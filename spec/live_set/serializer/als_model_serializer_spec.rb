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
# header block, the metadata of the set, the verdict for a transfer to P3S Standalone, the
# hierarchy of the groups, the tracks, the clips and the devices, the samples that are not in
# the project, the two cross-references, the assets of the set, and the state of the machine
# the report was made on.
RSpec.describe AlsModelSerializer, '#to_markdown' do
  # The model of the set.
  #
  # @param separately [Boolean] whether the audio tracks and the MIDI tracks are written in
  #   their own lists
  # @param machine [Boolean] whether the facts of the machine are written
  # @return [AlsModel] the model
  def model(separately: false, machine: false)
    path = LiveSets.fascination
    document = LiveSets.document path
    header = HeaderBlock.new path, document, nil
    context = ReportContext.new machine: machine
    separate = separately
    AlsModel.new path, document, header, context: context, show_midi_and_audio_tracks_separately: separate
  end

  it 'writes the sections of the report, in order' do
    markdown = described_class.new(model).to_markdown

    expect(markdown.scan(/^## .*$/)).to eq [
      '## Metadata',
      '## P3S Standalone',
      '## Groups/Tracks/Clips/Devices',
      '## Missing Samples',
      '## Located Samples',
      '## Device/Track Cross-Reference',
      '## Track / Clip Cross Reference',
      '## Set Assets',
      '## Referenced Packs'
    ]
  end

  it 'writes the sizes and the checksums of the set under the metadata' do
    markdown = described_class.new(model).to_markdown

    expect(markdown.scan(/^### .*$/)).to include '### Set Sizes', '### Set Checksums'
  end

  it 'does not write the state of the machine when it is not asked for' do
    markdown = described_class.new(model).to_markdown

    expect(markdown).not_to include('## Test Environment')
  end

  it 'writes the state of the machine the report was made on at the bottom' do
    markdown = described_class.new(model(machine: true)).to_markdown

    expect(markdown).to include('### The Ableton Project Info Folder')
    expect(markdown).to include('### Installed Packs')
    expect(markdown).to include('### Missing Packs')
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

  it 'writes the tracks of the set under the legend, in the order they appear in the file' do
    markdown = described_class.new(model).to_markdown

    expect(markdown).to include('### Groups')
    expect(markdown).to include('### Tracks')
    expect(markdown).to include('<summary>Group track G1  👥 Group  ')
    expect(markdown).to include('<summary>Track T1  🎵 Audio  ')
  end

  it 'writes the outline of the set as a list that can be folded' do
    markdown = described_class.new(model).to_markdown

    expect(markdown).to include('<ul style="list-style: none;">')
    expect(markdown).to include('<details open>')
  end

  it 'writes a blank line before and after the outline, so that a markdown processor does
       not take the indented lines for a code block' do
    markdown = described_class.new(model).to_markdown

    expect(markdown).to include("\n\n<ul style=\"list-style: none;\">\n")
    expect(markdown).to include("</ul>\n\n")
  end

  it 'writes the audio tracks and the MIDI tracks in their own lists when they are to be
       shown separately' do
    markdown = described_class.new(model(separately: true)).to_markdown

    # The set has no MIDI track at the top of it, so there is no section of MIDI tracks.
    expect(markdown).to include('### Audio Tracks')
    expect(markdown).not_to include('### Ungrouped Tracks')
  end
end
