# TODO: This is a placeholder to start off the changes described as TODO comments in lib/live_set/live_palette.rb.
# TODO Write unit tests
#
# Serializes a `LiveTakeLanes` model as markdown.
#
# Sample usage:
# take_lanes = LiveTakeLanes.new(...)
# markdown = LiveTakeLanesSerializer.new(take_lanes).to_markdown
class LiveTakeLanesSerializer
  # Creates a serializer for the given take lanes.
  #
  # @param take_lanes [LiveTakeLanes] the take lanes to be serialized
  def initialize(take_lanes, hierarchical_number)
    @take_lanes = take_lanes
    @hierarchical_number = hierarchical_number
  end

  # Returns the take_lanes as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    @take_lanes.map(&:to_markdown).join("\n")
  end
end
