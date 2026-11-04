require_relative 'live_device_serializer'

# Writes a collection of devices.
#
# The collection is never written by itself: each device is written by the serializer of a
# device, and the outputs are mapped together.
#
# Sample usage:
# markdown = LiveDevicesSerializer.new(devices, '1.1', slot_label: 'Track Device').to_markdown
class LiveDevicesSerializer
  # Creates a serializer for a collection of devices.
  #
  # @param devices [Array<LiveDevice>] the devices of the collection
  # @param hierarchical_number [String] the number of the collection in the report
  # @param slot_label [String] the name of the devices of a kind of track: `Track Device` or
  #   `Group Track Device`
  # @param indent [String] the indentation of the lines of the collection
  # @param track_frozen [Boolean] true when the track the devices are on is frozen
  def initialize(devices, hierarchical_number, slot_label:, indent: '', track_frozen: false)
    @devices = devices
    @hierarchical_number = hierarchical_number
    @slot_label = slot_label
    @indent = indent
    @track_frozen = track_frozen
  end

  # Returns the collection as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    @devices.each_with_index.map do |device, index|
      number = "#{@hierarchical_number}#{letter_of index}"
      serializer = LiveDeviceSerializer.new device, number, track_frozen: @track_frozen
      "#{@indent}- #{@slot_label} #{number}  #{serializer.to_markdown}"
    end.join("\n")
  end

  private

  # The letter of a device, from the number of it in the collection.
  #
  # @param index [Integer] the number of the device, counting from zero
  # @return [String] the letter
  def letter_of(index)
    ('a'.ord + index).chr
  end
end
