require 'markdown-tables'
require_relative '../model/live_palette'
require_relative 'live_markup'

# Writes the section of the report that crosses the devices of the set with the tracks they
# are on.
#
# Sample usage:
# markdown = DeviceCrossReferenceSerializer.new(cross_reference).to_markdown
class DeviceCrossReferenceSerializer
  # Creates a serializer for the cross-reference of the devices and the tracks.
  #
  # @param cross_reference [LiveDeviceCrossReference] the devices and the tracks they are on
  def initialize(cross_reference)
    @cross_reference = cross_reference
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
    @cross_reference.uses.sort_by { |(label, _kind, _unusable), _| label.downcase }.map do |(label, kind, unusable), tracks|
      name = if unusable
               LiveMarkup.colored_code label,
                                       background_color: LiveMarkup::DARK_BACKGROUND,
                                       foreground_color: LiveMarkup::LIGHT_TEXT
             else
               "<nobr><code>#{LiveMarkup.escape label}</code></nobr>"
             end
      [name, kind, tracks.map { |track| track_label track }.uniq.join(', ')]
    end
  end

  # The name of a track, on the colour Live gave it.
  #
  # The name is in a table cell, so it is written without a line break.
  #
  # @param track [LiveTrack, LiveGroup] the track
  # @return [String] the name of the track
  def track_label(track)
    LiveMarkup.track_name_markdown track, track.display_name, in_a_cell: true
  end
end
