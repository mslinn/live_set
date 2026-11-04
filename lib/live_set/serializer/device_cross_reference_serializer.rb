require 'markdown-tables'
require_relative '../live_palette'
require_relative 'live_track_serializer'

# Writes the section of the report that crosses the devices of the set with the tracks they
# are on.
#
# A device of a group is on the group and on the tracks in the group, because the chain of
# the group processes the audio of the tracks in it.
#
# Sample usage:
# markdown = DeviceCrossReferenceSerializer.new(devices).to_markdown
class DeviceCrossReferenceSerializer
  # Creates a serializer for the devices of the set.
  #
  # @param devices [LiveDevices] the devices of the set, and the tracks they are on
  def initialize(devices)
    @devices = devices
  end

  # Returns the section as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = ['## Device/Track Cross-Reference', '']
    rows = rows_of_devices
    if rows.empty?
      lines << 'The set has no devices.'
      return lines.join("\n")
    end

    lines << MarkdownTables.make_table(['Device', 'Kind', 'Tracks With This Device'], rows,
                                       align: %w[l l l], is_rows: true)
    lines.join("\n")
  end

  private

  # The rows of the table: each device, its kind, and the tracks it is on.
  #
  # @return [Array<Array>] the rows
  def rows_of_devices
    uses = {}
    @devices.each_with_its_tracks do |device, tracks|
      unusable = device.blocking? && !tracks.first.frozen?
      key = [device.label, device.kind, unusable]
      uses[key] ||= []
      tracks.each { |track| uses[key] << track }
    end

    uses.sort_by { |(label, _kind, _unusable), _| label.downcase }.map do |(label, kind, unusable), tracks|
      name = if unusable
               LiveTrackSerializer.colored_code label,
                                                background_color: LiveTrackSerializer::DARK_BACKGROUND,
                                                foreground_color: LiveTrackSerializer::LIGHT_TEXT
             else
               "<code>#{LiveTrackSerializer.escape label}</code>"
             end
      [name, kind, tracks.map { |track| track_label track }.uniq.join(', ')]
    end
  end

  # The name of a track, on the colour Live gave it.
  #
  # @param track [LiveTrack, LiveGroup] the track
  # @return [String] the name of the track
  def track_label(track)
    name = LiveTrackSerializer.display_name track
    if track.problem?
      return LiveTrackSerializer.colored_code LiveTrackSerializer.escape(name),
                                              background_color: LiveTrackSerializer::DARK_BACKGROUND,
                                              foreground_color: LiveTrackSerializer::LIGHT_TEXT
    end

    color = LivePalette.color_of track.color
    return "<code>#{LiveTrackSerializer.escape name}</code>" unless color

    LiveTrackSerializer.colored_code LiveTrackSerializer.escape(name),
                                     color_number:     track.color,
                                     background_color: "##{color}",
                                     foreground_color: LiveTrackSerializer.text_color(color)
  end
end
