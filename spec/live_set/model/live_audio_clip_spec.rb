require 'spec_helper'
require 'live_set/model/live_audio_clip'
require 'live_set/model/live_tracks'
require 'support/live_fixtures'

# A clip of the audio side of a track.
#
# The clip is a real one, from the XML of the largest Live 12 demo set. See
# docs/serializer_plan.md, "Testing".
RSpec.describe LiveAudioClip do
  around { |example| silence_output { example.run } }

  # The first clip of the audio side of the first track of the set.
  #
  # @return [LiveAudioClip] the clip
  def clip
    @clip ||= begin
      document = LiveFixtures.document 'live_12_suite_demo'
      elements = document.xpath('//AudioTrack')
      tracks = LiveTracks.new LiveFixtures.directory_of('live_12_suite_demo'), elements
      tracks.top_level.first.audio_clips.first
    end
  end

  it 'holds the name of the clip' do
    expect(clip.name).to eq 'Vocal Main'
  end

  it 'holds the colour Live wrote for it' do
    expect(clip.color).to eq 3
  end

  it 'holds the place it is in' do
    expect(clip.place).to eq 'session view'
  end

  it 'holds the file it plays' do
    expect(clip.file).to eq 'Samples/Loops/Tonal/Vocal/Vocal Patience Main.wav'
  end

  it 'holds the size of the file' do
    expect(clip.file_size).to eq 12_830_744
  end

  it 'is not collected, because its file is not in the project folder' do
    expect(clip).not_to be_collected
    expect(clip.messages).to eq ['⚠ missing']
  end

  it 'is named after the file it plays, in the cross-reference' do
    expect(clip.label).to eq 'Vocal Patience Main'
  end
end
