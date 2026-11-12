require_relative 'hierarchical_number'

# A thing of the outline, and the things under it.
#
# The outline of a set is a tree: a group has devices and member tracks, a track has
# devices, clips and take lanes, a clip has the copies of it, and a take lane has clips.
#
# An item holds what is presented: the number of the thing in the report, the text of it,
# and the things under it.
class LiveOutlineItem
  attr_reader :children, :number, :value

  # @param number [HierarchicalNumber] the number of the thing in the report
  # @param value [String] the text of the thing
  # @param children [Array<LiveOutlineItem>] the things under it
  def initialize(number, value, children = [])
    @number = number
    @value = value
    @children = children
  end

  # Whether the thing has things under it.
  #
  # @return [Boolean] true when the thing is a list
  def list?
    !@children.empty?
  end

  # The indentation of the thing in the report.
  #
  # @param indent [String] the indentation of one level
  # @return [String] the indentation
  def indent_for(indent)
    @number.indent_for indent
  end
end
