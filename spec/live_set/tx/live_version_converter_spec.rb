require 'spec_helper'
require 'live_set/tx/live_version_converter'

# The base class of a conversion between two versions of the Live format.
#
# The base class knows nothing about any particular pair of versions. It applies the tables a
# subclass supplies, in the order the tables are applied, and it takes the direction from the
# version the document carries.
RSpec.describe LiveVersionConverter do # rubocop:disable RSpec/DescribeClass
  # A bridge between two made-up versions, used to test the base class on its own.
  #
  # The tables are deliberately unlike the tables of a real bridge: the elements are named after
  # the rules they exercise, so that a failing example says which rule failed.
  class TestConverter < LiveVersionConverter
    VERSION = {
      down: { 'MajorVersion' => '5', 'MinorVersion' => '9.0_9000', 'SchemaChangeCount' => '1',
              'Creator' => 'Test Live 9', 'Revision' => 'down' },
      up: { 'MajorVersion' => '5', 'MinorVersion' => '10.0_10000', 'SchemaChangeCount' => '2',
            'Creator' => 'Test Live 10', 'Revision' => 'up' }
    }.freeze

    REMOVE = %w[OldElement].freeze
    REMOVE_UNDER = %w[Parent/Child].freeze
    RENAME = { 'NewName' => 'OldName' }.freeze
    RENAME_UNDER = { 'Parent/NewChild' => 'OldChild' }.freeze
    EMPTY = { down: %w[Holder], up: [] }.freeze
    REMOVE_ATTRIBUTE = %w[OldAttribute].freeze
    DEFAULT_ATTRIBUTE = { 'Event' => { 'Added' => 'yes' } }.freeze
    ADD = {
      down: [{ parent: 'Adder', name: 'DownOnly', attributes: { 'Value' => '1' } }],
      up:   [{ parent: 'Adder', name: 'UpOnly', attributes: { 'Value' => '2' } }]
    }.freeze
    CHILD_ORDER = {
      down: { 'Adder' => %w[First Second DownOnly], 'Keep' => %w[First Second] },
      up:   { 'Adder' => %w[First Second UpOnly], 'Keep' => %w[First Second] }
    }.freeze
  end

  # A bridge whose tables the base class must not use.
  class OtherConverter < TestConverter
    REMOVE = %w[SomethingElse].freeze
  end

  # The version of a document.
  LIVE_9 = '9.0_9000'.freeze
  LIVE_10 = '10.0_10000'.freeze

  # Builds a document of a version.
  #
  # @param version [String] the minor version of the set
  # @param xml [String] the content of the set
  # @return [Nokogiri::XML::Document] the document
  def document_for(version, xml = '')
    Nokogiri::XML(%(<Ableton MajorVersion="5" MinorVersion="#{version}" SchemaChangeCount="0" ) +
                  %(Creator="Test" Revision="revision">#{xml}</Ableton>))
  end

  # The content of a document, as XML.
  #
  # @param document [Nokogiri::XML::Document] the document
  # @return [String] the XML of the children of the root
  def content_of(document)
    options = Nokogiri::XML::Node::SaveOptions::AS_XML
    document.root.element_children.map { |child| child.to_xml(save_with: options) }
  end

  it 'reads the direction of the conversion from the version of the document' do
    expect(TestConverter.new(document_for(LIVE_9)).direction).to eq :up
    expect(TestConverter.new(document_for(LIVE_10)).direction).to eq :down
  end

  it 'refuses a document whose version it does not know' do
    expect { TestConverter.new(document_for('7.0_7000')) }.to raise_error(ArgumentError, /7\.0_7000/)
  end

  it 'writes the version strings of the version the set is going to' do
    document = TestConverter.new(document_for(LIVE_10)).convert
    expect(document.root['MinorVersion']).to eq LIVE_9
    expect(document.root['Creator']).to eq 'Test Live 9'
  end

  it 'keeps only the attributes of the version it writes' do
    document = document_for(LIVE_10)
    document.root['Extra'] = 'gone'
    TestConverter.new(document).convert
    expect(document.root.attribute_nodes.map(&:name)).to contain_exactly('MajorVersion', 'MinorVersion',
                                                                      'SchemaChangeCount', 'Creator', 'Revision')
  end

  it 'removes the elements the older version does not have' do
    document = document_for(LIVE_10, '<OldElement/><Kept/>')
    TestConverter.new(document).convert
    expect(content_of(document)).to eq ['<Kept/>']
  end

  it 'removes an element only under the parent it is listed under' do
    document = document_for(LIVE_10, '<Parent><Child/></Parent><Other><Child/></Other>')
    TestConverter.new(document).convert
    expect(content_of(document)).to eq ['<Parent/>', '<Other><Child/></Other>']
  end

  it 'renames an element to the other spelling, whichever spelling it has' do
    document = document_for(LIVE_10, '<NewName/>')
    TestConverter.new(document).convert
    expect(content_of(document)).to eq ['<OldName/>']
  end

  it 'renames an element back when the set is going the other way' do
    document = document_for(LIVE_9, '<OldName/>')
    TestConverter.new(document).convert
    expect(content_of(document)).to eq ['<NewName/>']
  end

  it 'renames an element under a parent, in the direction of the parent' do
    document = document_for(LIVE_10, '<Parent><NewChild/></Parent>')
    TestConverter.new(document).convert
    expect(content_of(document)).to eq ['<Parent><OldChild/></Parent>']
  end

  it 'empties an element that is empty in the older version' do
    document = document_for(LIVE_10, '<Holder><Content/></Holder>')
    TestConverter.new(document).convert
    expect(content_of(document)).to eq ['<Holder/>']
  end

  it 'does not empty an element when the set is going the other way' do
    document = document_for(LIVE_9, '<Holder><Content/></Holder>')
    TestConverter.new(document).convert
    expect(content_of(document)).to eq ['<Holder><Content/></Holder>']
  end

  it 'removes an attribute the older version does not have' do
    document = document_for(LIVE_10, '<Thing OldAttribute="x" Kept="y"/>')
    TestConverter.new(document).convert
    expect(content_of(document)).to eq ['<Thing Kept="y"/>']
  end

  it 'gives an attribute the value the older version writes' do
    document = document_for(LIVE_10, '<Event/>')
    TestConverter.new(document).convert
    expect(content_of(document)).to eq ['<Event Added="yes"/>']
  end

  it 'leaves an attribute alone when the older version already writes it' do
    document = document_for(LIVE_10, '<Event Added="no"/>')
    TestConverter.new(document).convert
    expect(content_of(document)).to eq ['<Event Added="no"/>']
  end

  it 'reads the tables of the subclass, and not the tables of the base class' do
    document = document_for(LIVE_10, '<OldElement/><SomethingElse/>')
    OtherConverter.new(document).convert
    expect(content_of(document)).to eq ['<OldElement/>']
  end

  it 'calls the special rules of the subclass' do
    converter = TestConverter.new(document_for(LIVE_10))
    expect(converter).to receive(:special_rules).and_call_original
    converter.convert
  end

  it 'lists the versions it converts' do
    expect(TestConverter.versions).to eq [LIVE_9, LIVE_10]
  end

  it 'adds the element the newer version has, and not the one the older version has' do
    document = document_for(LIVE_10, '<Adder/>')
    TestConverter.new(document).convert
    expect(content_of(document)).to eq ['<Adder><DownOnly Value="1"/></Adder>']
  end

  it 'adds the other element when the set is going the other way' do
    document = document_for(LIVE_9, '<Adder/>')
    TestConverter.new(document).convert
    expect(content_of(document)).to eq ['<Adder><UpOnly Value="2"/></Adder>']
  end

  it 'does not add an element the parent already has' do
    document = document_for(LIVE_10, '<Adder><DownOnly Value="x"/></Adder>')
    TestConverter.new(document).convert
    expect(content_of(document)).to eq ['<Adder><DownOnly Value="x"/></Adder>']
  end

  it 'puts the children of an element in the order the version writes them in' do
    document = document_for(LIVE_10, '<Adder><Second/><First/></Adder>')
    TestConverter.new(document).convert
    expect(content_of(document)).to eq ['<Adder><First/><Second/><DownOnly Value="1"/></Adder>']
  end

  # Live writes the whitespace between the elements of a set as text nodes, so the whitespace in
  # front of an element goes with the element when it is moved.
  it 'moves the whitespace in front of an element with the element' do
    document = document_for(LIVE_10, "<Keep>\n\t<Second/>\n\t<First/>\n</Keep>")
    TestConverter.new(document).convert
    expect(document.at_xpath('//Keep').to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML))
      .to eq "<Keep>\n\t<First/>\n\t<Second/>\n</Keep>"
  end
end
