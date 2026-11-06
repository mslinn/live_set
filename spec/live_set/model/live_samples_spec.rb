require 'spec_helper'
require 'live_set/model/live_samples'
require 'live_set/model/live_tracks'
require 'support/live_sets'

# The samples of a set.
#
# The samples are the ones of the Live 11 reference set, which is checked in.
RSpec.describe LiveSamples do
  # The samples of the set.
  #
  # @return [LiveSamples] the samples
  def samples
    @samples ||= begin
      elements = LiveSets.nodes(LiveSets.fascination, '//MidiTrack | //AudioTrack | //GroupTrack')
      tracks = LiveTracks.new LiveSets.directory(LiveSets.fascination), elements
      LiveSamples.new tracks.audio_clips, LiveSets.directory(LiveSets.fascination)
    end
  end

  it 'holds a sample for every file the set plays' do
    expect(samples.samples.map(&:name)).to include 'Pink Noise - EDMtips.com.wav'
  end

  it 'writes a sample in only one of the two sections' do
    located = samples.located.map(&:name)
    missing = samples.missing.map(&:name)

    expect(located & missing).to be_empty
  end

  it 'holds the sample that has not been collected into the project as a missing one' do
    expect(samples.missing.map(&:name)).to eq ['Pink Noise - EDMtips.com.wav']
  end

  it 'holds the sample of the pack as a located one, because the pack holds it' do
    expect(samples.located.map(&:name)).to eq ['Tambourine 16th 84 bpm.aif']
  end

  it 'holds the packs the set refers to' do
    expect(samples.packs.packs.map(&:name)).to eq ['Drive and Glow']
  end
end
