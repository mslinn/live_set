require 'spec_helper'
require 'live_set/live_device'

# The devices in a chain are the children of DeviceChain/DeviceChain/Devices. A plug-in is a
# PluginDevice, and its name is in a different place depending on the plug-in format.
#
# See docs/als_notes.md, "The devices of a chain, and the plug-ins among them".
RSpec.describe LiveDevice do
  def device_from(xml)
    described_class.new Nokogiri::Slop("<Devices>#{xml}</Devices>").xpath('//Devices/*').first
  end

  describe 'a VST2 plug-in' do
    it 'takes its name from the PlugName' do
      device = device_from vst2_plugin_device_xml(name: 'MAutoPitch')

      expect(device.name).to eq('MAutoPitch')
    end

    it 'is a plug-in' do
      device = device_from vst2_plugin_device_xml

      expect(device).to be_plug_in
    end

    it 'blocks a transfer to Push 3 Standalone' do
      device = device_from vst2_plugin_device_xml

      expect(device).to be_blocking
    end
  end

  describe 'a VST3 plug-in' do
    it 'takes its name from the Name element' do
      device = device_from plugin_device_xml(name: 'OTT')

      expect(device.name).to eq('OTT')
    end

    it 'is a plug-in' do
      device = device_from plugin_device_xml

      expect(device).to be_plug_in
    end

    it 'blocks a transfer to Push 3 Standalone' do
      device = device_from plugin_device_xml

      expect(device).to be_blocking
    end
  end

  describe 'a native Ableton device' do
    it 'is not a plug-in' do
      device = device_from '<Eq8><LomId Value="0"/><Name Value="EQ Eight"/></Eq8>'

      expect(device).not_to be_plug_in
    end

    it 'does not block a transfer to Push 3 Standalone' do
      device = device_from '<Eq8><LomId Value="0"/><Name Value="EQ Eight"/></Eq8>'

      expect(device).not_to be_blocking
    end

    it 'takes its name from its own Name element' do
      device = device_from '<Eq8><LomId Value="0"/><Name Value="EQ Eight"/></Eq8>'

      expect(device.name).to eq('EQ Eight')
    end
  end

  describe 'a Max for Live device' do
    it 'blocks a transfer to Push 3 Standalone' do
      device = device_from '<MxDeviceAudioEffect><LomId Value="0"/></MxDeviceAudioEffect>'

      expect(device).to be_blocking
    end
  end
end
