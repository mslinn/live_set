require 'json'
require_relative '../common/command'
require_relative '../live_set/als_file'
require_relative '../live_set/demo_sets'
require_relative 'als_nodes_options'

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

    print_results results, found
    0
  end

  # Prints what the command found.
  #
  # The nodes are printed as XML. The values of the nodes are printed as a JSON array of
  # strings, so that jq can work with them: jq reads JSON, and not XML.
  #
  # @param results [Array<String>] the results
  # @param found [Hash] the options
  # @return [void]
  def self.print_results(results, found)
    if prints_nodes?(found)
      results.each { |node| puts node }
    else
      puts JSON.pretty_generate(results)
    end
  end

  # Whether the command prints the nodes themselves, and not the values of them.
  #
  # @param found [Hash] the options
  # @return [Boolean] true when the nodes are printed
  def self.prints_nodes?(found)
    found[:attribute].empty? && !found[:attributes] && !found[:name] && !found[:children]
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

    [xml_of(node)]
  end

  # The XML of a node, indented.
  #
  # The node is copied into a document of its own, so that it is the outermost element of
  # what is printed. The blank text nodes are removed, so that the formatter indents the
  # children of the node: otherwise the whitespace of the file the node came from is kept,
  # and the node is printed at the depth it has in that file.
  #
  # Every level of nesting is indented by two spaces, and the outermost element is at the
  # start of a line.
  #
  # @param node [Nokogiri::XML::Node] the node
  # @return [String] the XML of the node
  def self.xml_of(node)
    document = Nokogiri::XML::Document.new
    document.root = node.dup
    document.xpath('//text()').each { |text| text.remove if text.content.strip.empty? }

    document.root.to_xml(indent: 2)
  end
end
