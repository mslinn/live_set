require_relative 'live_devices_serializer'
require_relative 'live_markup'

# Serializes a `LiveMasterTrack` model as markdown.
#
# It writes the line of the track, and then the devices under it. The master track holds no
# clips.
#
# Sample usage:
# track = LiveMasterTrack.new(...)
# markdown = LiveMasterTrackSerializer.new(track, '1.1').to_markdown
class LiveMasterTrackSerializer
  # Creates a serializer for the given track.
  #
  # @param track [LiveMasterTrack] the track to be serialized
  # @param hierarchical_number [String] the number of the track in the report
  def initialize(track, hierarchical_number)
    @track = track
    @hierarchical_number = hierarchical_number
  end

  # Returns the track as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    parts = [track_detail, device_lines]
    parts.reject(&:empty?).join "\n"
  end

  private

  # The line of the track: its number, its icon, its kind, its name and its state.
  #
  # @return [String] the line
  def track_detail
    LiveMarkup.track_detail @track, @hierarchical_number
  end

  # The lines of the devices of the track.
  #
  # @return [String] the devices
  def device_lines
    LiveDevicesSerializer.new(@track.devices, @hierarchical_number, slot_label:   'Track Device',
                                                                    track_frozen: @track.frozen?).to_markdown
  end
end
