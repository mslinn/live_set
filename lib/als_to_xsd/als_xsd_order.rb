require 'nokogiri'
require 'optparse'
require_relative '../common/command'

# Reads the order of the children of an element out of a generated schema.
#
# A generated schema describes an element with an xs:sequence, which lists the kinds of child
# element the element may have, in order. The order is the order Live writes the children in,
# because the schema is generated from the XML stored in the demo sets of a Live version.
#
# The transformations of a conversion put elements in a particular place, and this is where they
# get it.
class AlsXsdOrder
  extend Command

  # The namespace of the XML Schema vocabulary.
  NAMESPACE = { 'xs' => 'http://www.w3.org/2001/XMLSchema' }.freeze

  # Display help message for als_xsd_order
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      Als_xsd_order prints the order of the children of an element in a generated Live schema.

      The transformations of a conversion put elements in a particular place, and the schema is
      where that order comes from: it is generated from the demo sets of a Live version, so it
      records the order Live writes the children of an element in.

      Syntax: als_xsd_order SCHEMA_FILE ELEMENT_NAME

      SCHEMA_FILE is the path of a generated schema, e.g. schemas/live_12.4d1.xsd.
      ELEMENT_NAME is the name of an element of the format, e.g. MidiClip.

      Options are:
        -h Display this help message.

      Example:
        als_xsd_order schemas/live_12.4d1.xsd MidiClip
        MidiClip: ["LomId", "LomIdView", "CurrentStart", ...]
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # Prints the order of the children of an element.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Integer] the exit status of the command
  def self.run(args)
    _, remaining = parse_options(args)

    if remaining.length != 2
      warn help
      return 1
    end

    schema_file, element_name = remaining
    abort "No such schema: #{schema_file}" unless File.exist?(schema_file)

    order = of_file(schema_file, element_name)

    if order.nil?
      warn "The schema has no element named #{element_name}"
      return 1
    end

    puts "#{element_name}: #{order.inspect}"
    0
  end

  def self.parser
    OptionParser.new do |parser|
      parser.program_name = 'als_xsd_order'

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end

  # The order of the children of an element.
  #
  # @param document [Nokogiri::XML::Document] the schema
  # @param element_name [String] the name of the element
  # @return [Array<String>, nil] the names of the children, in order
  def self.of(document, element_name)
    element = document.xpath('//xs:element[@name]', NAMESPACE).find { |e| e['name'] == element_name }
    return nil if element.nil?

    sequence = element.at_xpath('./xs:complexType/xs:sequence', NAMESPACE)
    return nil if sequence.nil?

    sequence.xpath('./xs:element', NAMESPACE).map { |child| child['name'] }
  end

  # The order of the children of an element in a schema file.
  #
  # @param path [String] the path of the schema file
  # @param element_name [String] the name of the element
  # @return [Array<String>, nil] the names of the children, in order
  def self.of_file(path, element_name)
    of(Nokogiri::XML(File.read(path)), element_name)
  end
end
