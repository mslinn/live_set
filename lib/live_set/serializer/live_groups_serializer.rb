require_relative '../model/hierarchical_number'
require_relative 'live_collection_serializer'
require_relative 'live_group_serializer'

# Writes a collection of groups.
#
# The collection is never written by itself: each group is written by the serializer of a
# group, and the outputs are mapped together.
#
# Sample usage:
# markdown = LiveGroupsSerializer.new(groups).to_markdown
class LiveGroupsSerializer < LiveCollectionSerializer
  # The prefix of the numbers of the groups.
  PREFIX = 'G'.freeze

  # Creates a serializer for a collection of groups.
  #
  # @param groups [LiveGroups] the groups of the collection
  def initialize(groups)
    super()
    @groups = groups
  end

  # The groups of the collection, with the numbers they have in the report.
  #
  # @return [Array<Array>] the number and the group
  def numbered_groups
    @numbered_groups ||= begin
      number = HierarchicalNumber.new PREFIX
      @groups.map do |group|
        [number.dup, group].tap { number.increment }
      end
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

  private

  # The groups of the collection, with the numbers they have in the report.
  #
  # @return [Array<Array>] the number and the group
  def items
    numbered_groups
  end

  # The serializer of a group.
  #
  # @param number [HierarchicalNumber] the number of the group
  # @param group [LiveGroup] the group
  # @return [LiveGroupSerializer] the serializer
  def serializer_for(number, group)
    LiveGroupSerializer.new group, number
  end
end
