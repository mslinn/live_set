require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require 'live_set/model/live_packs'
require 'live_set/model/live_sample'
require 'live_set/model/live_samples'
require 'live_set/model/live_tracks'
require 'live_set/serializer/live_packs_serializer'
require 'support/live_sets'

# The packs the set refers to.
#
# The expected values are the packs of the Live 11 reference set, which is checked in.
RSpec.describe LivePacksSerializer, '#to_markdown' do
  # The packs of the set.
  #
  # @return [LivePacks] the packs
  def packs
    @packs ||= begin
      elements = LiveSets.nodes(LiveSets.fascination, '//MidiTrack | //AudioTrack | //GroupTrack')
      tracks = LiveTracks.new LiveSets.directory(LiveSets.fascination), elements
      samples = LiveSamples.new tracks.audio_clips, LiveSets.directory(LiveSets.fascination)
      LivePacks.new samples.samples
    end
  end

  it 'writes the heading of the section' do
    expect(described_class.new(packs).to_markdown).to start_with "## Referenced Packs\n"
  end

  it 'names the pack that the set refers to' do
    expect(described_class.new(packs).to_markdown).to include('- **Drive and Glow**')
  end

  it 'says that This set does not reference any packs' do
    markdown = described_class.new(LivePacks.new([])).to_markdown

    expect(markdown).to include(described_class::NO_PACK_REFERENCES)
  end

  it 'names the pack, and where it is' do
    Dir.mktmpdir 'live_set_spec_' do |directory|
      pack = File.join directory, 'Drive and Glow'
      FileUtils.mkdir_p File.join(pack, 'Samples')
      sample = LiveSample.new File.join(pack, 'Samples', 'Tambourine.aif')

      markdown = described_class.new(LivePacks.new([sample])).to_markdown

      expect(markdown).to include("- **Drive and Glow**: `#{pack.gsub('/', '/<wbr/>')}`")
    end
  end
end
