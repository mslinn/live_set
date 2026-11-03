# TODO: This is a placeholder to start off the changes described as TODO comments in lib/live_set/live_palette.rb.
# TODO Write unit tests
#
# Serializes a `LiveTakeLane` model as markdown.
#
# Sample usage:
# take_lane = LiveTakeLane.new(...)
# markdown = LiveTakeLaneSerializer.new(take_lane).to_markdown
class LiveTakeLaneSerializer
  # Creates a serializer for the given take lane.
  #
  # @param take_lane [LiveTakeLane] the take lane to be serialized
  def initialize(take_lane, hierarchical_number)
    @take_lane = take_lane
    @hierarchical_number = hierarchical_number
  end

  # Returns the take_lane as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    # TODO: write me
  end
end
