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
  # @param hierarchical_number [String] the number of the group in the report
  def initialize(group, hierarchical_number)
    @group = group
    @hierarchical_number = hierarchical_number
  end

  # Returns the group and its member tracks as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    parts = [group_line, device_lines, track_details]
    parts.reject(&:empty?).join "\n"
  end

  private

  # The line of the group: its number, its icon, its kind and its name.
  #
  # The indentation of the line comes from the number of the group, so that the number and the
  # place of the group in the outline always agree.
  #
  # @return [String] the line
  def group_line
    name = LiveMarkup.display_name @group
    "#{LiveMarkup.indent_for(@hierarchical_number)}- Group track #{@hierarchical_number}  " \
      "👥 Group  #{name_markdown(name)}"
  end

  # The name of the group, on the colour Live gave it.
  #
  # A group that Push 3 Standalone cannot use is written on the dark background of those
  # things, and the name of it is in light text.
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

  # Whether the group cannot be transferred to Push 3 Standalone.
  #
  # A group cannot be frozen, so a device in its chain that Push 3 cannot run cannot be
  # rendered away.
  #
  # @return [Boolean] true when the group is a problem
  def problem?
    @group.blocking_devices.any?
  end

  # The lines of the devices of the group.
  #
  # @return [String] the devices
  def device_lines
    LiveDevicesSerializer.new(@group.devices, @hierarchical_number,
                              slot_label: 'Group Track Device').to_markdown
  end

  # The lines of the tracks in the group.
  #
  # The MIDI members of the group come first, and the audio members after them, and the
  # numbers of the members follow the number of the group.
  #
  # @return [String] the tracks
  def track_details
    midi = LiveMidiTracksSerializer.new @group.midi_tracks, @hierarchical_number, 1
    audio = LiveAudioTracksSerializer.new @group.audio_tracks, @hierarchical_number,
                                          @group.midi_tracks.size + 1
    [midi.to_markdown, audio.to_markdown].reject(&:empty?).join("\n")
  end
end
