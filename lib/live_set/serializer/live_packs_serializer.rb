require_relative '../model/live_packs'
require_relative 'live_markup'

# Writes the packs the set refers to.
#
# A pack is a folder of content that Ableton sells. A set that plays a file of a pack refers
# to the pack, and the pack has to be installed for the file to be found. A pack that is not
# installed is not a fault of the set.
#
# Sample usage:
# markdown = LivePacksSerializer.new(packs).to_markdown

LOST_PACK_REFERENCES = 'None'.freeze
NO_PACK_REFERENCES   = 'This set does not reference any packs.'.freeze

class LivePacksSerializer
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
    lines = ['### Referenced Packs', '']
    if @packs.empty?
      lines << NO_PACK_REFERENCES
      return lines.join("\n")
    end

    lines.concat located_section
    lines.concat missing_section
    lines.join("\n")
  end

  private

  # The packs that are on this machine.
  #
  # @return [Array<String>] the lines of the section
  def located_section
    lines = ['#### Located Packs', '']
    packs = @packs.located
    if packs.empty?
      lines << LOST_PACK_REFERENCES
    else
      packs.each { |pack| lines << "- **#{pack.name}**: `#{path_of pack}`" }
    end
    lines << ''
    lines
  end

  # The packs that are not on this machine.
  #
  # @return [Array<String>] the lines of the section
  def missing_section
    lines = ['#### Missing Packs', '']
    packs = @packs.missing
    if packs.empty?
      lines << 'Every pack the set refers to is on this machine.'
    else
      packs.each { |pack| lines << "- **#{pack.name}**" }
    end
    lines << ''
    lines
  end

  # The path of the folder of a pack, as the report breaks it.
  #
  # @param pack [LivePack] the pack
  # @return [String] the path
  def path_of(pack)
    LiveMarkup.escape(pack.path.to_s).gsub('/', '/<wbr/>')
  end
end
