require_relative 'live_group_serializer'

# Writes a collection of groups.
#
# The collection is never written by itself: each group is written by the serializer of a
# group, and the outputs are mapped together.
#
# Sample usage:
# markdown = LiveGroupsSerializer.new(groups).to_markdown
class LiveGroupsSerializer
  # Creates a serializer for a collection of groups.
  #
  # @param groups [LiveGroups] the groups of the collection
  # @param indent [String] the indentation of the lines of the collection
  def initialize(groups, indent = '')
    @groups = groups
    @indent = indent
  end

  # Returns the collection as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    @groups.each_with_index.map do |group, index|
      LiveGroupSerializer.new(group, (index + 1).to_s, @indent).to_markdown
    end.join("\n")
  end
end
