# TODO: This is a placeholder to start off the changes described as TODO comments in lib/live_set/live_palette.rb.
# TODO Write unit tests
#
# Serializes a `LiveDevice` model as markdown.
#
# Sample usage:
# device = LiveDevice.new(...)
# markdown = LiveDeviceSerializer.new(device).to_markdown
class LiveDeviceSerializer
  # Creates a serializer for the given device.
  #
  # @param device [LiveDevice] the device to be serialized
  def initialize(device, hierarchical_number)
    @device = device
    @hierarchical_number = hierarchical_number
  end

  # Returns the device as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    # TODO: write me
  end
end
