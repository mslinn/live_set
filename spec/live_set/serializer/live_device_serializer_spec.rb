require 'spec_helper'
require 'live_set/serializer/live_device_serializer'
require 'support/live_sets'
require 'support/numbers'

# A device of a track.
#
# The expected value is the device as it is written in the report of the set as it is
# written now:
#
#   sets/live_11/reports/Fascination.md
#
# The slot of the device — "Track Device 1.1a" — and the number of it are written by the
# serializer of the track, which numbers the devices of its track. What is written here is
# the device itself: its name on the background of the thing P3S cannot use, the kind of
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
    number = ReportNumbers.number 'G', 1, 1, 2
    markdown = described_class.new(device('DrumBuss'), number, slot_label: 'Track Device').to_markdown

    expect(markdown).to eq(
      '    - Track Device G1.1.2  <code>DrumBuss</code>  Live'
    )
  end

  it 'writes the name of a device P3S cannot run on the dark background, and warns of it' do
    number = ReportNumbers.number 'G', 1, 1, 1
    markdown = described_class.new(device('Kontakt 7'), number, slot_label: 'Track Device').to_markdown

    expect(markdown).to eq(
      '    - Track Device G1.1.1  <code style="color: #FFFFFF; background-color: #212121; ' \
      'vertical-align: middle;">Kontakt 7</code>  VST3  ⚠ not usable on P3S'
    )
  end
end
