require 'spec_helper'
require 'live_set/model/live_device_cross_reference'
require 'live_set/model/live_devices'
require 'live_set/serializer/device_cross_reference_serializer'
require 'support/live_fixtures'

# The devices of the set, and the tracks they are on.
#
# The model is inflated from the fixture data: the XML of the largest Live 12 demo set.
# See docs/serializer_plan.md, "Testing".
RSpec.describe DeviceCrossReferenceSerializer, '#to_markdown' do
  # The devices of the set, and the tracks they are on.
  #
  # @return [LiveDeviceCrossReference] the cross-reference
  def cross_reference
    @cross_reference ||= begin
      document = LiveFixtures.document 'live_12_suite_demo'
      elements = document.xpath('//MidiTrack | //AudioTrack | //GroupTrack | //Tracks/ReturnTrack | ' \
                                '//MasterTrack | //MainTrack')
      tracks = LiveTracks.new LiveFixtures.directory_of('live_12_suite_demo'), elements
      LiveDeviceCrossReference.new LiveDevices.new(tracks.top_level)
    end
  end

  it 'writes the heading of the section' do
    expect(described_class.new(cross_reference).to_markdown).to start_with "## Device/Track Cross-Reference\n"
  end

  it 'writes the columns of the table' do
    expect(described_class.new(cross_reference).to_markdown).to include('|Device|Kind|Tracks With This Device|')
  end

  it 'names the tracks a device is on' do
    markdown = described_class.new(cross_reference).to_markdown

    expect(markdown).to include('|<nobr><code>Drift</code></nobr>|Live|')
    expect(markdown).to include('Coffee Leaf</code>')
  end
end
