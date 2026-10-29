require 'spec_helper'
require 'live_set/live_device'
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

    it 'blocks a transfer to Push 3 Standalone' do
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

    it 'does not block a transfer to Push 3 Standalone' do
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

    it 'blocks a transfer to Push 3 Standalone' do
      expect(device).to be_blocking
    end

    it 'is not a plug-in' do
      expect(device).not_to be_plug_in
    end
  end
end
