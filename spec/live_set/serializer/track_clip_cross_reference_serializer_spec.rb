require 'spec_helper'
require 'live_set/serializer/track_clip_cross_reference_serializer'
require 'support/live_sets'

# The tracks of the set, and the clips they hold.
#
# The expected values are the section of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe TrackClipCrossReferenceSerializer, '#to_markdown' do
  # The tracks of the set.
  #
  # @return [LiveTracks] the tracks
  def tracks
    LiveTracks.new LiveSets.directory(LiveSets.fascination),
                   LiveSets.nodes(LiveSets.fascination,
                                  '//MidiTrack | //AudioTrack | //GroupTrack')
  end

  it 'writes the heading of the section, and the two tables under it' do
    markdown = described_class.new(tracks).to_markdown

    expect(markdown).to include("## Track / Clip Cross Reference\n")
    expect(markdown).to include('### Tracks and their clips')
    expect(markdown).to include('### Clips and their tracks')
  end

  it 'writes the tracks of the set, and the places the clips of each are in' do
    markdown = described_class.new(tracks).to_markdown

    expect(markdown).to include('|Track|Clips|')
    expect(markdown).to include('`Kontakt 7 1` session view ×2, arrangement ×3, take lane 1.1.1 ×3')
  end

  it 'writes the clips of the set, and the tracks that hold them' do
    markdown = described_class.new(tracks).to_markdown

    expect(markdown).to include('|Clip|Tracks|')
    expect(markdown).to include('`Tambourine 16th 84 bpm`|')
  end
end
