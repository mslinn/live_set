require 'spec_helper'
require 'live_set/model/live_assets'
require 'live_set/model/live_sizes'
require 'support/live_sets'

# The sizes of a set.
#
# The sizes are the ones of the Live 11 reference set, which is checked in.
RSpec.describe LiveSizes do
  # The assets of the set.
  #
  # @return [LiveAssets] the assets
  def assets
    @assets ||= LiveAssets.new LiveSets.directory(LiveSets.fascination),
                               LiveSets.document(LiveSets.fascination)
  end

  # The sizes of the set.
  #
  # @return [LiveSizes] the sizes
  def sizes
    @sizes ||= described_class.new LiveSets.fascination, assets
  end

  it 'is the size of the set file on disk' do
    expect(sizes.set_file_size).to eq File.size(LiveSets.fascination)
  end

  it 'expects the project to be the set file and the samples in it' do
    expected = sizes.set_file_size + assets.in_project.sum(&:expected_size)

    expect(sizes.expected_project_size).to eq expected
  end

  it 'is the size of the files in the project folder' do
    directory = LiveSets.directory(LiveSets.fascination)
    actual = Dir.glob(File.join(directory, '**', '*')).sum { |path| File.file?(path) ? File.size(path) : 0 }

    expect(sizes.actual_project_size).to eq actual
  end

  it 'resolves the size to the expected size and the assets outside the project' do
    outside = assets.outside_project.sum { |asset| asset.size_on_disk.to_i }

    expect(sizes.resolved_size).to eq sizes.expected_project_size + outside
  end

  it 'has no actual size when the project folder is not there' do
    sizes = described_class.new LiveSets.fascination, assets

    expect(sizes.actual_project_size).not_to be_nil
  end
end
