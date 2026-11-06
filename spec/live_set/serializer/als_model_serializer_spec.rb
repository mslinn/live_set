require 'spec_helper'
require 'live_set/model/als_model'
require 'live_set/model/header_block'
require 'live_set/serializer/als_model_serializer'
require 'support/live_sets'

# The report of a set, as a whole.
#
# The expected value is the report of the set as it is written now:
#
#   sets/live_11/reports/Fascination.md
#
# The report is a document, so what is expected of it is the order of its sections: the
# header block, the metadata of the set, the verdict for a transfer to Push 3 Standalone, the
# hierarchy of the groups, the tracks, the clips and the devices, the samples that are not in
# the project, the two cross-references, the assets of the set, and the state of the machine
# the report was made on.
RSpec.describe AlsModelSerializer, '#to_markdown' do
  # The model of the set.
  #
  # @param separately [Boolean] whether the audio tracks and the MIDI tracks are written in
  #   their own lists
  # @return [AlsModel] the model
  def model(separately: false)
    path = LiveSets.fascination
    document = LiveSets.document path
    header = HeaderBlock.new path, document, nil
    AlsModel.new path, document, header, show_midi_and_audio_tracks_separately: separately
  end

  it 'writes the sections of the report, in order' do
    markdown = described_class.new(model).to_markdown

    expect(markdown.scan(/^## .*$/)).to eq [
      '## Metadata',
      '## Push 3 Standalone',
      '## Groups/Tracks/Clips/Devices',
      '## Missing Samples',
      '## Located Samples',
      '## Device/Track Cross-Reference',
      '## Track / Clip Cross Reference',
      '## Set Assets',
      '## Test Environment'
    ]
  end

  it 'writes the sizes and the checksums of the set under the metadata' do
    markdown = described_class.new(model).to_markdown

    expect(markdown.scan(/^### .*$/)).to include '### Set Sizes', '### Set Checksums'
  end

  it 'writes the state of the machine the report was made on at the bottom' do
    markdown = described_class.new(model).to_markdown

    expect(markdown).to include('### The Ableton Project Info Folder')
    expect(markdown).to include('### Referenced Packs')
    expect(markdown).to end_with "- **Drive and Glow**\n\n"
  end

  it 'writes the name of the set at the top of the report' do
    expect(described_class.new(model).to_markdown).to start_with(
      "# `Fascination.als`\n"
    )
  end

  it 'writes the facts about the set under the name of the set' do
    expect(described_class.new(model).to_markdown).to include(
      "|||\n|:-|-:|\n"
    )
  end

  it 'writes the tracks of the set under the legend, in the order Live wrote them' do
    markdown = described_class.new(model).to_markdown

    expect(markdown).to include('### Groups')
    expect(markdown).to include('### Tracks')
    expect(markdown).to include('- Group track 1  👥 Group  ')
    expect(markdown).to include('- Track 1  🎵 Audio  ')
  end

  it 'writes the audio tracks and the MIDI tracks in their own lists when they are to be
       shown separately' do
    markdown = described_class.new(model(separately: true)).to_markdown

    expect(markdown).to include('### Audio Tracks')
    expect(markdown).to include('### MIDI Tracks')
  end
end
