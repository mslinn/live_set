# TODO: This is a placeholder to start off the changes described as TODO comments in lib/live_set/live_palette.rb.
# TODO Write unit tests
#
require_relative 'live_track_serializer'

# Serializes a `LiveDevice` model as markdown.
#
# The name of the device and the number of it are written by the serializer of the track the
# device is on: the name depends on the kind of the track, and the number is the number the
# track serializer gives it. What is written here is the device itself.
#
# Sample usage:
# device = LiveDevice.new(...)
# markdown = LiveDeviceSerializer.new(device, '1.1a').to_markdown
class LiveDeviceSerializer
  # The warning on a device that Push 3 Standalone cannot run.
  NOT_USABLE = '⚠ not usable on Push 3'.freeze

  # Creates a serializer for the given device.
  #
  # @param device [LiveDevice] the device to be serialized
  # @param hierarchical_number [String] the number of the device in the report
  # @param track_frozen [Boolean] true when the track the device is on is frozen
  def initialize(device, hierarchical_number, track_frozen: false)
    @device = device
    @hierarchical_number = hierarchical_number
    @track_frozen = track_frozen
  end

  # Returns the device as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    parts = [name_markdown, @device.kind]
    parts << NOT_USABLE if unusable?
    parts.join '  '
  end

  private

  # The name of the device.
  #
  # A device that Push 3 Standalone cannot run is written on the dark background of the
  # things it cannot run on, and the name of it is in light text.
  #
  # @return [String] the name of the device
  def name_markdown
    return LiveTrackSerializer.colored_code(@device.label) unless unusable?

    LiveTrackSerializer.colored_code @device.label,
                                     background_color: LiveTrackSerializer::DARK_BACKGROUND,
                                     foreground_color: LiveTrackSerializer::LIGHT_TEXT
  end

  # Whether the device stops the track from being transferred to Push 3 Standalone.
  #
  # A device Push 3 cannot run blocks the transfer, unless the track is frozen: freezing a
  # track renders its devices away.
  #
  # @return [Boolean] true when the device is a problem
  def unusable?
    @device.blocking? && !@track_frozen
  end
end
