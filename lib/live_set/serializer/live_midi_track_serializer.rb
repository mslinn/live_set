require_relative 'live_devices_serializer'
require_relative 'live_markup'
require_relative 'live_midi_clip_groups'
require_relative 'live_take_lanes_serializer'

# Serializes a `LiveMidiTrack` model as markdown.
#
# It writes the line of the track, and then the devices, the clips and the take lanes under
# it.
#
# Sample usage:
# track = LiveMidiTrack.new(...)
# markdown = LiveMidiTrackSerializer.new(track, '1.1').to_markdown
class LiveMidiTrackSerializer
  # Creates a serializer for the given track.
  #
  # @param track [LiveMidiTrack] the track to be serialized
  # @param hierarchical_number [String] the number of the track in the report
  # @param indent [String] the indentation of the lines of the track
  def initialize(track, hierarchical_number, indent = '')
    @track = track
    @hierarchical_number = hierarchical_number
    @indent = indent
  end

  # Returns the track as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    parts = [track_line, device_lines, clip_lines.join("\n"), take_lane_lines.join("\n")]
    parts.reject(&:empty?).join "\n"
  end

  private

  # The line of the track: its number, its icon, its kind, its name and its state.
  #
  # @return [String] the line
  def track_line
    LiveMarkup.track_line @track, @hierarchical_number, @indent
  end

  # The lines of the devices of the track.
  #
  # @return [String] the devices
  def device_lines
    LiveDevicesSerializer.new(@track.devices, @hierarchical_number, slot_label:   'Track Device',
                                                                    indent:       "#{@indent}  ",
                                                                    track_frozen: @track.frozen?).to_markdown
  end

  # The lines of the clips of the track.
  #
  # @return [Array<String>] the lines
  def clip_lines
    LiveMidiClipGroups.new(@track.clips).to_markdown(@hierarchical_number)
                      .map { |line| "#{@indent}  #{line}" }
  end

  # The lines of the take lanes of the track.
  #
  # @return [Array<String>] the lines
  def take_lane_lines
    return [] if @track.take_lanes.empty?

    serializer = LiveTakeLanesSerializer.new @track.take_lanes, @hierarchical_number, "#{@indent}  "
    serializer.to_markdown.split("\n")
  end
end
