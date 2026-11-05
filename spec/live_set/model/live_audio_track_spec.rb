require 'spec_helper'
require 'live_set/model/live_audio_track'
require 'support/live_sets'

# An audio track of a set.
#
# The tracks are the ones of the Live 11 reference set, which is checked in.
RSpec.describe LiveAudioTrack do
  subject(:track) { track_named('Tambo and Timbales Loop 90bpm') }

  around { |example| silence_output { example.run } }

  # The audio track with the given name.
  #
  # Live numbers the names of the tracks that share a name, and the number is not part of the
  # name.
  #
  # @param name [String] the name of the track
  # @return [LiveAudioTrack] the track
  def track_named(name)
    element = LiveSets.nodes(LiveSets.fascination, '//AudioTrack').find do |candidate|
      candidate.at('Name/EffectiveName')&.[]('Value')&.sub(/\A\d+[- ]/, '') == name
    end
    described_class.new LiveSets.directory(LiveSets.fascination), element
  end

  it 'is an audio track' do
    expect(track.kind).to eq 'Audio'
  end

  it 'holds the color Live wrote for it' do
    expect(track.color).to eq 21
  end

  it 'holds the audio clips of the track, and the place each of them is in' do
    expect(track.audio_clips.size).to eq 11
    expect(track.audio_clips.map(&:place).uniq).to include 'session view', 'arrangement'
  end

  it 'holds no MIDI clips, because the track of the set holds none' do
    expect(track.clips).to be_empty
  end

  it 'finds the devices nested in a group branch' do
    # The device chain of a track can be nested: an AudioEffectGroupDevice holds the chain of
    # a group in its branches. See docs/als_notes.md, "The device chain, and the chains
    # nested inside it".
    audio = track_named 'All'

    expect(audio.device_summary).to include('Eq8', 'Compressor2', 'Saturator')
  end
end
