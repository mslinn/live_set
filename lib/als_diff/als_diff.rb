require 'nokogiri'
require_relative '../common/command'
require_relative '../live_set/als_file'
require_relative '../live_set/demo_sets'
require_relative 'als_diff_options'

# Compares two Ableton Live sets element by element, and prints the differences.
#
# A Live set is XML, usually gzip-compressed, so the documents can be .als files or any XML
# files. The two documents are walked in parallel: the children of two elements are matched by
# their names, and the children that one of the elements has and the other does not are reported
# as differences.
class AlsDiff
  extend Command

  # Compares the two files, and prints the differences.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Integer] the exit status of the command
  # Compares the two files, and prints the differences.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Integer] the exit status of the command
  def self.run(args)
    options, remaining = parse_options(args)

    return warn(help) || 1 if remaining.length < 2

    check_extra_parameters(remaining, 2)

    ours_path, theirs_path = remaining.first(2).map do |arg|
      path = DemoSets.path_of(arg)
      raise "No such file: #{path}" unless File.exist?(path)

      path
    end

    differences = AlsDiff.new(
      AlsFile.read(ours_path).root,
      AlsFile.read(theirs_path).root,
      skip: options[:skip]
    ).differences

    if options[:count]
      puts differences.length
    else
      diffs = options[:max] ? differences.first(options[:max]) : differences
      puts diffs
      puts 'The documents are the same.' if diffs.empty?
    end

    differences.empty? ? 0 : 1
  rescue StandardError => e
    warn e.full_message
    1
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
