require_relative '../model/live_packs'
require_relative 'live_markup'

# Writes the packs the set refers to.
#
# A pack is a folder of content that Ableton sells. A set that plays a file of a pack refers
# to the pack, and the pack has to be installed for the file to be found. A pack that is not
# installed is not a fault of the set.
#
# The packs the set refers to are a fact of the set: the XML names them. The packs that are
# installed are a fact of the machine, and they are written by the serializer of the machine.
#
# Sample usage:
# markdown = LivePacksSerializer.new(packs).to_markdown

class LivePacksSerializer
  # What the report says when the set refers to no pack.
  NO_PACK_REFERENCES = 'This set does not reference any packs.'.freeze

  # Creates a serializer for the packs of a set.
  #
  # @param packs [LivePacks] the packs of the set
  def initialize(packs)
    @packs = packs
  end

  # Returns the section as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = ['## Referenced Packs', '']
    if @packs.empty?
      lines << NO_PACK_REFERENCES
      return lines.join("\n")
    end

    @packs.each { |pack| lines << "- **#{pack.name}**: `#{path_of pack}`" }
    lines.join("\n")
  end

  private

  # The path of the folder of a pack, as the report breaks it.
  #
  # @param pack [LivePack] the pack
  # @return [String] the path
  def path_of(pack)
    LiveMarkup.escape(pack.path.to_s).gsub('/', '/<wbr/>')
  end
end
