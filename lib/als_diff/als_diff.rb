require 'nokogiri'
require_relative '../live_set/als_file'
require_relative '../live_set/demo_sets'

# Compares two Ableton Live sets element by element, and prints the differences.
#
# A Live set is XML, usually gzip-compressed, so the documents can be .als files or any XML
# files. The two documents are walked in parallel: the children of two elements are matched by
# their names, and the children that one of the elements has and the other does not are reported
# as differences.
class AlsDiff
  # Display help message for als_diff
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      Als_diff compares two Ableton Live sets element by element, and prints the differences.

      A Live set is XML, usually gzip-compressed, so the documents can be .als files or any XML
      files. The two documents are walked in parallel: the children of two elements are matched
      by their names, and the children that one of the elements has and the other does not are
      reported as differences.

      Syntax: als_diff FILE1 FILE2 [options]

      FILE1 and FILE2 are paths, or selectors of demo sets:
        demo:11:suite            the Live 11 Suite demo set
        demo:12                  the demo set of Live 12
        demo:converted:11:suite  the Live 12 conversion of the Live 11 Suite demo set

      Options are:
        --skip NAME    do not compare the elements with this name, or anything below them. The
                       option may be given more than once.
        --count        print the number of differences, and nothing else
        --max N        print at most N differences
        -h             Display this help message.

      The exit status is 0 when the documents are the same, and 1 when they are not.

      Examples:
        als_diff live11.als live12.als
        als_diff live11.als live12.als --skip Devices --skip DeviceChain
        als_diff live11.als live12.als --count
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # Compares the two files, and prints the differences.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Integer] the exit status of the command
  def self.run(args)
    argv = args.dup

    if argv.length < 2
      warn help
      return 1
    end

    ours_path = DemoSets.path_of(argv.shift)
    theirs_path = DemoSets.path_of(argv.shift)
    found = options(argv)

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

  # The options the tool was given.
  #
  # @param argv [Array<String>] the arguments that are left
  # @return [Hash] the options
  def self.options(argv)
    { skip: [], max: nil }.tap do |found|
      until argv.empty?
        case argv.first
        when '--skip' then found[:skip] << argv.shift(2).last
        when '--count' then found[:count] = argv.shift
        when '--max'  then found[:max] = argv.shift(2).last.to_i
        else break
        end
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
