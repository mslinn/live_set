require_relative 'hierarchical_number_serializer'
require_relative 'live_audio_tracks_serializer'
require_relative 'live_device_serializer'
require_relative 'live_devices_serializer'
require_relative 'live_markup'
require_relative 'live_midi_tracks_serializer'

# Serializes a `LiveGroup` model as markdown by serializing each member track.
#
# A group is a summing container: it holds no clips of its own, and the tracks in it are
# under it.
#
# Sample usage:
# group = LiveGroup.new(...)
# markdown = LiveGroupSerializer.new(group, '1').to_markdown
class LiveGroupSerializer
  # Creates a serializer for the given group.
  #
  # @param group [LiveGroup] the group to be serialized
  # @param hierarchical_number [HierarchicalNumber] the number of the group in the report
  def initialize(group, hierarchical_number)
    @group = group
    @hierarchical_number = hierarchical_number
  end

  # Returns the group and its member tracks as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    item.to_markdown markdown_children
  end

  # Returns the group and its member tracks as HTML.
  #
  # @return [String] the serialized HTML
  def to_html
    item.to_html html_children
  end

  # The tracks in the group, with the numbers they have in the report.
  #
  # The numbers of the members follow the number of the group, and they are the numbers the
  # cross-references of the set use.
  #
  # @return [Array<Array>] the number and the track
  def numbered_members
    track_serializers.flat_map(&:numbered_tracks)
  end

  private

  # The item of the group: its number, its icon, its kind and its name.
  #
  # @return [HierarchicalNumberSerializer] the item
  def item
    @item ||= HierarchicalNumberSerializer.new @hierarchical_number, group_text
  end

  # The text of the group: its number, its icon, its kind and its name.
  #
  # @return [String] the text
  def group_text
    "Group track #{@hierarchical_number}  #{@group.icon} Group  #{name_markdown(@group.display_name)}"
  end

  # The nodes under the group, as markdown.
  #
  # @return [Array<String>] the nodes under the group
  def markdown_children
    [devices.to_markdown, *track_serializers.map(&:to_markdown)].reject(&:empty?)
  end

  # The nodes under the group, as HTML.
  #
  # @return [Array<String>] the nodes under the group
  def html_children
    [devices.to_html, *track_serializers.map(&:to_html)].reject(&:empty?)
  end

  # The name of the group, on the colour Live gave it.
  #
  # A group that P3S Standalone cannot use is written on the dark background of those
  # nodes, and the name of it is in light text.
  #
  # @return [String] the name of the group
  def name_markdown(name)
    if problem?
      return LiveMarkup.colored_code LiveMarkup.escape(name),
                                     background_color: LiveMarkup::DARK_BACKGROUND,
                                     foreground_color: LiveMarkup::LIGHT_TEXT
    end

    color = LivePalette.color_of @group.color
    return "<code>#{LiveMarkup.escape name}</code>" unless color

    LiveMarkup.colored_code LiveMarkup.escape(name),
                            color_number:     @group.color,
                            background_color: "##{color}",
                            foreground_color: LiveMarkup.text_color(color)
  end

  # Whether the group cannot be transferred to P3S Standalone.
  #
  # A group cannot be frozen, so a device in its chain that P3S cannot run cannot be
  # rendered away.
  #
  # @return [Boolean] true when the group is a problem
  def problem?
    @group.blocking_devices.any?
  end

  # The serializer of the devices of the group.
  #
  # @return [LiveDevicesSerializer] the devices
  def devices
    @devices ||= LiveDevicesSerializer.new(@group.devices, @hierarchical_number,
                                           slot_label: 'Group Track Device')
  end

  # The serializers of the tracks in the group.
  #
  # The MIDI members of the group come first, and the audio members after them, and the
  # numbers of the members follow the number of the group. The devices of the group come
  # before the members, and the members are numbered after them.
  #
  # @return [Array<LiveTrackCollectionSerializer>] the serializers
  def track_serializers
    number = @hierarchical_number.dup.indent.increment @group.devices.size
    [
      LiveMidiTracksSerializer.new(@group.midi_tracks, number),
      LiveAudioTracksSerializer.new(@group.audio_tracks, number.dup.increment(@group.midi_tracks.size))
    ]
  end
end
