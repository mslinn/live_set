require 'spec_helper'
require 'live_set/serializer/live_device_serializer'
require 'support/live_sets'

# A device of a track.
#
# The expected value is the device as it is written in the report of the set as it is
# written now:
#
#   sets/live_11/reports/Fascination.md
#
# The slot of the device — "Track Device 1.1a" — and the number of it are written by the
# serializer of the track, which numbers the devices of its track. What is written here is
# the device itself: its name on the background of the thing Push 3 cannot use, the kind of
# device it is, and the warning.
RSpec.describe LiveDeviceSerializer, '#to_markdown' do
  # The device of the set with the given name.
  #
  # @param label [String] the name of the device
  # @return [LiveDevice] the device
  def device(label)
    node = LiveSets.nodes(LiveSets.fascination, './/Devices/*').find do |candidate|
      LiveDevice.new(candidate).label == label
    end
    LiveDevice.new node
  end

  it 'writes the name of a device and the kind of device it is' do
    expect(described_class.new(device('DrumBuss'), '1.1b').to_markdown).to eq(
      '<code>DrumBuss</code>  Live'
    )
  end

  it 'writes the name of a device Push 3 cannot run on the dark background, and warns of it' do
    expect(described_class.new(device('Kontakt 7'), '1.1a').to_markdown).to eq(
      '<code style="background-color: #212121; color: #FFFFFF; vertical-align: middle">Kontakt 7</code>  ' \
      'VST3  ⚠ not usable on Push 3'
    )
  end
end
