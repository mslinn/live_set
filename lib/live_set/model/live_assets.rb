require_relative 'live_asset'

# The external assets of a set: every file it refers to.
#
# Several references may name the same file, and each of them may play it differently. The
# size of a set counts each file once, and it is not the sum of the sizes of the references.
class LiveAssets
  include Enumerable

  attr_reader :assets

  # @param set_directory [String] the directory the set is in
  # @param xml_doc [Nokogiri::XML::Document] the set
  def initialize(set_directory, xml_doc)
    @assets = xml_doc.xpath('//FileRef')
                     .filter_map { |file_ref| LiveAsset.new file_ref, set_directory }
                     .reject(&:folder?)
                     .reject { |asset| asset.path.empty? }
                     .uniq(&:resolved_path)
  end

  # The assets that are in the project folder.
  #
  # @return [Array<LiveAsset>] the assets
  def in_project
    assets.select(&:in_project?)
  end

  # The assets that are outside the project folder.
  #
  # @return [Array<LiveAsset>] the assets
  def outside_project
    assets.reject(&:in_project?)
  end

  # The assets that are not on disk.
  #
  # @return [Array<LiveAsset>] the assets
  def missing
    assets.reject(&:there?)
  end

  # The assets that are samples.
  #
  # @return [Array<LiveAsset>] the assets
  def samples
    assets.select(&:sample?)
  end

  # The samples the set ships.
  #
  # A sample that the set refers to by a path within the project is one of them, even when it
  # came from a pack: the set has the file, and the file travels with the set. A sample that
  # comes from a pack or from the Core Library of Live, and that the set does not hold, is not
  # one of them: the pack holds it, and it travels with the pack.
  #
  # @return [Array<LiveAsset>] the assets
  def samples_of_the_set
    samples.reject { |asset| (asset.from_pack? || asset.from_core_library?) && !asset.in_project? }
  end

  # @yieldparam asset [LiveAsset] an asset
  # @return [Enumerator, LiveAssets] the assets
  def each(&)
    return enum_for(:each) unless block_given?

    assets.each(&)
    self
  end

  # @return [Integer] the number of assets
  def size
    assets.length
  end

  # @return [Boolean] true when the set refers to no files
  def empty?
    assets.empty?
  end
end
