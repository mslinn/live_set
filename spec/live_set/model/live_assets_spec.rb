require 'spec_helper'
require 'live_set/model/live_assets'
require 'support/live_sets'

# The external assets of a set.
#
# The assets are the ones of the Live 11 reference set, which is checked in.
RSpec.describe LiveAssets do
  # The assets of the set.
  #
  # @return [LiveAssets] the assets
  def assets
    @assets ||= described_class.new LiveSets.directory(LiveSets.fascination),
                                    LiveSets.document(LiveSets.fascination)
  end

  it 'holds every file the set refers to, each one once' do
    expect(assets.size).to eq assets.assets.map(&:resolved_path).uniq.length
  end

  it 'holds the samples that are in the project' do
    expect(assets.in_project.map(&:relative_path)).to include 'Samples/Pink Noise - EDMtips.com.wav'
  end

  it 'holds the assets that are outside the project' do
    expect(assets.outside_project.map(&:relative_path)).to include(
      a_string_starting_with('..')
    )
  end

  it 'holds the assets that are not on disk' do
    expect(assets.missing).not_to be_empty
  end
end
