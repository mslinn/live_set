require 'nokogiri'

# Reads the order of the children of an element out of a generated schema.
#
# A generated schema describes an element with an xs:sequence, which lists the kinds of child
# element the element may have, in order. The order is the order Live writes the children in,
# because the schema is generated from the XML stored in the demo sets of a Live version.
#
# The transformations of a conversion put elements in a particular place, and this is where they
# get it.
class SchemaOrder
  # The namespace of the XML Schema vocabulary.
  NAMESPACE = { 'xs' => 'http://www.w3.org/2001/XMLSchema' }.freeze

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
