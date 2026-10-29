require 'nokogiri'
require 'live_set/tx/live_11_and_12'

# The minor versions of the two versions of the Live format that the conversion between them
# understands.
LIVE_11 = '11.0_11300'.freeze
LIVE_12 = '12.0_12402'.freeze

# Builds a document of a Live version.
#
# The document is a whole set as far as the conversion is concerned: the version of the set is
# in the attributes of the root element, and the content is whatever the example needs.
#
# @param version [String] the minor version of the set
# @param xml [String] the content of the set
# @return [Nokogiri::XML::Document] the document
def live_document(version, xml = '')
  Nokogiri::XML(%(<Ableton MajorVersion="5" MinorVersion="#{version}" SchemaChangeCount="0" ) +
                %(Creator="Test Live" Revision="revision">#{xml}</Ableton>))
end

# Converts a fragment of a set, and returns the content of the result.
#
# @param version [String] the minor version of the set the fragment is in
# @param xml [String] the fragment
# @return [Array<String>] the XML of the children of the root of the converted set
def convert_fragment(version, xml)
  document = live_document(version, xml)
  Live11And12.new(document).convert
  content_of(document)
end

# Converts an element of a set, and returns the element as it is after the conversion.
#
# The transformations of a conversion name the parent an element goes in, so an element has to be inside
# its parent for the transformations that add to that parent to find it. The element is put inside its
# ancestors here, and taken out again afterwards, so that the example is about the element and
# not about the elements the transformations add to its ancestors.
#
# @param version [String] the minor version of the set the element is in
# @param path [String] the path of the element, e.g. "LiveSet/GroovePool"
# @param xml [String] the content of the element
# @return [String] the XML of the element after the conversion
def convert_element(version, path, xml)
  parts = path.split('/')
  name = parts.last
  content = "<#{name}>#{xml}</#{name}>"
  parts[0...-1].reverse_each { |ancestor| content = "<#{ancestor}>#{content}</#{ancestor}>" }

  document = live_document(version, content)
  Live11And12.new(document).convert
  element = document.at_xpath("//#{path}")
  return nil if element.nil?

  element.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
end

# The content of a document, as XML.
#
# The XML is written without the indentation Nokogiri adds by default, so that the expected
# value in an example can be written the way the element is written in a set.
#
# @param document [Nokogiri::XML::Document] the document
# @return [Array<String>] the XML of the children of the root
def content_of(document)
  options = Nokogiri::XML::Node::SaveOptions::AS_XML
  document.root.element_children.map { |child| child.to_xml(save_with: options) }
end
