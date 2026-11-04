require 'spec_helper'
require 'live_set/model/live_clips'
require 'live_set/model/live_samples'
require 'live_set/serializer/live_samples_serializer'
require 'support/live_sets'

# The samples of the set, by the pack they are in.
#
# The expected values are the section of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe LiveSamplesSerializer, '#to_markdown' do
  # The samples of the set.
  #
  # @return [LiveSamples] the samples
  def samples
    tracks = LiveTracks.new LiveSets.directory(LiveSets.fascination),
                            LiveSets.nodes(LiveSets.fascination,
                                           '//MidiTrack | //AudioTrack | //GroupTrack')
    LiveSamples.new LiveClips.new(tracks).to_a
  end

  it 'writes the heading of the section' do
    expect(described_class.new(samples).to_markdown).to start_with "## Samples\n"
  end

  it 'names the samples of the set, by the pack they are in' do
    markdown = described_class.new(samples).to_markdown

    expect(markdown).to include('|User Library|`Pink Noise - EDMtips.com.wav` (not in the project)|')
    expect(markdown).to include('|Drive and Glow|`Tambourine 16th 84 bpm.aif` (not in the project)|')
  end
end
