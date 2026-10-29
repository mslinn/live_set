require 'spec_helper'
require 'conversions'
require 'support/live_sets'

# The conversion of a whole set, down to the Live 11 format.
#
# The set is a real one: the Live 12 version of the checked-in set with return tracks and a
# third-party device. Both reference sets are checked in, so the conversion can be proved
# against the set that Live 11 itself wrote, and not only against fragments.
#
# The other examples of the conversion are in live_11_and_12_down_spec.rb. Those walk the
# transformations one at a time; this one walks the whole set.
RSpec.describe LiveSet, 'converting a Live 12 set down to Live 11' do # rubocop:disable RSpec/DescribeMethod
  # The Live 12 set.
  let(:live12_path) { LiveSets.fascination12 }

  # The Live 11 set that Live 12 wrote from it, converted by this gem.
  let(:converted) { Conversions.in_process live12_path }

  # The Live 11 set that Live 11 wrote, which is the set the conversion is proved against.
  let(:live11) { LiveSets.document LiveSets.fascination }

  # The number of the elements of a name in a document.
  #
  # @param document [Nokogiri::XML::Document] the document
  # @param name [String] the name of the elements
  # @return [Integer] the number of the elements
  def count(document, name)
    document.xpath("//#{name}").length
  end

  it 'writes the version strings of a Live 11 set' do
    expect(converted.root['MinorVersion']).to eq '11.0_11300'
    expect(converted.root['Creator']).to eq 'Ableton Live 11.3.21'
    expect(converted.root['MajorVersion']).to eq '5'
    expect(converted.root['SchemaChangeCount']).to eq '3'
  end

  it 'keeps the tracks of the set' do
    expect(count(converted, 'AudioTrack')).to eq count(live11, 'AudioTrack')
    expect(count(converted, 'MidiTrack')).to eq count(live11, 'MidiTrack')
  end

  it 'keeps the clips of the set' do
    expect(count(converted, 'AudioClip')).to eq count(live11, 'AudioClip')
  end

  it 'keeps the groups of the set' do
    expect(count(converted, 'GroupTrack')).to eq count(live11, 'GroupTrack')
  end

  it 'keeps the third-party device of the set' do
    names = converted.xpath('//PluginDevice/PluginDesc/Vst3PluginInfo/Name').map { |node| node['Value'] }

    expect(names).to eq ['Kontakt 7']
    expect(count(converted, 'MxDeviceAudioEffect')).to eq count(live11, 'MxDeviceAudioEffect')
  end

  it 'removes the constructs Live 11 does not have' do
    %w[Roar MxPatchRef MidiEditorLaneModel InstrumentMeld IsTuned].each do |name|
      expect(count(converted, name)).to eq(0), "#{name} is not a Live 11 construct"
    end
  end

  it 'renames the width of the mixer, typo and all' do
    expect(count(converted, 'ViewStateSesstionTrackWidth')).to eq count(live11, 'ViewStateSesstionTrackWidth')
    expect(count(converted, 'ViewStateSessionTrackWidth')).to eq 0
  end

  it 'keeps the lanes of Live 11' do
    lanes = converted.xpath('//ContentLanes/*').map(&:name).uniq

    expect(lanes).to eq ['ExpressionLane']
  end

  it 'leaves the set it was given alone' do
    expect(LiveSets.document(live12_path).root['MinorVersion']).to eq '12.0_12402'
  end
end
