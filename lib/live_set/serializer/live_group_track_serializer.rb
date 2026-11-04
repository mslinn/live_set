require_relative 'live_device_serializer'
require_relative 'live_track_serializer'

# Serializes a `LiveGroup` model as markdown by serializing each member track.
#
# A group is a summing container: it holds no clips of its own, and the tracks in it are
# under it.
#
# Sample usage:
# group = LiveGroup.new(...)
# markdown = LiveGroupTrackSerializer.new(group, '1').to_markdown
class LiveGroupTrackSerializer
  # Creates a serializer for the given group.
  #
  # @param group [LiveGroup] the group to be serialized
  # @param hierarchical_number [String] the number of the group in the report
  # @param indent [String] the indentation of the lines of the group
  def initialize(group, hierarchical_number, indent = '')
    @group = group
    @hierarchical_number = hierarchical_number
    @indent = indent
  end

  # Returns the group and its member tracks as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = [group_line]
    lines += device_lines
    lines += track_lines
    lines.join "\n"
  end

  private

  # The line of the group: its number, its icon, its kind and its name.
  #
  # @return [String] the line
  def group_line
    "#{@indent}- Group track #{@hierarchical_number}  👥 Group  #{name_markdown}"
  end

  # The name of the group, on the colour Live gave it.
  #
  # A group that Push 3 Standalone cannot use is written on the dark background of those
  # things, and the name of it is in light text.
  #
  # @return [String] the name of the group
  def name_markdown
    if problem?
      return LiveTrackSerializer.colored_code LiveTrackSerializer.escape(@group.name),
                                                              background_color: LiveTrackSerializer::DARK_BACKGROUND,
                                                              foreground_color: LiveTrackSerializer::LIGHT_TEXT
    end

    color = LivePalette.color_of @group.color
    return "<code>#{LiveTrackSerializer.escape @group.name}</code>" unless color

    LiveTrackSerializer.colored_code LiveTrackSerializer.escape(@group.name),
                                     color_number:     @group.color,
                                     background_color: "##{color}",
                                     foreground_color: LiveTrackSerializer.text_color(color)
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
  # @return [Array<String>] the lines
  def device_lines
    @group.devices.each_with_index.map do |device, index|
      letter = ('a'.ord + index).chr
      number = "#{@hierarchical_number}#{letter}"
      serializer = LiveDeviceSerializer.new device, number
      "#{@indent}  - Group Track Device #{number}  #{serializer.to_markdown}"
    end
  end

  # The lines of the tracks in the group.
  #
  # @return [Array<String>] the lines
  def track_lines
    @group.tracks.each_with_index.map do |track, index|
      number = "#{@hierarchical_number}.#{index + 1}"
      LiveTrackSerializer.new(track, number, "#{@indent}  ").to_markdown
    end
  end
end
