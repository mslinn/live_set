require_relative '../live_set/als_file'
require_relative '../live_set/demo_sets'

# Prints the nodes of an XML document that an XPath expression finds.
#
# A Live set is XML, usually gzip-compressed, so the document can be a .als file or any XML
# file. The XPath expression is the only thing that has to change from one question to the next,
# which makes this the tool to reach for instead of writing a program for each element.
class AlsNodes
  # Display help message for als_nodes
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      Als_nodes prints the nodes of an XML document that an XPath expression finds.

      A Live set is XML, usually gzip-compressed, so the document can be a .als file or any XML
      file. The XPath expression is the only thing that has to change from one question to the
      next, which makes this the tool to reach for instead of writing a program for each
      element.

      Syntax: als_nodes FILE XPATH [options]

      FILE is the path of the file, or a selector of a demo set, e.g. demo:11:suite.

      Options are:
        --attribute NAME  print the value of an attribute of each node, not the node itself. The
                           option may be given more than once, and the values of the attributes
                           are then printed in the order the options were given.
        --attributes       print every attribute of each node, as name=value pairs
        --name             print the name of each node, not the node itself
        --children        print the names of the children of each node, not the node itself
        --count           print the number of nodes that were found, and nothing else
        --max N           print at most N nodes
        --unique          print each distinct result once
        -h                Display this help message.

      Examples:
        als_nodes set.als '//MidiTrack/IsTuned' --attribute Value
        als_nodes set.als '//MidiTrack' --attribute Id --attribute SelectedToolPanel
        als_nodes set.als '//MidiTrack' --attributes
        als_nodes set.als '//LiveSet/Scenes/Scene/FollowAction' --children
        als_nodes set.als '//MidiTrack' --count
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # Prints the nodes the XPath expression finds.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Integer] the exit status of the command
  def self.run(args)
    argv = args.dup

    if argv.length < 2
      warn help
      return 1
    end

    path = DemoSets.path_of(argv.shift)
    xpath = argv.shift
    found = options(argv)

    abort "No such file: #{path}" unless File.exist?(path)

    document = AlsFile.read(path)
    nodes = document.xpath(xpath)

    if found[:count]
      puts nodes.length
      return 0
    end

    nodes = nodes.first(found[:max]) if found[:max]
    results = nodes.map { |node| text_of(node, found) }
    results = results.uniq if found[:unique]

    puts results
    0
  end

  # The options the tool was given.
  #
  # @param argv [Array<String>] the arguments that are left
  # @return [Hash] the options
  def self.options(argv)
    { attributes: [], max: nil, unique: false }.tap do |found|
      until argv.empty?
        case argv.first
        when '--attribute' then found[:attributes] << argv.shift(2).last
        when '--attributes' then found[:all_attributes] = argv.shift
        when '--name'       then found[:name] = argv.shift
        when '--children'   then found[:children] = argv.shift
        when '--count'      then found[:count] = argv.shift
        when '--max'        then found[:max] = argv.shift(2).last.to_i
        when '--unique'     then found[:unique] = argv.shift
        else break
        end
      end
    end
  end

  # The text of a node.
  #
  # @param node [Nokogiri::XML::Node] the node
  # @param found [Hash] the options
  # @return [String] the text of the node
  def self.text_of(node, found)
    attributes = found[:attributes]
    return attributes.map { |name| node[name].to_s }.join(' ') unless attributes.empty?
    return node.attribute_nodes.map { |attribute| "#{attribute.name}=#{attribute.value}" }.join(' ') if found[:all_attributes]
    return node.name if found[:name]
    return node.element_children.map(&:name).inspect if found[:children]

    node.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
  end
end
