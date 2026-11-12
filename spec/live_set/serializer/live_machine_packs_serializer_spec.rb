require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require 'live_set/model/live_packs'
require 'live_set/model/live_sample'
require 'live_set/serializer/live_machine_packs_serializer'

# The packs of a set that are on the machine the report was made on.
RSpec.describe LiveMachinePacksSerializer, '#to_markdown' do
  it 'writes the two subsections' do
    markdown = described_class.new(LivePacks.new([])).to_markdown

    expect(markdown).to include('### Installed Packs')
    expect(markdown).to include('### Missing Packs')
  end

  it 'says that every pack the set refers to is on this machine' do
    Dir.mktmpdir 'live_set_spec_' do |directory|
      pack = File.join directory, 'Drive and Glow'
      FileUtils.mkdir_p File.join(pack, 'Samples')
      sample = LiveSample.new File.join(pack, 'Samples', 'Tambourine.aif')

      markdown = described_class.new(LivePacks.new([sample])).to_markdown

      expect(markdown).to include('Every pack the set refers to is on this machine.')
    end
  end

  it 'names the pack that is on this machine, and where it is' do
    Dir.mktmpdir 'live_set_spec_' do |directory|
      pack = File.join directory, 'Drive and Glow'
      FileUtils.mkdir_p File.join(pack, 'Samples')
      sample = LiveSample.new File.join(pack, 'Samples', 'Tambourine.aif')

      markdown = described_class.new(LivePacks.new([sample])).to_markdown

      expect(markdown).to include("- **Drive and Glow**: `#{pack.gsub('/', '/<wbr/>')}`")
    end
  end

  it 'names the pack that is not on this machine' do
    Dir.mktmpdir 'live_set_spec_' do |directory|
      sample = LiveSample.new File.join(directory, 'Tenchu 2', 'Sounds', 'Erhu.aif')

      markdown = described_class.new(LivePacks.new([sample])).to_markdown

      expect(markdown).to include('- **Tenchu 2**')
    end
  end
end
