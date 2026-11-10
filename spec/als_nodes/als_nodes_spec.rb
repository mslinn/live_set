require 'spec_helper'
require 'als_nodes/als_nodes'
require 'support/live_fixtures'

# The nodes of a document that an XPath expression finds.
#
# The document is inflated from the fixture data: the XML of the largest Live 12 demo set.
# See docs/serializer_plan.md, "Testing".
RSpec.describe AlsNodes, '.values_of' do
  # The document of the fixture.
  #
  # @return [Nokogiri::XML::Document] the document
  def document
    @document ||= LiveFixtures.document 'live_12_suite_demo'
  end

  # The values of a node.
  #
  # @param node [Nokogiri::XML::Node] the node
  # @param found [Hash] the options
  # @return [Array<String>] the values of the node
  def values_of(node, found = described_class.default_options)
    described_class.values_of node, found
  end

  it 'writes the outermost element at the start of a line' do
    node = document.xpath('//FileRef').first

    expect(values_of(node).first.lines.first).to eq "<FileRef>\n"
  end

  it 'indents the children of the element by two spaces' do
    node = document.xpath('//FileRef').first

    expect(values_of(node).first.lines[1]).to match(/\A {2}</)
  end

  it 'writes no whitespace of the file the node came from' do
    node = document.xpath('//FileRef').first

    expect(values_of(node).first).not_to match(/^\t/)
  end

  it 'indents every level of nesting by two spaces' do
    node = document.xpath('//Tracks').first

    expect(values_of(node).first.lines[1]).to match(/\A {2}</)
    expect(values_of(node).first.lines[2]).to match(/\A {4}</)
  end

  it 'keeps the text of an element that has some' do
    node = Nokogiri::XML::DocumentFragment.parse('<Value>the text</Value>').children.first

    expect(values_of(node).first).to include('the text')
  end
end
