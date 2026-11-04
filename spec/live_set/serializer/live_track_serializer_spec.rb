require 'spec_helper'
require 'live_set/serializer/live_track_serializer'
require 'support/live_sets'

# A track of a set.
#
# The expected values are the lines of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe LiveTrackSerializer, '#to_markdown' do
  # The track with the given name.
  #
  # @param name [String] the name of the track
  # @return [LiveTrack] the track
  def track(name)
    element = LiveSets.nodes(LiveSets.fascination,
                             '//MidiTrack | //AudioTrack | //GroupTrack | //Tracks/ReturnTrack').find do |candidate|
      candidate.at('Name/EffectiveName')&.[]('Value')&.sub(/\A\d+[- ]/, '') == name
    end
    LiveTrack.new LiveSets.directory(LiveSets.fascination), element
  end

  it 'writes the line of the track: its number, its icon, its kind and its name' do
    markdown = described_class.new(track('Tambo and Timbales Loop 90bpm'), '1.2').to_markdown

    expect(markdown.lines.first.chomp).to eq(
      '- Track 1.2  🎵 Audio  <code style="background-color: #18E9FE; color: #000000; ' \
      'vertical-align: middle" title="Live color #21">Tambo and Timbales Loop 90bpm</code>'
    )
  end

  it 'writes the devices of the track under it' do
    markdown = described_class.new(track('Kontakt 7'), '1.1').to_markdown

    expect(markdown).to include(
      '  - Track Device 1.1a  <code style="background-color: #212121; color: #FFFFFF; ' \
      'vertical-align: middle">Kontakt 7</code>  VST3  ⚠ not usable on Push 3'
    )
  end

  it 'writes the name of a track Push 3 cannot use on the dark background' do
    markdown = described_class.new(track('Kontakt 7'), '1.1').to_markdown

    expect(markdown.lines.first.chomp).to eq(
      '- Track 1.1  🎹 MIDI  <code style="background-color: #212121; color: #FFFFFF; ' \
      'vertical-align: middle">Kontakt 7</code>'
    )
  end

  it 'writes the clips of the track under it' do
    markdown = described_class.new(track('Tambo and Timbales Loop 90bpm'), '1.2').to_markdown

    expect(markdown).to include('  * Clip 1.2.1 (×7) ')
  end

  it 'writes the take lanes of the track under it' do
    markdown = described_class.new(track('Pink Noise - EDMtips.com'), '1').to_markdown

    expect(markdown).to include('  - Take lane 1.1  Pink Noise - EDMtips.com')
  end

  it 'writes the name of a track with a character that would break a table, escaped' do
    markdown = described_class.new(track('A-Fresh Room | EQ Eight'), '4').to_markdown

    expect(markdown.lines.first.chomp).to include('A-Fresh Room &#124; EQ Eight</code>')
  end
end
