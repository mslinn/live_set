require_relative 'live_collection_serializer'
require_relative 'live_take_lane_serializer'

# Writes a collection of take lanes.
#
# The collection is never written by itself: each lane is written by the serializer of a
# lane, and the outputs are mapped together.
#
# The lanes of a track are under the track.
#
# Sample usage:
# markdown = LiveTakeLanesSerializer.new(take_lanes, number).to_markdown
class LiveTakeLanesSerializer < LiveCollectionSerializer
  # Creates a serializer for the given take lanes.
  #
  # @param take_lanes [LiveTakeLanes] the take lanes to be serialized
  # @param hierarchical_number [HierarchicalNumber] the number of the first lane
  def initialize(take_lanes, hierarchical_number)
    super()
    @take_lanes = take_lanes
    @hierarchical_number = hierarchical_number
  end

  private

  # The lanes of the collection, with the numbers they have in the report.
  #
  # @return [Array<Array>] the number and the lane
  def items
    @take_lanes.map do |lane|
      [@hierarchical_number.dup.increment(lane.index - 1), lane]
    end
  end

  # The serializer of a lane.
  #
  # @param number [HierarchicalNumber] the number of the lane
  # @param lane [LiveTakeLane] the lane
  # @return [LiveTakeLaneSerializer] the serializer
  def serializer_for(number, lane)
    LiveTakeLaneSerializer.new lane, number
  end
end
