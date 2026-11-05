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
