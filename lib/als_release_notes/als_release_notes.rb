require 'net/http'
require 'nokogiri'
require_relative '../common/command'
require_relative 'als_release_notes_options'

# Prints the release notes of a version of Live as markdown.
#
# The release notes are the evidence the version_diff documents are built from: they say which
# differences to expect, and which version introduced each one. They are written for the
# musicians who use Live, and they never give an element name or an attribute name, so they are
# a filter over the differences rather than a source of them.
#
# The notes are HTML, downloaded from Ableton's web site, and one file per version is kept in
# docs/release_notes/. This command reads one of them and prints it as markdown, so that the
# notes can be read, searched, and pasted into a document. When the file is not there, the
# notes are fetched from the web page they came from.
class AlsReleaseNotes
  extend Command

  # The directory the release notes are kept in.
  NOTES = File.expand_path('../../docs/release_notes', __dir__).freeze

  # The page the notes of a version come from.
  URL = 'https://www.ableton.com/en/release-notes/live-%s/'.freeze

  # The heading of a release, e.g. "12.0.25 Release Notes".
  RELEASE = /\A(\d+\.\d+(?:\.\d+)?) Release Notes\z/

  # The level of the heading of an element in the markdown.
  #
  # The heading of a release is a level of its own, and the headings of the sections of a
  # release are below it.
  LEVEL = { 'h2' => 3, 'h3' => 4, 'h4' => 5 }.freeze

  # Prints the notes of a version of Live.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Integer] the exit status of the command
  def self.run(args)
    found, remaining = parse_options(args)

    version = remaining.shift
    if version.nil?
      warn help
      return 1
    end

    live = version.split('.').first
    notes = notes_of html_of(live)

    print_notes notes, version, found[:pattern]
    0
  end

  # The HTML of the notes of a version.
  #
  # The copy that is kept in docs/release_notes/ is used when it is there, and the notes are
  # fetched from the page they come from when it is not.
  #
  # @param live [String] the version of Live, e.g. "12"
  # @return [String] the HTML of the notes
  def self.html_of(live)
    path = File.join(NOTES, "live-#{live}.html")
    File.exist?(path) ? File.read(path) : fetch(format(URL, live))
  end

  # Prints the notes.
  #
  # @param notes [Array<Array(String, String)>] the lines of the notes
  # @param version [String] the version asked for
  # @param pattern [String, nil] the pattern the notes are searched for
  # @return [void]
  def self.print_notes(notes, version, pattern)
    if pattern
      matcher = Regexp.new(pattern, Regexp::IGNORECASE)
      notes.each { |release, line| puts "#{release} | #{line}" if line&.match?(matcher) }
      return
    end

    puts "# Live #{version.split('.').first} Release Notes"
    puts

    if version.include?('.')
      notes.each { |release, line| puts line if release == version }
      return
    end

    notes.map(&:last).each { |line| puts line }
  end

  # Fetches the notes of a version from the page they come from.
  #
  # @param url [String] the URL of the page
  # @return [String] the HTML of the page
  def self.fetch(url)
    response = Net::HTTP.get_response URI(url)
    abort "Could not read #{url}: #{response.code} #{response.message}" unless response.is_a? Net::HTTPSuccess

    response.body
  end

  # The text of a node, with a line break in it kept as a line break.
  #
  # @param node [Nokogiri::XML::Node] the node
  # @return [String] the text
  def self.text_of(node)
    node.children.map do |child|
      if child.element?
        child.name == 'br' ? "\n" : text_of(child)
      else
        child.content
      end
    end.join
  end

  # The text of a node, on one line.
  #
  # @param node [Nokogiri::XML::Node] the node
  # @return [String] the text
  def self.flat_text(node)
    collapse(text_of(node))
  end

  # The text of a string, on one line.
  #
  # @param text [String] the text
  # @return [String] the text
  def self.collapse(text)
    text.tr(' ', ' ').gsub(/\s+/, ' ').strip
  end

  # The lines of the text of a node, with its whitespace collapsed.
  #
  # @param node [Nokogiri::XML::Node] the node
  # @return [Array<String>] the lines of text
  def self.lines_of_text(node)
    text_of(node).gsub(/[^\S\n]+/, ' ').gsub(/\n{2,}/, "\n").split("\n").map(&:strip).reject(&:empty?)
  end

  # The text of a node, without the text of the lists it holds.
  #
  # The items of a nested list are printed in their own right, so the list item that holds them
  # does not repeat them.
  #
  # @param node [Nokogiri::XML::Node] the node
  # @return [String] the text
  def self.own_text(node)
    node.children.map do |child|
      if child.element?
        %w[ul ol].include?(child.name) ? '' : own_text(child)
      else
        child.content
      end
    end.join
  end

  # The notes of a version, as the lines of a markdown document.
  #
  # @param html [String] the HTML of the notes
  # @return [Array<Array(String, String)>] the lines, each a release and a line of markdown
  def self.notes_of(html)
    document = Nokogiri::HTML(html)
    release = nil
    previous = nil
    lines = []
    document.css('main h2, main h3, main h4, main p, main li').each do |node|
      text = flat_text(node)
      next if text.empty?

      if node.name == 'h2' && (match = RELEASE.match(text))
        release = match[1]
        lines << [release, "## #{text}"]
        lines << [release, '']
        previous = :heading
        next
      end
      next if release.nil?

      previous = add_node node, text, release, previous, lines
    end
    lines
  end

  # Adds the lines of a node to the lines of the notes.
  #
  # @param node [Nokogiri::XML::Node] the node
  # @param text [String] the text of the node
  # @param release [String] the release the node belongs to
  # @param previous [Symbol] what the node before it was
  # @param lines [Array<Array(String, String)>] the lines of the notes
  # @return [Symbol] what this node was
  def self.add_node(node, text, release, previous, lines)
    case node.name
    when 'h2', 'h3', 'h4'
      lines << [release, "#{'#' * LEVEL.fetch(node.name)} #{text}"]
      lines << [release, '']
      :heading
    when 'li'
      indent = '  ' * (node.ancestors('ul').length - 1)
      lines << [release, "#{indent}- #{collapse(own_text(node))}"]
      :item
    when 'p'
      return previous if node.ancestors('li').any?

      lines << [release, ''] if previous == :item
      lines_of_text(node).each_with_index do |line, index|
        lines << [release, index.zero? ? line : "#{line}  "]
      end
      lines << [release, '']
      :paragraph
    else
      previous
    end
  end
end
