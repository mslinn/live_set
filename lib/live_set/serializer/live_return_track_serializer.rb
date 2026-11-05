require_relative 'live_devices_serializer'
require_relative 'live_markup'

# Serializes a `LiveReturnTrack` model as markdown.
#
# It writes the line of the track, and then the devices under it. A return track holds no
# clips.
#
# Sample usage:
# track = LiveReturnTrack.new(...)
# markdown = LiveReturnTrackSerializer.new(track, '1.1').to_markdown
class LiveReturnTrackSerializer
  # Creates a serializer for the given track.
  #
  # @param track [LiveReturnTrack] the track to be serialized
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
    parts = [track_line, device_lines]
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
end
