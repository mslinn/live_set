require 'spec_helper'
require 'live_set/live_set_class'

# The -11 conversion rewrites the version strings and removes the Live 12-only elements it knows
# about. Everything else is copied through unchanged.
#
# See docs/als_format.md section 9.2.1 for why group tracks are kept, and section 12 for the
# elements that are removed.
RSpec.describe LiveSet, '#modify_als' do
  # The directory the set is written to.
  let(:dir) { Dir.mktmpdir }

  # The path of the set that is converted.
  let(:set_path) { File.join dir, 'set.als' }

  # The path of the converted set.
  let(:output_path) { File.join dir, 'set_11.als' }

  after { FileUtils.remove_entry dir }

  # Writes a set with the given body inside <Tracks>.
  def write_set(body)
    Zlib::GzipWriter.open(set_path) { |gz| gz.write build_set(body) }
    set_path
  end

  # Builds the XML of a minimal set with the given body inside <Tracks>.
  def build_set(body)
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <Ableton MajorVersion="5" MinorVersion="12.0_12120" SchemaChangeCount="3"
               Creator="Ableton Live 12.2.1" Revision="c0d59beb">
        <LiveSet>
          <Tracks>
      #{body}
          </Tracks>
          <Scenes/>
        </LiveSet>
      </Ableton>
    XML
  end

  # A track element.
  def track_xml(name: 'Track')
    <<~XML
      <AudioTrack Id="1">
        <Name><EffectiveName Value="#{name}"/></Name>
        <Freeze Value="false"/>
        <DeviceChain>
          <MainSequencer><ClipSlotList/></MainSequencer>
        </DeviceChain>
      </AudioTrack>
    XML
  end

  # A group track element.
  def group_xml(name: 'Group')
    <<~XML
      <GroupTrack Id="2">
        <Name><EffectiveName Value="#{name}"/></Name>
        <TrackGroupId Value="-1"/>
        <Freeze Value="false"/>
        <DeviceChain><FreezeSequencer><ClipSlotList/></FreezeSequencer></DeviceChain>
      </GroupTrack>
    XML
  end

  # Reads a set back as a document.
  def read_set(path = output_path)
    Nokogiri::XML Zlib::GzipReader.open(path, &:read)
  end

  describe 'the Live 11 version strings' do
    it 'writes the Live 11 creator' do
      described_class.new(write_set(track_xml)).modify_als

      expect(read_set.at('//Ableton')['Creator']).to eq('Ableton Live 11.3.21')
    end

    it 'writes the Live 11 minor version' do
      described_class.new(write_set(track_xml)).modify_als

      expect(read_set.at('//Ableton')['MinorVersion']).to eq('11.0_11300')
    end
  end

  describe 'the elements it removes' do
    it 'removes a ContentLanes element' do
      described_class.new(write_set("#{track_xml}<ContentLanes/>")).modify_als

      expect(read_set.xpath('//ContentLanes')).to be_empty
    end

    it 'removes an Oversampling element' do
      described_class.new(write_set("#{track_xml}<Oversampling/>")).modify_als

      expect(read_set.xpath('//Oversampling')).to be_empty
    end
  end

  describe 'the elements it keeps' do
    it 'keeps the tracks' do
      described_class.new(write_set(track_xml)).modify_als

      expect(read_set.xpath('//AudioTrack').length).to eq(1)
    end

    it 'keeps the group tracks' do
      described_class.new(write_set(group_xml)).modify_als

      expect(read_set.xpath('//GroupTrack').length).to eq(1)
    end

    it 'keeps an element it does not know about' do
      described_class.new(write_set("#{track_xml}<SomeFutureElement Value=\"1\"/>")).modify_als

      expect(read_set.xpath('//SomeFutureElement').length).to eq(1)
    end

    it 'keeps an unknown element inside a group track' do
      body = group_xml.sub('</GroupTrack>', '<SomeFutureElement Value="1"/></GroupTrack>')
      described_class.new(write_set(body)).modify_als

      expect(read_set.xpath('//SomeFutureElement').length).to eq(1)
    end
  end

  describe 'a FakeGroup element' do
    # There is a claim that the .als format uses a <FakeGroup> element for nested groups. No set
    # examined has one, so it is not a documented element. The conversion copies through anything
    # it does not recognise, so a FakeGroup is preserved rather than lost.
    #
    # See docs/als_format.md section 9.2.1 and TODO.md N43.
    let(:fake_group) { '<FakeGroup Id="999"><LomId Value="0"/></FakeGroup>' }

    it 'is copied to the output' do
      described_class.new(write_set("#{track_xml}#{fake_group}")).modify_als

      expect(read_set.xpath('//FakeGroup').length).to eq(1)
    end

    it 'keeps its attributes' do
      described_class.new(write_set("#{track_xml}#{fake_group}")).modify_als

      expect(read_set.at('//FakeGroup')['Id']).to eq('999')
    end

    it 'is copied when it is inside a group track' do
      body = group_xml.sub('</GroupTrack>', "#{fake_group}</GroupTrack>")
      described_class.new(write_set(body)).modify_als

      expect(read_set.xpath('//GroupTrack/FakeGroup').length).to eq(1)
    end

    it 'is not counted as a track' do
      live_set = described_class.new write_set("#{track_xml}#{fake_group}")
      instances = live_set.instance_variable_get(:@tracks).instance_variable_get(:@track_instances)

      expect(instances.length).to eq(1)
    end
  end
end
