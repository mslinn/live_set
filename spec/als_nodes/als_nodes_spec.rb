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
  # @return [Array] the values of the node
  def values_of(node, found = described_class.default_options)
    described_class.values_of node, found
  end

  # The options of the command, with the given ones added.
  #
  # @param options [Hash] the options
  # @return [Hash] the options
  def found(**options)
    described_class.default_options.merge(options)
  end

  describe 'the XML of a node' do
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

  describe 'the values of a node' do
    # A node with attributes and with children.
    #
    # @return [Nokogiri::XML::Node] the node
    def node
      @node ||= Nokogiri::XML::DocumentFragment.parse(
        '<Track Id="16"><Name>Drums</Name></Track>'
      ).children.first
    end

    it 'returns the value of an attribute as plaintext' do
      expect(values_of(node, found(attribute: ['Id']))).to eq ['16']
    end

    it 'returns the values of several attributes in the order they were given' do
      element = Nokogiri::XML::DocumentFragment.parse('<Track Id="16" Color="1"/>').children.first

      expect(values_of(element, found(attribute: %w[Color Id]))).to eq ['1 16']
    end

    it 'returns the name of the node as plaintext' do
      expect(values_of(node, found(name: true))).to eq ['Track']
    end

    it 'returns the attributes of the node as name/value pairs' do
      expect(values_of(node, found(attributes: true))).to eq [{ 'Id' => '16' }]
    end

    it 'returns the names of the children of the node' do
      expect(values_of(node, found(children: true))).to eq [['Name']]
    end

    it 'gives the attributes of the node priority over the children' do
      expect(values_of(node, found(attributes: true, children: true))).to eq [{ 'Id' => '16' }]
    end

    it 'gives the children of the node priority over an attribute' do
      expect(values_of(node, found(attribute: ['Id'], children: true))).to eq [['Name']]
    end
  end
end
