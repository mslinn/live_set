require 'spec_helper'
require 'live_set/model/als_model'
require 'live_set/model/header_block'
require 'live_set/serializer/p3s_compatibility'
require 'support/live_sets'

# The verdict for a transfer of a set to P3S Standalone.
#
# The expected value is the section of the report of the set as it is written now:
#
#   sets/live_11/experiments/reports/Fascination.md
#
# The section is a document, so the whole of it is expected, in a heredoc, and it can be
# read.
RSpec.describe P3SCompatibility, '#to_markdown' do
  # The set, as the model of it.
  #
  # @param path [String] the path of the set
  # @return [AlsModel] the set
  def set(path)
    document = LiveSets.document path
    header = HeaderBlock.new path, document
    AlsModel.new path, document, header
  end

  # A set, as the model of it, with the size Live recorded for every sample of it changed.
  #
  # The size of the project of a set is the size of the set file and the sizes Live recorded
  # for the samples that are in the project, so a set of more than 2 GB is made by changing
  # those sizes.
  #
  # @param path [String] the path of the set
  # @param size [Integer] the size in bytes
  # @return [AlsModel] the set
  def set_with_sample_size(path, size)
    document = Nokogiri::Slop LiveSets.document(path).to_xml
    document.xpath('//OriginalFileSize | //FileSize').each { |element| element['Value'] = size.to_s }
    header = HeaderBlock.new path, document
    AlsModel.new path, document, header
  end

  it 'says that a set that cannot be transferred is not ready, and what stops it' do
    expect(described_class.new(set(LiveSets.fascination)).to_markdown).to eq(<<~END_MARKDOWN.chomp)
      ## P3S Standalone

      ❌ Warning: This set should not be transferred to P3S Standalone.

      ### Reasons Why

      - [2 clips have not been collected.](#missing-samples)
      - Track <code style="color: #FFFFFF; background-color: #212121; vertical-align: middle;">Kontakt 7</code> is not frozen and uses device Kontakt 7, which P3S Standalone cannot run. Freeze or render this track.

      ### What Could Not Be Checked

      - The set refers to the pack 'Drive and Glow'. The pack has to be installed on the P3S Standalone for the content of it to play, and there is no way to check what is installed on it.

      ### Advice

      - Track <nobr><code style="color: #000000; background-color: #FFA428; vertical-align: middle;" title="Live color #1">A-Fresh Room &#124; EQ Eight</code></nobr> uses Max for Live device Dry/Wet, which the P3S Standalone runs with less headroom. A return track cannot be frozen, so remove the device from its chain, or bounce it.
      - Group '2 Drums' uses Max for Live device Filter, which the P3S Standalone runs with less headroom. A group cannot be frozen, so bounce the group if it overloads.
      - Group '5 Main' uses Max for Live device Filter, which the P3S Standalone runs with less headroom. A group cannot be frozen, so bounce the group if it overloads.
    END_MARKDOWN
  end

  # A set that refers to a pack, and that has nothing else against it.
  #
  # The plug-in of the set is removed, and every sample of the set is marked as collected,
  # so that the set refers to a pack and has no clip that has not been collected.
  #
  # @return [AlsModel] the set
  def set_with_a_pack
    document = Nokogiri::Slop LiveSets.document(LiveSets.fascination).to_xml
    document.xpath('//PluginDevice').each(&:remove)
    document.xpath('//FileRef/RelativePath').each do |relative_path|
      relative_path['Value'] = "Samples/Imported/#{File.basename relative_path['Value']}"
    end
    header = HeaderBlock.new LiveSets.fascination, document
    AlsModel.new LiveSets.fascination, document, header
  end

  context 'when the set refers to a pack' do
    it 'says that the set is probably ready, because the P3S Standalone cannot be probed' do
      markdown = described_class.new(set_with_a_pack).to_markdown

      expect(markdown).to include('⚠️ This set is probably ready for transfer to P3S Standalone.')
      expect(markdown).to include(
        "The set refers to the pack 'Drive and Glow'. The pack has to be installed on the P3S " \
        'Standalone for the content of it to play, and there is no way to check what is ' \
        'installed on it.'
      )
    end
  end

  context 'when an old version of Live wrote the set' do
    it 'says that the P3S Standalone cannot load it' do
      markdown = described_class.new(set(LiveSets.live_9_demo)).to_markdown

      expect(markdown).to include(
        'This set was written by Live 9.5, and the oldest version of Live the P3S Standalone ' \
        'can load a set of is Live 11.3.'
      )
    end
  end

  context 'when the set is of more than 2 GB' do
    it 'says that the P3S Standalone cannot load it' do
      markdown = described_class.new(set_with_sample_size(LiveSets.fascination, 3 * (1024**3))).to_markdown

      expect(markdown).to match(
        /The project of this set is \d+\.\d+ GB, and the P3S Standalone cannot load a set of more than 2 GB\./
      )
    end
  end

  context 'when the set has no clip in the session view' do
    it 'says that the P3S Standalone has nothing to play' do
      markdown = described_class.new(set(LiveSets.factory_default11)).to_markdown

      expect(markdown).to include(
        'This set has no clip in the session view, so the P3S Standalone has nothing to play.'
      )
    end
  end
end
