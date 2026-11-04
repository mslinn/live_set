require 'spec_helper'
require 'live_set/serializer/live_clip_serializer'
require 'support/live_sets'

# A clip of a set.
#
# The expected values are the lines of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe LiveClipSerializer, '#to_markdown' do
  # The clip of the set with the given name.
  #
  # @param name [String] the name Live wrote
  # @return [LiveClip] the clip
  def clip(name)
    element = LiveSets.nodes(LiveSets.fascination, '//MidiClip | //AudioClip').find do |candidate|
      candidate.at('Name')&.[]('Value') == name
    end
    LiveClip.new element, place: 'session view'
  end

  it 'writes the name of the clip, on the colour Live gave it, with its mark and its file' do
    expect(described_class.new(clip('Pink Noise - EDMtips.com'), '1.1').to_markdown).to eq(
      '<code style="background-color: #FFA428; color: #000000; vertical-align: middle" ' \
      'title="Live color #1">Pink Noise - EDMtips.com</code>  ' \
      '<code style="background-color:#8B0000; color:#FFFFFF; vertical-align:middle">⚠ not in project</code>' \
      '<br>`Samples/Pink Noise - EDMtips.com.wav`'
    )
  end

  it 'writes the file the clip plays, on a line of its own' do
    expect(described_class.new(clip('Pink Noise - EDMtips.com'), '1.1').to_markdown).to end_with(
      '<br>`Samples/Pink Noise - EDMtips.com.wav`'
    )
  end

  it 'writes the mark of a clip whose sample is not in the project, on a dark red' do
    expect(described_class.new(clip('Pink Noise - EDMtips.com'), '1.1').to_markdown).to include(
      '<code style="background-color:#8B0000; color:#FFFFFF; vertical-align:middle">⚠ not in project</code>'
    )
  end

  it 'writes the name of a MIDI clip, which plays no file' do
    markdown = described_class.new(clip('3-Kontakt 7 1'), '1.1.1').to_markdown

    expect(markdown).to include('>Kontakt 7 1</code>')
    expect(markdown).not_to include('<br>')
  end
end
