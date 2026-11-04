require_relative 'live_group'

# The groups of a set.
#
# A group is a track that holds other tracks. The groups of the set are the groups that are
# at the top of it.
class LiveGroups
  include Enumerable

  attr_reader :groups

  # @param groups [Array<LiveGroup>] the groups
  def initialize(groups)
    @groups = groups
  end

  # @yieldparam group [LiveGroup] a group
  # @return [Enumerator, LiveGroups] the groups
  def each(&)
    return enum_for(:each) unless block_given?

    groups.each(&)
    self
  end

  # @return [Integer] the number of groups
  def size
    groups.length
  end
end
