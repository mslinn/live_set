require_relative 'live_take_lane_serializer'

# Serializes a `LiveTakeLanes` model as markdown.
#
# The lanes of a track are under the track.
#
# Sample usage:
# take_lanes = LiveTakeLanes.new(...)
# markdown = LiveTakeLanesSerializer.new(take_lanes, '1.1').to_markdown
class LiveTakeLanesSerializer
  # Creates a serializer for the given take lanes.
  #
  # @param take_lanes [LiveTakeLanes] the take lanes to be serialized
  # @param hierarchical_number [String] the number of the track the lanes are on
  def initialize(take_lanes, hierarchical_number, indent = '')
    @take_lanes = take_lanes
    @hierarchical_number = hierarchical_number
    @indent = indent
  end

  # Returns the take lanes as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    @take_lanes.map do |lane|
      number = "#{@hierarchical_number}.#{lane.index}"
      LiveTakeLaneSerializer.new(lane, number, @indent).to_markdown
    end.join("\n")
  end
end
