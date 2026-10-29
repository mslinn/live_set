require 'spec_helper'
require 'live_set/live_xml_writer'

# Writes an XML document the way Ableton Live writes it.
#
# Live writes every element on a line of its own, indented with tabs, and writes an element that
# holds nothing as <Foo />.
RSpec.describe LiveXmlWriter do
  # Writes a document, and returns the XML.
  #
  # @param xml [String] the XML of the document
  # @param quote [Symbol] :double, :single or :auto
  # @return [String] the XML, as Live would write it
  def write(xml, quote: :auto)
    described_class.new(quote: quote).write(Nokogiri::XML(xml))
  end

  # A document with an attribute whose value holds the given text.
  #
  # The value is set through Nokogiri, so that the document is well-formed whatever the value
  # holds. The writer only ever sees the value of the attribute, and not how it was written.
  #
  # @param value [String] the value of the attribute
  # @return [Nokogiri::XML::Document] the document
  def document_with_value(value)
    document = Nokogiri::XML('<Ableton/>')
    document.root['Name'] = value
    document
  end

  it 'writes the XML declaration, and ends the file with a newline' do
    expect(write('<Ableton/>')).to eq %(<?xml version="1.0" encoding="UTF-8"?>\n<Ableton />\n)
  end

  it 'writes an element that holds nothing as an empty element' do
    expect(write('<Ableton><Foo/></Ableton>')).to include '<Foo />'
  end

  it 'writes an element that holds only whitespace as an empty element' do
    expect(write(%(<Ableton><Foo>\n\t</Foo></Ableton>))).to include '<Foo />'
  end

  it 'writes the whitespace in front of an element' do
    expect(write(%(<Ableton>\n\t<Foo/>\n</Ableton>))).to include %(<Ableton>\n\t<Foo />\n</Ableton>)
  end

  # The whitespace in front of an element that is removed from a set is left behind, and two
  # whitespace nodes then follow each other. Live never writes that.
  it 'does not write two whitespace nodes in a row' do
    document = Nokogiri::XML('<Ableton><Foo/></Ableton>')
    document.at_xpath('//Foo').add_previous_sibling(Nokogiri::XML::Text.new("\n\t", document))
    document.at_xpath('//Foo').add_previous_sibling(Nokogiri::XML::Text.new("\n\t", document))

    expect(described_class.new.write(document)).to include %(<Ableton>\n\t<Foo /></Ableton>)
  end

  it 'delimits the value of an attribute with double quotes' do
    document = document_with_value('a')
    expect(described_class.new(quote: :double).write(document)).to include 'Name="a"'
  end

  # Live 12 writes the value of an attribute with the quote character that occurs later in it, so
  # that the quote character that occurs first can be written as it is. The quote that delimits
  # the value is escaped inside it.
  it 'delimits the value of an attribute with the quote that occurs later in it' do
    expect(described_class.new(quote: :single).write(document_with_value(%(a'b)))).to include %(Name="a'b")
    expect(described_class.new(quote: :single).write(document_with_value(%(a"b)))).to include %(Name='a"b')
    expect(described_class.new(quote: :single).write(document_with_value(%(a"b'c)))).to include %(Name='a"b&apos;c')
    expect(described_class.new(quote: :single).write(document_with_value(%(a'b"c)))).to include %(Name="a'b&quot;c")
  end

  it 'escapes the delimiter inside the value of an attribute' do
    expect(described_class.new(quote: :double).write(document_with_value(%(a"b)))).to include 'Name="a&quot;b"'
  end

  it 'escapes the characters that are not allowed in the value of an attribute' do
    expect(described_class.new(quote: :double).write(document_with_value('a&b'))).to include 'Name="a&amp;b"'
    expect(described_class.new(quote: :double).write(document_with_value("a\nb"))).to include 'Name="a&#x0A;b"'
  end

  # A set that was converted has to be readable again, so the writer has to write XML that
  # Nokogiri can read, whatever the value of an attribute holds.
  it 'writes a document that can be read again' do
    values = ['plain', %(a'b), %(a"b), %(a"b'c), %(a'b"c), 'a&b', "a\nb", 'a>b', 'a<b']

    values.each do |value|
      xml = described_class.new(quote: :single).write(document_with_value(value))
      read_back = Nokogiri::XML(xml)

      aggregate_failures do
        expect(read_back.errors).to be_empty, "reading #{xml.inspect} back: #{read_back.errors.map(&:message).join(', ')}"
        expect(read_back.root['Name']).to eq(value), "reading #{xml.inspect} back"
      end
    end
  end
end
