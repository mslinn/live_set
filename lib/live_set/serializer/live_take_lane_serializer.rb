require_relative 'live_clip_groups'

# Serializes a `LiveTakeLane` model as markdown.
#
# A lane holds the takes of a recording, and the track holds the clips that are heard. The
# lanes are subordinate to the track.
#
# Sample usage:
# take_lane = LiveTakeLane.new(...)
# markdown = LiveTakeLaneSerializer.new(take_lane, '1.1.1').to_markdown
class LiveTakeLaneSerializer
  # Creates a serializer for the given take lane.
  #
  # @param take_lane [LiveTakeLane] the take lane to be serialized
  # @param hierarchical_number [String] the number of the lane in the report
  def initialize(take_lane, hierarchical_number, indent = '')
    @take_lane = take_lane
    @hierarchical_number = hierarchical_number
    @indent = indent
  end

  # Returns the take lane as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = ["#{@indent}- Take lane #{@hierarchical_number}  #{@take_lane.name}"]
    lines += LiveClipGroups.new(@take_lane.clips).to_markdown(@hierarchical_number)
                           .map { |line| "#{@indent}  #{line}" }
    lines.join "\n"
  end
end
