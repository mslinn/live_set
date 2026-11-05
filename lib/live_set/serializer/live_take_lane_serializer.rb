require_relative 'live_markup'
require_relative 'live_midi_clip_groups'

# Serializes a `LiveTakeLane` model as markdown.
#
# A lane holds the takes of a recording, and the track holds the clips that are heard. The
# lanes are subordinate to the track.
#
# The indentation of the lane comes from its number, so that the number of a lane and the
# place of it in the outline always agree.
#
# Sample usage:
# take_lane = LiveTakeLane.new(...)
# markdown = LiveTakeLaneSerializer.new(take_lane, '1.1.1').to_markdown
class LiveTakeLaneSerializer
  # Creates a serializer for the given take lane.
  #
  # @param take_lane [LiveTakeLane] the take lane to be serialized
  # @param hierarchical_number [String] the number of the lane in the report
  def initialize(take_lane, hierarchical_number)
    @take_lane = take_lane
    @hierarchical_number = hierarchical_number
  end

  # Returns the take lane as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = ["#{LiveMarkup.indent_for(@hierarchical_number)}- Take lane #{@hierarchical_number}  " \
             "#{@take_lane.name}"]
    lines + LiveMidiClipGroups.new(@take_lane.clips).to_markdown(@hierarchical_number)
  end
end
