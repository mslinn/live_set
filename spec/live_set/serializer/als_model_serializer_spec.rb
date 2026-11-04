require 'spec_helper'
require 'live_set/model/als_model'
require 'live_set/serializer/als_model_serializer'
require 'support/live_sets'

# The report of a set, as a whole.
#
# The expected value is the report of the set as it is written now:
#
#   sets/live_11/reports/Fascination.md
#
# The report is a document, so what is expected of it is the order of its sections: the
# header block, the verdict for a transfer to Push 3 Standalone, the hierarchy of the groups,
# the tracks, the clips and the devices, the samples that are not in the project, and the two
# cross-references.
RSpec.describe AlsModelSerializer, '#to_markdown' do
  # The model of the set.
  #
  # @return [AlsModel] the model
  def model
    path = LiveSets.fascination
    AlsModel.new path, LiveSets.document(path), Time.now, Time.now
  end

  it 'writes the sections of the report, in order' do
    markdown = described_class.new(model).to_markdown

    expect(markdown.scan(/^## .*$/)).to eq [
      '## Push 3 Standalone',
      '## Groups/Tracks/Clips/Devices',
      '## Missing Samples',
      '## Samples',
      '## Device/Track Cross-Reference',
      '## Track / Clip Cross Reference'
    ]
  end

  it 'writes the facts about the set at the top of the report' do
    expect(described_class.new(model).to_markdown).to start_with(
      "|||\n|:-|-:|\n"
    )
  end

  it 'writes the tracks of the set under the legend' do
    markdown = described_class.new(model).to_markdown

    expect(markdown).to include('- Track 1  🎵 Audio  ')
    expect(markdown).to include('- Group track 1  👥 Group  ')
  end
end
