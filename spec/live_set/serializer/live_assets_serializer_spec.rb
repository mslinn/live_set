require 'spec_helper'
require 'live_set/model/live_assets'
require 'live_set/serializer/live_assets_serializer'
require 'support/live_sets'

# The assets of a set.
#
# The expected values are the assets of the Live 11 reference set, which is checked in.
RSpec.describe LiveAssetsSerializer, '#to_markdown' do
  # The assets of the set.
  #
  # @return [LiveAssets] the assets
  def assets
    @assets ||= LiveAssets.new LiveSets.directory(LiveSets.fascination),
                               LiveSets.document(LiveSets.fascination)
  end

  it 'writes the heading of the section' do
    expect(described_class.new(assets).to_markdown).to start_with "## The Assets of the Set\n"
  end

  it 'writes the columns of the table' do
    markdown = described_class.new(assets).to_markdown

    expect(markdown).to include(
      '|The path|How it was resolved|Where it is|The size Live recorded|The size on disk|Last changed|'
    )
  end

  it 'writes a row for each asset' do
    markdown = described_class.new(assets).to_markdown
    samples = assets.in_project.count { |asset| asset.relative_path.start_with? 'Samples' }

    expect(markdown.scan('<code>Samples').length).to eq samples
  end

  it 'writes the size Live recorded for a file' do
    markdown = described_class.new(assets).to_markdown

    expect(markdown).to include('4130387 (4.13 MB)')
  end

  it 'says that a file that is not on disk is not there' do
    markdown = described_class.new(assets).to_markdown

    expect(markdown).to include('not there')
  end
end
