require_relative 'hierarchical_number_serializer'
require_relative 'live_devices_serializer'
require_relative 'live_midi_clip_groups'
require_relative 'live_take_lanes_serializer'
require_relative 'live_track_markup'

# Writes a track of a set.
#
# It writes the line of the track, and then the nodes under it: its devices, its clips and
# its take lanes.
#
# The devices, the clips and the take lanes of the track are numbered in one sequence among
# themselves, so that the number of a node says where it is in the outline.
class LiveTrackSerializer
  include LiveTrackMarkup

  # Creates a serializer for the given track.
  #
  # @param track [LiveMidiTrack, LiveAudioTrack, LiveReturnTrack] the track to be serialized
  # @param hierarchical_number [HierarchicalNumber] the number of the track in the report
  def initialize(track, hierarchical_number)
    @track = track
    @hierarchical_number = hierarchical_number
  end

  # Returns the track as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    item.to_markdown markdown_children
  end

  # Returns the track as HTML.
  #
  # @return [String] the serialized HTML
  def to_html
    item.to_html html_children
  end

  private

  # The item of the track: its number, its icon, its kind, its name and its state.
  #
  # @return [HierarchicalNumberSerializer] the item
  def item
    @item ||= HierarchicalNumberSerializer.new @hierarchical_number, track_text(@track, @hierarchical_number)
  end

  # The nodes under the track, as markdown.
  #
  # @return [Array<String>] the nodes under the track
  def markdown_children
    child_collections.map(&:to_markdown).reject(&:empty?)
  end

  # The nodes under the track, as HTML.
  #
  # @return [Array<String>] the nodes under the track
  def html_children
    child_collections.map(&:to_html).reject(&:empty?)
  end

  # The collections of the nodes under the track.
  #
  # @return [Array<Object>] the collections
  def child_collections
    [devices, clips, *extra_children, lanes]
  end

  # The collections of the nodes under the track that are neither its devices, nor its MIDI
  # clips, nor its take lanes.
  #
  # @return [Array<Object>] the collections
  def extra_children
    []
  end

  # The serializer of the devices of the track.
  #
  # @return [LiveDevicesSerializer] the devices
  def devices
    @devices ||= LiveDevicesSerializer.new(@track.devices, @hierarchical_number, slot_label:   'Track Device',
                                                                                 track_frozen: @track.frozen?)
  end

  # The serializer of the MIDI clips of the track.
  #
  # @return [LiveMidiClipGroups] the clips
  def clips
    @clips ||= LiveMidiClipGroups.new @track.clips, first_clip_number
  end

  # The serializer of the take lanes of the track.
  #
  # @return [LiveTakeLanesSerializer] the take lanes
  def lanes
    @lanes ||= LiveTakeLanesSerializer.new @track.take_lanes, first_lane_number
  end

  # The number of the first clip of the track.
  #
  # The devices of the track come first, and the clips after them. The clips are numbered
  # among the other children of the track.
  #
  # @return [HierarchicalNumber] the number
  def first_clip_number
    @hierarchical_number.dup.indent.increment @track.devices.size
  end

  # The number of the first take lane of the track.
  #
  # The devices of the track come first, then its clips, and then its take lanes.
  #
  # @return [HierarchicalNumber] the number
  def first_lane_number
    @hierarchical_number.dup.indent.increment @track.children_before_the_take_lanes
  end
end
