require 'spec_helper'
require 'live_set/model/live_track_clip_cross_reference'
require 'live_set/serializer/live_tracks_serializer'
require 'live_set/serializer/track_clip_cross_reference_serializer'
require 'support/live_fixtures'

# The tracks of the set, and the clips they hold.
#
# The model is inflated from the fixture data: the XML of the largest Live 12 demo set.
# See docs/serializer_plan.md, "Testing".
RSpec.describe TrackClipCrossReferenceSerializer, '#to_markdown' do
  # The tracks of the set.
  #
  # @return [LiveTracks] the tracks of the set
  def tracks
    @tracks ||= begin
      document = LiveFixtures.document 'live_12_suite_demo'
      elements = document.xpath('//MidiTrack | //AudioTrack | //GroupTrack | //Tracks/ReturnTrack | ' \
                                '//MasterTrack | //MainTrack')
      LiveTracks.new LiveFixtures.directory_of('live_12_suite_demo'), elements
    end
  end

  # The tracks of the set, and the clips they hold.
  #
  # @return [LiveTrackClipCrossReference] the cross-reference
  def cross_reference
    @cross_reference ||= LiveTrackClipCrossReference.new(
      LiveTracksSerializer.new(tracks).numbered_tracks
    )
  end

  it 'writes the heading of the section, and the two tables under it' do
    markdown = described_class.new(cross_reference).to_markdown

    expect(markdown).to include("## Track / Clip Cross Reference\n")
    expect(markdown).to include('### Tracks And Their Clips')
    expect(markdown).to include('### Clips And Their Tracks')
  end

  it 'writes the tracks of the set, and the places the clips of each are in' do
    markdown = described_class.new(cross_reference).to_markdown

    expect(markdown).to include('|Track|Clips|')
    expect(markdown).to include('`Coffee Lead` session view ×3, arrangement ×3')
    expect(markdown).to include('`Drift 3` take lane 1.3 ×2')
  end

  it 'writes the clips of the set, and the tracks that hold them' do
    markdown = described_class.new(cross_reference).to_markdown

    expect(markdown).to include('|Clip|Tracks|')
    expect(markdown).to include('`Strum-o-Matic`|')
    expect(markdown).to include('`Drift`|1 Coffee Leaf (take lane 1.1), 5 Mello (take lane 5.1)|')
  end
end
