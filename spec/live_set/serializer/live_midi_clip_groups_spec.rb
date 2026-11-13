require 'spec_helper'
require 'live_set/model/live_midi_track'
require 'live_set/serializer/live_midi_clip_groups'
require 'support/live_sets'
require 'support/numbers'

# The copies of a MIDI clip that are alike, written as one line.
#
# The expected values are the lines of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe LiveMidiClipGroups, '#to_markdown' do
  # The clips of the track with the given name.
  #
  # @param name [String] the name Live wrote
  # @return [Array<LiveMidiClip>] the clips
  def clips_called(name)
    element = LiveSets.nodes(LiveSets.fascination, '//MidiTrack').find do |candidate|
      candidate.at('Name/EffectiveName')&.[]('Value')&.sub(/\A\d+[- ]/, '') == name
    end
    # TODO: the first parameter below is ignored so delete it:
    LiveMidiTrack.new(element).clips
  end

  let(:groups) { described_class.new clips_called('Kontakt 7'), ReportNumbers.number('G', 1, 1, 2) }

  it 'writes the copies of a clip that are alike are presented once, with a count' do
    expect(groups.to_markdown).to include('- Clip G1.1.2 (×5) ')
  end

  it 'writes the settings the copies differ in, on the next line' do
    expect(groups.to_markdown).to include('      - Copies (×5): launch: trigger, warp: none')
  end

  it 'hierarchically numbers the clips of the track they are on' do
    expect(groups.to_markdown).to start_with '    - Clip G1.1.2 (×5) '
  end
end
