require_relative 'live_collection_serializer'
require_relative 'live_device_serializer'
require_relative 'live_markup'

# Writes a collection of devices.
#
# The collection is never written by itself: each device is written by the serializer of a
# device, and the outputs are mapped together.
#
# The indentation of a device comes from its number, so that the number of a device and the
# place of it in the outline always agree.
#
# Sample usage:
# markdown = LiveDevicesSerializer.new(devices, number, slot_label: 'Track Device').to_markdown
class LiveDevicesSerializer < LiveCollectionSerializer
  # Creates a serializer for a collection of devices.
  #
  # @param devices [Array<LiveDevice>] the devices of the collection
  # @param hierarchical_number [HierarchicalNumber] the number of the collection in the report
  # @param slot_label [String] the name of the devices of a kind of track: `Track Device` or
  #   `Group Track Device`
  # @param track_frozen [Boolean] true when the track the devices are on is frozen
  def initialize(devices, hierarchical_number, slot_label:, track_frozen: false)
    super()
    @devices = devices
    @hierarchical_number = hierarchical_number
    @slot_label = slot_label
    @track_frozen = track_frozen
  end

  # The devices of the collection, with the numbers they have in the report.
  #
  # @return [Array<Array>] the number and the device
  def numbered_devices
    @numbered_devices ||= begin
      number = @hierarchical_number.dup.indent
      @devices.map do |device|
        [number.dup, device].tap { number.increment }
      end
    end
  end

  private

  # The devices of the collection, with the numbers they have in the report.
  #
  # @return [Array<Array>] the number and the device
  def items
    numbered_devices
  end

  # The serializer of a device.
  #
  # @param number [HierarchicalNumber] the number of the device
  # @param device [LiveDevice] the device
  # @return [LiveDeviceSerializer] the serializer
  def serializer_for(number, device)
    LiveDeviceSerializer.new device, number, slot_label: @slot_label, track_frozen: @track_frozen
  end
end
