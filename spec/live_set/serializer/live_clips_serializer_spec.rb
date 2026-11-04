require 'spec_helper'
require 'live_set/model/live_clips'
require 'live_set/serializer/live_clips_serializer'
require 'support/live_sets'

# The clips of the set, and the tracks that hold them.
#
# The expected values are the table of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe LiveClipsSerializer, '#to_markdown' do
  # The clips of the set.
  #
  # @return [LiveClips] the clips
  def clips
    tracks = LiveTracks.new LiveSets.directory(LiveSets.fascination),
                            LiveSets.nodes(LiveSets.fascination,
                                           '//MidiTrack | //AudioTrack | //GroupTrack')
    LiveClips.new tracks
  end

  it 'writes the columns of the table' do
    expect(described_class.new(clips).to_markdown).to include('|Clip|Tracks|')
  end

  it 'names the tracks that hold a clip' do
    markdown = described_class.new(clips).to_markdown

    expect(markdown).to include('|`Tambourine 16th 84 bpm`|1.2 Tambo and Timbales Loop 90bpm (take lane 1.2.1)')
  end
end
