require_relative '../model/live_packs'
require_relative 'live_markup'

# Writes the packs of a set that are on the machine the report was made on, and the ones
# that are not.
#
# The packs are a fact of the machine: a pack is installed, or it is not. The packs the set
# refers to are written by the serializer of the packs of the set.
#
# Sample usage:
# markdown = LiveMachinePacksSerializer.new(packs).to_markdown
class LiveMachinePacksSerializer
  # What the report says when none of the packs of the set is on this machine.
  LOST_PACK_REFERENCES = 'None'.freeze

  # Creates a serializer for the packs of a set that are on this machine.
  #
  # @param packs [LivePacks] the packs of the set
  def initialize(packs)
    @packs = packs
  end

  # Returns the sections as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    (located_section + missing_section).join("\n")
  end

  private

  # The packs that are on this machine.
  #
  # @return [Array<String>] the lines of the section
  def located_section
    lines = ['### Installed Packs', '']
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
    lines = ['### Missing Packs', '']
    packs = @packs.missing
    if packs.empty?
      lines << (@packs.empty? ? LOST_PACK_REFERENCES : 'Every pack the set refers to is on this machine.')
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
