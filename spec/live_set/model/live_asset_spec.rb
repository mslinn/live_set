require 'spec_helper'
require 'live_set/model/live_asset'
require 'support/live_sets'

# An external asset of a set: a file the set refers to.
#
# The assets are the ones of the Live 11 reference set, which is checked in.
RSpec.describe LiveAsset do
  # The assets of the set, with the directory the set is in.
  #
  # @return [Array<LiveAsset>] the assets
  def assets
    @assets ||= begin
      document = LiveSets.document LiveSets.fascination
      document.xpath('//FileRef').map do |file_ref|
        described_class.new file_ref, LiveSets.directory(LiveSets.fascination)
      end
    end
  end

  # The asset with the given relative path.
  #
  # @param path [String] the relative path of the asset
  # @return [LiveAsset] the asset
  def asset_with(path)
    assets.find { |asset| asset.relative_path == path }
  end

  # An asset that the set names by its absolute path alone.
  #
  # @param path [String] the absolute path of the asset
  # @return [LiveAsset] the asset
  def asset_with_absolute_path(path)
    file_ref = Nokogiri::XML::Node.new('FileRef', Nokogiri::XML::Document.new)
    file_ref.add_child '<Path Value="'
    file_ref.at('Path')['Value'] = path
    described_class.new file_ref, LiveSets.directory(LiveSets.fascination)
  end

  it 'holds the path the set writes' do
    asset = asset_with 'Samples/Pink Noise - EDMtips.com.wav'

    expect(asset.path).to eq 'Samples/Pink Noise - EDMtips.com.wav'
    expect(asset.absolute_path).to eq '/Users/owen/Music/Ableton/User Library/Samples/Pink Noise - EDMtips.com.wav'
  end

  it 'resolves a relative path against the directory of the set' do
    asset = asset_with 'Samples/Pink Noise - EDMtips.com.wav'

    expect(asset.resolved_path).to eq(
      File.join(LiveSets.directory(LiveSets.fascination), 'Samples/Pink Noise - EDMtips.com.wav')
    )
  end

  it 'resolves a path with .. in it against the directory of the set' do
    asset = assets.find { |candidate| candidate.relative_path.start_with? '..' }

    expect(asset.resolved_path).to eq(
      File.expand_path(File.join(LiveSets.directory(LiveSets.fascination), asset.relative_path))
    )
  end

  it 'holds the size Live recorded for the file' do
    asset = asset_with 'Samples/Pink Noise - EDMtips.com.wav'

    expect(asset.recorded_size).to eq 4_130_387
  end

  it 'says that an asset with a relative path is in the project' do
    expect(asset_with('Samples/Pink Noise - EDMtips.com.wav')).to be_in_project
  end

  it 'says that an asset with a path outside the project is outside it' do
    asset = assets.find { |candidate| candidate.relative_path.start_with? '..' }

    expect(asset).not_to be_in_project
    expect(asset.location).to eq :outside
  end

  it 'says that an asset with only an absolute path in the user library is in the user library' do
    asset = asset_with_absolute_path '/Users/owen/Music/Ableton/User Library/Samples/loop.wav'

    expect(asset.location).to eq :user_library
  end

  it 'says that an asset with only an absolute path in the Core Library is in the Core Library' do
    asset = asset_with_absolute_path '/Applications/Ableton Live 11 Suite.app/Core Library/loop.wav'

    expect(asset.location).to eq :core_library
  end

  it 'says that a file that is not on disk is not there' do
    asset = asset_with 'Samples/Pink Noise - EDMtips.com.wav'

    expect(asset).not_to be_there
    expect(asset.size_on_disk).to be_nil
  end
end
