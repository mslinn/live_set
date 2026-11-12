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
    expect(described_class.new(assets).to_markdown).to start_with "## Set Assets\n"
  end

  it 'writes the samples of the set as a numbered list' do
    markdown = described_class.new(assets).to_markdown

    expect(markdown).to include('1. <code>Samples/<wbr/>Pink Noise - EDMtips.com.wav</code>')
    expect(markdown).to include('3. <code>../<wbr/>../<wbr/>../<wbr/>Plugins/')
  end

  it 'writes no device, and no preset of one' do
    markdown = described_class.new(assets).to_markdown

    expect(markdown).not_to include 'Devices/'
    expect(markdown).not_to include 'Presets/'
  end

  it 'writes the size Live recorded for a file' do
    markdown = described_class.new(assets).to_markdown

    expect(markdown).to include('(4.13 MB)')
  end

  it 'says that a file that is not in the project is not compatible with the P3S' do
    markdown = described_class.new(assets).to_markdown

    expect(markdown).to include('❌ not P3S compatible')
  end

  it 'says that a file that is not in the project is missing when the machine is asked for' do
    markdown = described_class.new(assets, machine: true).to_markdown

    expect(markdown).to include('❌ missing')
  end

  it 'writes the marker of a file with the decoration of a warning' do
    markdown = described_class.new(assets, machine: true).to_markdown

    # The decoration is the one of the warning of a clip, and it is made in one place.
    expect(markdown).to include(
      '<code style="background-color: #8B0000; color: #FFFFFF; vertical-align:middle;">❌ missing</code>'
    )
  end

  it 'writes no date for a file that is not on disk' do
    markdown = described_class.new(assets).to_markdown

    expect(markdown).not_to match(/\d{4}-\d{2}-\d{2}/)
  end
end
