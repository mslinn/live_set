require 'spec_helper'
require 'live_set/serializer/live_midi_clip_serializer'
require 'support/live_sets'

# A MIDI clip of a set.
#
# The expected values are the lines of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe LiveMidiClipSerializer, '#to_markdown' do
  # The clip of the set with the given name.
  #
  # @param name [String] the name Live wrote
  # @return [LiveMidiClip] the clip
  def clip(name)
    element = LiveSets.nodes(LiveSets.fascination, '//MidiClip').find do |candidate|
      candidate.at('Name')&.[]('Value') == name
    end
    LiveMidiClip.new element, place: 'session view' # TODO: Why are we only testing clips in session view?
  end

  it 'writes the name of the clip, using the colours stored in the ALS XML' do
    expected = described_class.new(clip('3-Kontakt 7 1'), '1.1.1').to_markdown
    expect(expected).to eq(
      '<code style="color: #000000; background-color: #FFA428; vertical-align: middle;" ' \
      'title="Live color #1">Kontakt 7 1</code>'
    )
  end

  it 'writes no file, because a MIDI clip plays no file' do
    expected = described_class.new(clip('3-Kontakt 7 1'), '1.1.1').to_markdown
    expect(expected).not_to include('<br>') # TODO: this test makes no sense. how does this relate to midi clips?
  end
end
