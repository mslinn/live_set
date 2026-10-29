require 'spec_helper'
require 'live_set/live_set_track'
require 'live_set/live_set_audio_clip'
require 'support/live_sets'

# The clips of a track, and where they come from.
#
# The track is a real one: the "Lead" track of the Live 11 Suite demo set. It has clips in the
# session view, in the arrangement and in the take lanes, and every one of its 27 clips refers
# to the same file.
RSpec.describe LiveTrack, '#audio_clips' do
  around { |example| silence_output { example.run } }

  # The path of the set the track is in.
  def path
    LiveSets.suite
  end

  # The track.
  def track
    @track ||= described_class.new LiveSets.directory(path),
                                   LiveSets.node(path, '//AudioTrack[@Id="150"]')
  end

  it 'groups the clips by where they come from' do
    expect(track.audio_clips.keys).to eq(['Session view', 'Arrangement', 'Take lanes'])
  end

  it 'finds the clips in the session view' do
    expect(track.audio_clips['Session view'].length).to eq(3)
  end

  it 'finds the clips in the arrangement' do
    expect(track.audio_clips['Arrangement'].length).to eq(21)
  end

  it 'finds the clips in the take lanes' do
    expect(track.audio_clips['Take lanes'].length).to eq(3)
  end

  it 'reads the sample path from each clip' do
    expect(track.audio_clips['Session view'].map(&:relative_path).uniq)
      .to eq(['Samples/Loops/Tonal/Vocal/Vocal Demo Lead Takes.aif'])
  end

  it 'finds the same file in each of the three sources' do
    expect(track.audio_clips.values.map { |clips| clips.map(&:relative_path).uniq.length })
      .to eq([1, 1, 1])
  end

  it 'reports no clips for a track that has none' do
    # A MIDI track holds clips in its slots, but they are MIDI clips, and there are no audio
    # clips in it at all.
    midi = described_class.new LiveSets.directory(path), LiveSets.node(path, '//MidiTrack')

    expect(midi.distinct_clips).to be_empty
  end
end
