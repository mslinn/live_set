require_relative 'hierarchical_number_serializer'
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
# markdown = LiveTakeLaneSerializer.new(take_lane, number).to_markdown
class LiveTakeLaneSerializer
  # Creates a serializer for the given take lane.
  #
  # @param take_lane [LiveTakeLane] the take lane to be serialized
  # @param hierarchical_number [HierarchicalNumber] the number of the lane in the report
  def initialize(take_lane, hierarchical_number)
    @take_lane = take_lane
    @hierarchical_number = hierarchical_number
  end

  # Returns the take lane as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    item.to_markdown markdown_children
  end

  # Returns the take lane as HTML.
  #
  # @return [String] the serialized HTML
  def to_html
    item.to_html html_children
  end

  # The text of the take lane: its number and its name.
  #
  # @return [String] the text
  def text
    "Take lane #{@hierarchical_number}  #{@take_lane.name}"
  end

  private

  # The item of the take lane: its number and its name.
  #
  # @return [HierarchicalNumberSerializer] the item
  def item
    @item ||= HierarchicalNumberSerializer.new @hierarchical_number, text
  end

  # The nodes under the take lane, as markdown.
  #
  # @return [Array<String>] the nodes under the lane
  def markdown_children
    [clips.to_markdown].reject(&:empty?)
  end

  # The nodes under the take lane, as HTML.
  #
  # @return [Array<String>] the nodes under the lane
  def html_children
    [clips.to_html].reject(&:empty?)
  end

  # The serializer of the clips of the take lane.
  #
  # @return [LiveMidiClipGroups] the clips
  def clips
    @clips ||= LiveMidiClipGroups.new @take_lane.clips, @hierarchical_number.dup.indent
  end
end
