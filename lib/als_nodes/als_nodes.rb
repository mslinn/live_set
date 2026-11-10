require 'json'
require 'optparse'
require_relative '../common/command'
require_relative '../live_set/als_file'
require_relative '../live_set/demo_sets'

# TODO: I frequently run commands like:
# $ als_nodes "$pinkblanket" //AudioTrack/DeviceChain/DeviceChain --children |   jq -r '.[]' | sort -u
# This portion is boilerplate that I want to abbreviate somehow: `--children |   jq -r '.[]' | sort -u`
# Here are some options. help me decide which would be flexible and easy to understand for a user:
# $ als_nodes "$pinkblanket" //AudioTrack/DeviceChain/DeviceChain --unique_child_entities
# $ als_nodes "$pinkblanket" //AudioTrack/DeviceChain/DeviceChain --children --unique_entities
# $ als_nodes "$pinkblanket" //AudioTrack/DeviceChain/DeviceChain --children --unique
# We also need short-forms for options:
# - --children/-c
# - --unique/-u
#
# Prints the nodes of an XML document that an XPath expression finds.
#
# A Live set is XML, usually gzip-compressed, so the document can be a .als file or any XML file. The XPath expression
# is the only thing that has to change from one question to the next, which makes this the tool to reach for instead of
# writing a program for each element.
class AlsNodes
  extend Command

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

      The results are printed as a JSON array of strings, so that jq can work with them.

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
        #{log_level_help}

      Examples:
        als_nodes set.als '//MidiTrack/IsTuned' --attribute Value
        als_nodes set.als '//MidiTrack' --attribute Id --attribute SelectedToolPanel
        als_nodes set.als '//MidiTrack' --attributes
        als_nodes set.als '//LiveSet/Scenes/Scene/FollowAction' --children
        als_nodes set.als '//LiveSet/MainTrack' --children | jq -r '.[]'
        als_nodes set.als '//MidiTrack' --count
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # Prints the nodes the XPath expression finds.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Integer] the exit status of the command
  def self.run(args)
    found, remaining = parse_options(args)

    if remaining.length < 2
      warn help
      return 1
    end

    path = DemoSets.path_of(remaining.shift)
    xpath = remaining.shift

    abort "No such file: #{path}" unless File.exist?(path)

    document = AlsFile.read(path)
    nodes = document.xpath(xpath)

    if found[:count]
      puts nodes.length
      return 0
    end

    nodes = nodes.first(found[:max]) if found[:max]
    results = nodes.flat_map { |node| values_of(node, found) }
    results = results.uniq if found[:unique]

    puts JSON.pretty_generate(results)
    0
  end

  # The options the command starts with.
  #
  # @return [Hash] the options
  def self.default_options
    super.merge(attribute: [])
  end

  def self.parser
    OptionParser.new do |parser|
      parser.program_name = 'als_nodes'

      parser.on('--attribute NAME', Array, 'Print the value of an attribute of each node')
      parser.on('--attributes', 'Print every attribute of each node')
      parser.on('--name', 'Print the name of each node')
      parser.on('--children', 'Print the names of the children of each node')
      parser.on('--count', 'Print the number of nodes that were found')
      parser.on('--max N', Integer, 'Print at most N nodes')
      parser.on('--unique', 'Print each distinct result once')
      add_common_options parser

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end

  # The values of a node.
  #
  # @param node [Nokogiri::XML::Node] the node
  # @param found [Hash] the options
  # @return [Array<String>] the values of the node
  def self.values_of(node, found)
    attributes = found[:attribute]
    return [attributes.map { |name| node[name].to_s }.join(' ')] unless attributes.empty?
    return [node.attribute_nodes.map { |attribute| "#{attribute.name}=#{attribute.value}" }.join(' ')] if found[:attributes]
    return [node.name] if found[:name]
    return node.element_children.map(&:name) if found[:children]

    [node.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)]
  end
end
