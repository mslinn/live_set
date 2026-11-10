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
  def initialize(groups)
    @groups = groups
  end

  # Returns the collection as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    numbered_groups.map do |number, group|
      LiveGroupSerializer.new(group, number).to_markdown
    end.join("\n")
  end

  # The groups of the collection, with the numbers they have in the report.
  #
  # @return [Array<Array>] the number and the group
  def numbered_groups
    @groups.each_with_index.map do |group, index|
      [(index + 1).to_s, group]
    end
  end

  # The tracks in the groups, with the numbers they have in the report.
  #
  # The numbers of the members of a group follow the number of the group, and they are the
  # numbers the outline gives them.
  #
  # @return [Array<Array>] the number and the track
  def numbered_members
    numbered_groups.flat_map do |number, group|
      LiveGroupSerializer.new(group, number).numbered_members
    end
  end
end
