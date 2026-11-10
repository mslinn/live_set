require 'spec_helper'
require 'live_set/model/live_device'
require 'support/live_sets'

# The devices in a chain are the children of DeviceChain/DeviceChain/Devices. A plug-in is a
# PluginDevice, and its name is in a different place depending on the plug-in format.
#
# See docs/als_notes.md, "The devices of a chain, and the plug-ins among them".
#
# The devices are real ones, from the checked-in set with return tracks and a third-party device.
# That set holds the only plug-in in the corpus, and the only Max for Live devices in it.
RSpec.describe LiveDevice do
  # The path of the set the devices are in.
  def path
    LiveSets.fascination
  end

  describe 'a VST3 plug-in' do
    # The plug-in of the corpus, a Kontakt 7.
    def device
      described_class.new LiveSets.node(path, '//PluginDevice')
    end

    it 'takes its name from the Name element' do
      expect(device.name).to eq('Kontakt 7')
    end

    it 'is a plug-in' do
      expect(device).to be_plug_in
    end

    it 'blocks a transfer to P3S Standalone' do
      expect(device).to be_blocking
    end

    it 'is labelled with its name' do
      expect(device.label).to eq('Kontakt 7')
    end
  end

  describe 'a native Ableton device' do
    # An Eq8, one of the devices in a group branch of the corpus.
    def device
      described_class.new LiveSets.node(path, '//AudioTrack[@Id="20"]//AudioEffectBranch//Devices/Eq8')
    end

    it 'is not a plug-in' do
      expect(device).not_to be_plug_in
    end

    it 'does not block a transfer to P3S Standalone' do
      expect(device).not_to be_blocking
    end

    it 'takes its name from the element it is written as' do
      # A native device has no Name element of its own.
      expect(device.name).to eq('Eq8')
    end
  end

  describe 'a Max for Live device' do
    # A Max for Live device of the corpus.
    def device
      described_class.new LiveSets.node(path, '//MxDeviceAudioEffect')
    end

    it 'is a Max for Live device' do
      expect(device).to be_max_for_live
    end

    it 'does not block a transfer to P3S Standalone' do
      # The P3S Standalone runs Max for Live devices, with less headroom than a desktop.
      expect(device).not_to be_blocking
    end

    it 'is not a plug-in' do
      expect(device).not_to be_plug_in
    end
  end

  describe 'a Max for Live MIDI effect' do
    # The corpus holds no Max for Live MIDI effect, so the element of the audio effect is
    # copied and given the name of a MIDI effect.
    def device
      element = LiveSets.with_element_name LiveSets.node(path, '//MxDeviceAudioEffect'), 'MxDeviceMidiEffect'
      described_class.new element
    end

    it 'is a Max for Live device' do
      expect(device).to be_max_for_live
    end
  end

  describe 'a Max for Live instrument' do
    # The corpus holds no Max for Live instrument, so the element of the audio effect is
    # copied and given the name of an instrument.
    def device
      element = LiveSets.with_element_name LiveSets.node(path, '//MxDeviceAudioEffect'), 'MxDeviceInstrument'
      described_class.new element
    end

    it 'is a Max for Live device' do
      expect(device).to be_max_for_live
    end
  end

  describe 'a device whose name says it is a Max for Live device' do
    # A native device that the user called "Max for Live". The name of a device is whatever
    # the user called it, and says nothing about what the device is: the element does.
    def device
      element = LiveSets.with_element_name LiveSets.node(path, '//MxDeviceAudioEffect'), 'Eq8'
      copy = Nokogiri::Slop element.to_xml
      copied = copy.at_xpath('//*')
      copied.xpath('.//UserName | .//EffectiveName').each { |name| name['Value'] = 'Max for Live' }
      described_class.new copied
    end

    it 'is not a Max for Live device' do
      expect(device).not_to be_max_for_live
    end
  end
end
