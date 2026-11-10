require 'nokogiri'
require 'optparse'
require_relative '../common/command'
require_relative '../live_set/als_file'
require_relative '../live_set/demo_sets'

# Compares two Ableton Live sets element by element, and prints the differences.
#
# A Live set is XML, usually gzip-compressed, so the documents can be .als files or any XML
# files. The two documents are walked in parallel: the children of two elements are matched by
# their names, and the children that one of the elements has and the other does not are reported
# as differences.
class AlsDiff
  extend Command

  # Display help message for als_diff
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      Als_diff compares two Ableton Live sets element by element, and prints the
      differences.

      A Live set is XML, usually gzip-compressed, so the documents can be .als files
      or files containing XML extracted from an ALS file. The two documents are
      first promoted to the newer of the two ALS versions, and are then walked in
      parallel: the children of two elements are matched by their names, and the
      children that one of the elements has and the other does not are reported as
      differences. The attributes of two elements are compared as well.

      Syntax: als_diff [OPTIONS] FILE1 FILE2

      Where: FILE1 and FILE2 are paths

      OPTIONS can be specified before or after positional parameters:
        -h             Display this help message.
        --count        print the number of differences, and nothing else
        --max N        print at most N differences
        --skip NAME    do not compare the elements with this name, or anything below
                      them. This option may be given more than once.
        #{log_level_help}

      The exit status is 0 when the documents are the same, and 1 when they are not.

      Examples:
        als_diff live11.als live12.als
        als_diff live11.als live12.als --skip Devices --skip DeviceChain
        als_diff live11.als live12.als --count
        als_diff --skip Devices --skip DeviceChain live11.als live12.als
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # Compares the two files, and prints the differences.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Integer] the exit status of the command
  def self.run(args)
    found, remaining = parse_options(args)

    if remaining.length < 2
      warn help
      return 1
    end

    ours_path = DemoSets.path_of(remaining.shift)
    theirs_path = DemoSets.path_of(remaining.shift)

    [ours_path, theirs_path].each do |path|
      abort "No such file: #{path}" unless File.exist?(path)
    end

    differences = AlsDiff.new(AlsFile.read(ours_path).root, AlsFile.read(theirs_path).root, skip: found[:skip]).differences

    if found[:count]
      puts differences.length
      return (differences.empty? ? 0 : 1)
    end

    differences = differences.first(found[:max]) if found[:max]
    puts differences
    puts 'The documents are the same.' if differences.empty?

    differences.empty? ? 0 : 1
  end

  # The options the command starts with.
  #
  # @return [Hash] the options
  def self.default_options
    super.merge(skip: [])
  end

  def self.parser
    OptionParser.new do |parser|
      parser.program_name = 'als_diff'

      parser.on('--skip NAME', Array, 'Do not compare the elements with this name')
      parser.on('--count', 'Print the number of differences')
      parser.on('--max N', Integer, 'Print at most N differences')
      add_common_options parser

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end

  # @param ours [Nokogiri::XML::Node] the element of the first document
  # @param theirs [Nokogiri::XML::Node] the element of the second document
  # @param skip [Array<String>] the paths of the elements that are not compared at all
  def initialize(ours, theirs, skip: [])
    @ours = ours
    @theirs = theirs
    @skip = skip.map { |path| path.split('/') }
  end

  # The differences between the two documents.
  #
  # @return [Array<String>] the differences, one per line
  def differences
    found = []
    compare(@ours, @theirs, @ours.name, found)
    found
  end

  private

  # Compares two elements, and the elements below them.
  #
  # @param ours [Nokogiri::XML::Node] the element of the first document
  # @param theirs [Nokogiri::XML::Node] the element of the second document
  # @param path [String] the path of the element
  # @param found [Array<String>] the differences found so far
  # @return [void]
  def compare(ours, theirs, path, found)
    return if skipped?(path)

    found.concat attribute_differences(ours, theirs, path)

    pairs = matched_children(ours, theirs)
    pairs.each { |our_child, their_child| compare(our_child, their_child, "#{path}/#{our_child.name}", found) }

    ours.element_children.map(&:name).tally.each do |name, count|
      found << "#{path}/#{name} only in ours" if count > theirs.element_children.count { |child| child.name == name }
    end
    theirs.element_children.map(&:name).tally.each do |name, count|
      found << "#{path}/#{name} only in theirs" if count > ours.element_children.count { |child| child.name == name }
    end
  end

  # Whether an element is not compared at all.
  #
  # A skipped path matches the end of the path of the element, so that a path like
  # "DeviceChain/DeviceChain" skips that element wherever it is, and a path like "Devices"
  # skips every element of that name.
  #
  # @param path [String] the path of the element
  # @return [Boolean] whether the element is skipped
  def skipped?(path)
    parts = path.split('/')
    @skip.any? { |skipped| parts.last(skipped.length) == skipped }
  end

  # The children of two elements that have the same name, paired up.
  #
  # The children that have the same name are paired in the order they come, so that the first
  # child of one element is compared with the first child of the other.
  #
  # @param ours [Nokogiri::XML::Node] the element of the first document
  # @param theirs [Nokogiri::XML::Node] the element of the second document
  # @return [Array<Array(Nokogiri::XML::Node, Nokogiri::XML::Node)>] the pairs of children
  def matched_children(ours, theirs)
    theirs_children = theirs.element_children.group_by(&:name)
    pairs = []
    ours.element_children.each do |child|
      their_child = theirs_children.fetch(child.name, []).shift
      pairs << [child, their_child] unless their_child.nil?
    end
    pairs
  end

  # The attributes of two elements that are not the same.
  #
  # An attribute that one of the elements has and the other does not is a difference, and so is
  # an attribute whose value is not the same.
  #
  # @param ours [Nokogiri::XML::Node] the element of the first document
  # @param theirs [Nokogiri::XML::Node] the element of the second document
  # @param path [String] the path of the element
  # @return [Array<String>] the paths of the attributes that differ
  def attribute_differences(ours, theirs, path)
    names = (ours.attribute_nodes.map(&:name) + theirs.attribute_nodes.map(&:name)).uniq
    names.filter_map do |name|
      next if ours[name] == theirs[name]

      "#{path}/@#{name} ours=#{ours[name].inspect} theirs=#{theirs[name].inspect}"
    end
  end
end
