require 'spec_helper'
require 'live_set/model/live_devices'
require 'live_set/serializer/device_cross_reference_serializer'
require 'support/live_sets'

# The devices of the set, and the tracks they are on.
#
# The expected values are the section of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe DeviceCrossReferenceSerializer, '#to_markdown' do
  # The devices of the set.
  #
  # @return [LiveDevices] the devices
  def devices
    tracks = LiveTracks.new LiveSets.directory(LiveSets.fascination),
                            LiveSets.nodes(LiveSets.fascination,
                                           '//MidiTrack | //AudioTrack | //GroupTrack')
    LiveDevices.new tracks.top_level
  end

  it 'writes the heading of the section' do
    expect(described_class.new(devices).to_markdown).to start_with "## Device/Track Cross-Reference\n"
  end

  it 'writes the columns of the table' do
    expect(described_class.new(devices).to_markdown).to include('|Device|Kind|Tracks With This Device|')
  end

  it 'names the tracks a device is on' do
    markdown = described_class.new(devices).to_markdown

    expect(markdown).to include('|<code>DrumBuss</code>|Live|')
    expect(markdown).to include('Kontakt 7</code>')
  end
end
