require 'spec_helper'
require 'live_set/model/live_audio_clip'
require 'live_set/model/live_audio_track'
require 'support/live_sets'

# The clips of a track, and where they come from.
#
# The track is a real one: the "Lead" track of the Live 11 Suite demo set. It has clips in the
# session view, in the arrangement and in the take lanes, and every one of its 27 clips refers
# to the same file.
RSpec.describe LiveAudioTrack, '#audio_clips' do
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

  it 'says where each clip is' do
    expect(track.audio_clips.map(&:place).uniq)
      .to contain_exactly('session view', 'arrangement', 'take lane 1', 'take lane 2', 'take lane 3')
  end

  it 'finds the clips in the session view' do
    expect(track.audio_clips.in_place('session view').length).to eq(3)
  end

  it 'finds the clips in the arrangement' do
    expect(track.audio_clips.in_place('arrangement').length).to eq(21)
  end

  it 'finds the clips in the take lanes' do
    expect(track.audio_clips.in_lanes.length).to eq(3)
  end

  it 'reads the sample path from each clip' do
    expect(track.audio_clips.in_place('session view').map(&:relative_path).uniq)
      .to eq(['Samples/Loops/Tonal/Vocal/Vocal Demo Lead Takes.aif'])
  end

  it 'finds the same file in each of the three sources' do
    places = ['session view', 'arrangement']
    expect(places.map { |place| track.audio_clips.in_place(place).map(&:relative_path).uniq.length })
      .to eq([1, 1])
    expect(track.audio_clips.in_lanes.map(&:relative_path).uniq.length).to eq(1)
  end
end
