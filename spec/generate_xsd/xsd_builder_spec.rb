require 'spec_helper'

RSpec.describe XsdBuilder do
  # A minimal Ableton Live set. The root element carries attributes, one leaf element carries a
  # Value attribute, one element carries nothing at all, and a container holds two tracks.
  #
  # @return [String] the XML of the set
  def simple_set
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <Ableton MajorVersion="5" MinorVersion="12.0_12000" SchemaChangeCount="3" Creator="Ableton Live 12.4d1" Revision="abc123">
        <LiveSet>
          <NextPointeeId Value="260122"/>
          <NoValue/>
          <Tracks>
            <AudioTrack Id="3">
              <Name><EffectiveName Value="Test Track"/></Name>
              <Freeze Value="false"/>
            </AudioTrack>
            <AudioTrack Id="4">
              <Name><EffectiveName Value="Second Track"/></Name>
              <Freeze Value="false"/>
            </AudioTrack>
          </Tracks>
        </LiveSet>
      </Ableton>
    XML
  end

  # A Live set whose tracks have no Id attribute.
  #
  # @return [String] the XML of the set
  def set_without_track_ids
    simple_set.gsub('<AudioTrack Id="3">', '<AudioTrack>').gsub('<AudioTrack Id="4">', '<AudioTrack>')
  end

  # A Live set whose LiveSet element has an extra child element.
  #
  # @return [String] the XML of the set
  def set_with_extra_child
    simple_set.sub(%r{^(\s*)</Tracks>}, "\\1</Tracks>\n\\1<Extra/>")
  end

  # A Live set whose LiveSet element lists its children in a different order.
  #
  # @return [String] the XML of the set
  def reordered_set
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <Ableton MajorVersion="5" MinorVersion="12.0_12000" SchemaChangeCount="3" Creator="Ableton Live 12.4d1" Revision="abc123">
        <LiveSet>
          <Tracks>
            <AudioTrack Id="3">
              <Name><EffectiveName Value="Test Track"/></Name>
              <Freeze Value="false"/>
            </AudioTrack>
            <AudioTrack Id="4">
              <Name><EffectiveName Value="Second Track"/></Name>
              <Freeze Value="false"/>
            </AudioTrack>
          </Tracks>
          <NextPointeeId Value="260122"/>
          <NoValue/>
        </LiveSet>
      </Ableton>
    XML
  end

  # A Live set whose tracks are not grouped by type.
  #
  # A MIDI track comes between two audio tracks, so no sequence of child elements can describe
  # them.
  #
  # @return [String] the XML of the set
  def interleaved_set
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <Ableton MajorVersion="5" MinorVersion="12.0_12000" SchemaChangeCount="3" Creator="Ableton Live 12.4d1" Revision="abc123">
        <LiveSet>
          <NextPointeeId Value="260122"/>
          <NoValue/>
          <Tracks>
            <AudioTrack Id="3">
              <Name><EffectiveName Value="Test Track"/></Name>
              <Freeze Value="false"/>
            </AudioTrack>
            <MidiTrack Id="4">
              <Name><EffectiveName Value="MIDI Track"/></Name>
              <Freeze Value="false"/>
            </MidiTrack>
            <AudioTrack Id="5">
              <Name><EffectiveName Value="Second Track"/></Name>
              <Freeze Value="false"/>
            </AudioTrack>
          </Tracks>
        </LiveSet>
      </Ableton>
    XML
  end

  # Builds the schema for the given Live sets.
  #
  # @param sets [Array<String>] the XML of each set
  # @return [String] the generated schema
  def schema_for(sets)
    roots = sets.map { |xml| Nokogiri::XML(xml).root }

    described_class.new(roots).build
  end

  describe '#build' do
    it 'is a well-formed XML document' do
      schema = schema_for([simple_set])

      expect { Nokogiri::XML::Schema(schema) }.not_to raise_error
    end

    it 'generates a schema that validates the set it was generated from' do
      schema = Nokogiri::XML::Schema(schema_for([simple_set]))
      document = Nokogiri::XML(simple_set)

      expect(schema.validate(document)).to be_empty
    end

    it 'declares the root element' do
      schema = schema_for([simple_set])

      expect(schema).to include('<xs:element name="Ableton">')
    end

    it 'types an element that has no children and no attributes as a string' do
      schema = schema_for([simple_set])

      expect(schema).to include('<xs:element name="NoValue" type="xs:string"/>')
    end

    it 'declares the attributes that the elements carry' do
      schema = schema_for([simple_set])

      expect(schema).to include('<xs:attribute name="Value" type="xs:string" use="required"/>')
      expect(schema).to include('<xs:attribute name="Id" type="xs:string" use="required"/>')
    end

    it 'declares an attribute that some instances lack as optional' do
      schema = schema_for([simple_set, set_without_track_ids])

      expect(schema).to include('<xs:attribute name="Id" type="xs:string"/>')
    end

    it 'declares a child element that some instances lack as optional' do
      schema = schema_for([simple_set, set_with_extra_child])

      expect(schema).to include('<xs:element name="Extra" minOccurs="0" type="xs:string"/>')
    end

    it 'declares a child element that repeats as unbounded' do
      schema = schema_for([simple_set])

      expect(schema).to include('<xs:element name="AudioTrack" maxOccurs="unbounded">')
    end

    it 'explains that it was generated from a sample' do
      schema = schema_for([simple_set])

      expect(schema).to include('inference from a sample of the format')
    end

    it 'accepts the child elements in any order when the sample files disagree' do
      schema = schema_for([simple_set, reordered_set])

      expect(schema).to include('<xs:choice minOccurs="0" maxOccurs="unbounded">')
    end

    it 'generates a schema that validates a set whose children are in a different order' do
      schema = Nokogiri::XML::Schema(schema_for([simple_set, reordered_set]))
      document = Nokogiri::XML(reordered_set)

      expect(schema.validate(document)).to be_empty
    end

    it 'accepts the child elements in any order when a child element repeats' do
      allow(Log).to receive(:warn)

      schema = schema_for([simple_set, interleaved_set])

      expect(schema).to include('<xs:choice minOccurs="0" maxOccurs="unbounded">')
    end

    it 'generates a schema that validates a set whose child elements are interleaved' do
      schema = Nokogiri::XML::Schema(schema_for([simple_set, interleaved_set]))
      document = Nokogiri::XML(interleaved_set)

      expect(schema.validate(document)).to be_empty
    end

    it 'does not warn when the sample files agree about the order of child elements' do
      allow(Log).to receive(:warn)

      schema_for([simple_set, simple_set])

      expect(Log).not_to have_received(:warn)
    end

    it 'does not warn when one sample has a child element the others lack' do
      allow(Log).to receive(:warn)

      schema_for([simple_set, set_with_extra_child])

      expect(Log).not_to have_received(:warn)
    end
  end
end
