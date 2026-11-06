require 'spec_helper'
require 'live_set/model/live_audio_track'
require 'live_set/serializer/live_audio_track_serializer'
require 'support/live_sets'

# An audio track of a set.
#
# The expected values are the lines of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe LiveAudioTrackSerializer, '#to_markdown' do
  around { |example| silence_output { example.run } }

  # The audio track with the given name.
  #
  # @param name [String] the name of the track
  # @return [LiveAudioTrack] the track
  def track(name)
    element = LiveSets.nodes(LiveSets.fascination, '//AudioTrack').find do |candidate|
      candidate.at('Name/EffectiveName')&.[]('Value')&.sub(/\A\d+[- ]/, '') == name
    end
    LiveAudioTrack.new LiveSets.directory(LiveSets.fascination), element
  end

  it 'writes the line of the track: its number, its icon, its kind and its name' do
    markdown = described_class.new(track('Tambo and Timbales Loop 90bpm'), '1.2').to_markdown

    expect(markdown.lines.first.chomp).to eq(
      '    - Track 1.2  🎵 Audio  <code style="color: #000000; background-color: #18E9FE; ' \
      'vertical-align: middle;" title="Live color #21">Tambo and Timbales Loop 90bpm</code>'
    )
  end

  it 'writes the clips of the audio side of the track under it' do
    markdown = described_class.new(track('Tambo and Timbales Loop 90bpm'), '1.2').to_markdown

    expect(markdown).to include('    - Audio Clip 1.2.1 (×11) ')
  end

  it 'writes the file the clip plays, and the size of it' do
    markdown = described_class.new(track('Tambo and Timbales Loop 90bpm'), '1.2').to_markdown

    expect(markdown).to include(
      '`Samples/Loops and Chords/Drum Loops/Perc Loops/Tambourine 16th 84 bpm.aif`  session view'
    )
  end

  it 'writes the take lanes of the track under it' do
    markdown = described_class.new(track('Tambo and Timbales Loop 90bpm'), '1.2').to_markdown

    expect(markdown).to include('    - Take lane 1.2.1  Tambourine 16th 84 bpm')
  end
end
