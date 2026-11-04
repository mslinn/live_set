require 'spec_helper'
require 'live_set/model/live_clips'
require 'live_set/model/live_samples'
require 'live_set/serializer/missing_samples_serializer'
require 'support/live_sets'

# The samples of the set that are not in the project, by the pack they are in.
#
# The expected values are the section of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe MissingSamplesSerializer, '#to_markdown' do
  # The samples of the set that are not in the project.
  #
  # @return [MissingSamples] the samples
  def missing
    tracks = LiveTracks.new LiveSets.directory(LiveSets.fascination),
                            LiveSets.nodes(LiveSets.fascination,
                                           '//MidiTrack | //AudioTrack | //GroupTrack')
    LiveSamples.new(LiveClips.new(tracks).to_a).missing
  end

  it 'writes the heading of the section' do
    expect(described_class.new(missing).to_markdown).to start_with "## Missing Samples\n"
  end

  it 'names the samples that are not in the project, by the pack they are in' do
    markdown = described_class.new(missing).to_markdown

    expect(markdown).to include('|User Library|`Pink Noise - EDMtips.com.wav`|')
    expect(markdown).to include('|Drive and Glow|`Tambourine 16th 84 bpm.aif`|')
  end
end
