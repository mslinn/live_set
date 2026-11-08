require 'spec_helper'
require 'live_set/model/live_midi_track'
require 'live_set/serializer/live_midi_track_serializer'
require 'support/live_sets'

# A MIDI track of a set.
#
# The expected values are the lines of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe LiveMidiTrackSerializer, '#to_markdown' do
  # The MIDI track with the given name.
  #
  # @param name [String] the name of the track
  # @return [LiveMidiTrack] the track
  def track(name)
    element = LiveSets.nodes(LiveSets.fascination, '//MidiTrack').find do |candidate|
      candidate.at('Name/EffectiveName')&.[]('Value')&.sub(/\A\d+[- ]/, '') == name
    end
    LiveMidiTrack.new LiveSets.directory(LiveSets.fascination), element
  end

  it 'writes the line of the track: its number, its icon, its kind and its name' do
    markdown = described_class.new(track('Beat That Bass'), '1.2').to_markdown

    expect(markdown.lines.first.chomp).to eq(
      '    - Track 1.2  🎹 MIDI  <code style="color: #FFFFFF; background-color: #007DC0; ' \
      'vertical-align: middle;" title="Live color #23">Beat That Bass</code>'
    )
  end

  it 'writes the devices of the track under it' do
    markdown = described_class.new(track('Kontakt 7'), '1.1').to_markdown

    expect(markdown).to include(
      '    - Track Device 1.1a  <code style="color: #FFFFFF; background-color: #212121; ' \
      'vertical-align: middle;">Kontakt 7</code>  VST3  ⚠ not usable on P3S'
    )
  end

  it 'writes the name of a track P3S cannot use on the dark background' do
    markdown = described_class.new(track('Kontakt 7'), '1.1').to_markdown

    expect(markdown.lines.first.chomp).to eq(
      '    - Track 1.1  🎹 MIDI  <code style="color: #FFFFFF; background-color: #212121; ' \
      'vertical-align: middle;">Kontakt 7</code>'
    )
  end

  it 'writes the MIDI clips of the track under it' do
    markdown = described_class.new(track('Kontakt 7'), '1.1').to_markdown

    expect(markdown).to include('    - Clip 1.1.1 (×5) ')
  end

  it 'writes the take lanes of the track under it' do
    markdown = described_class.new(track('Kontakt 7'), '1.1').to_markdown

    expect(markdown).to include('    - Take lane 1.1.1  3-Kontakt 7 1')
  end
end
