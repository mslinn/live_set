require 'bytesize'
require 'markdown-tables'
require_relative '../model/live_assets'

# Writes the assets of a set: every file it refers to.
#
# The table says what the sizes of the set are made of: each file, the path as the set writes
# it, how the path was resolved, the size Live recorded for it, the size on disk, where it is,
# and when it was last changed. The reader can add the columns up.
#
# Sample usage:
# markdown = LiveAssetsSerializer.new(assets).to_markdown
class LiveAssetsSerializer
  # Creates a serializer for the assets of a set.
  #
  # @param assets [LiveAssets] the assets of the set
  def initialize(assets)
    @assets = assets
  end

  # Returns the section as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = ['## The Assets of the Set', '']
    if @assets.empty?
      lines << 'The set refers to no files.'
      return lines.join("\n")
    end

    rows = @assets.map do |asset|
      [path_cell(asset.path), path_cell(asset.resolved_path), location_of(asset),
       size_of(asset.recorded_size), size_on_disk_of(asset), changed_of(asset)]
    end

    lines << MarkdownTables.make_table(
      ['The path', 'How it was resolved', 'Where it is', 'The size Live recorded',
       'The size on disk', 'Last changed'],
      rows, align: %w[l l l r r l], is_rows: true
    )
    lines.join("\n")
  end

  private

  # A path, as a cell that can be broken where it has to be.
  #
  # @param path [String] the path
  # @return [String] the cell
  def path_cell(path)
    "<code>#{path.gsub('/', '/<wbr/>')}</code>"
  end

  # Where an asset is.
  #
  # @param asset [LiveAsset] the asset
  # @return [String] the place
  def location_of(asset)
    return 'not there' unless asset.there?

    LiveAsset::LOCATIONS.fetch asset.location
  end

  # A size, as the report writes it.
  #
  # @param size [Integer] the size in bytes
  # @return [String] the size
  def size_of(size)
    return 'not recorded' if size.zero?

    "#{size} (#{ByteSize.new size})"
  end

  # The size of a file on disk.
  #
  # @param asset [LiveAsset] the asset
  # @return [String] the size
  def size_on_disk_of(asset)
    size = asset.size_on_disk
    return 'not there' if size.nil?

    "#{size} (#{ByteSize.new size})"
  end

  # When a file was last changed.
  #
  # @param asset [LiveAsset] the asset
  # @return [String] the time
  def changed_of(asset)
    time = asset.last_modified_on_disk || asset.last_modified
    return 'not known' if time.nil?

    time.strftime '%Y-%m-%d %H:%M:%S'
  end
end
