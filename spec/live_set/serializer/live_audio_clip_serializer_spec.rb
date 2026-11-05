require 'spec_helper'
require 'live_set/model/live_tracks'
require 'live_set/serializer/live_audio_clip_serializer'
require 'support/live_fixtures'

# A clip of the audio side of a track.
#
# The clip is a real one, from the XML of the largest Live 12 demo set. See
# docs/serializer_plan.md, "Testing".
RSpec.describe LiveAudioClipSerializer, '#to_markdown' do
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

  it 'writes the name of the clip, on the colour Live gave it' do
    expect(described_class.new(clip, '11.1').to_markdown).to include(
      '<code style="background-color: #F6F57C; color: #000000; vertical-align: middle" ' \
      'title="Live color #3">Vocal Main</code>'
    )
  end

  it 'writes the file the clip plays, on a line of its own' do
    expect(described_class.new(clip, '11.1').to_markdown).to include(
      '<br>`Samples/Loops/Tonal/Vocal/Vocal Patience Main.wav`'
    )
  end

  it 'writes the warning for a clip whose sample is not in the project, on a dark red background' do
    expect(described_class.new(clip, '11.1').to_markdown).to include(
      '<code style="background-color:#8B0000; color:#FFFFFF; vertical-align:middle">⚠ not in project</code>'
    )
  end

  it 'writes the place the clip is in' do
    expect(described_class.new(clip, '11.1').to_markdown).to include('  session view  ')
  end

  it 'writes the size of the file the clip plays' do
    expect(described_class.new(clip, '11.1').to_markdown).to include('12.83 MB (12830744 bytes)')
  end
end
