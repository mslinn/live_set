require 'spec_helper'
require 'live_set/live_set_track'
require 'live_set/live_device'

# A track's device chain can be nested. An AudioEffectGroupDevice holds a group's device chain in
# its branches, so a member track's real devices are several levels down. A reader that looks only
# at the top level misses them.
#
# See docs/als_notes.md, "The device chain, and the chains nested inside it", and "The device
# chain of a group".
RSpec.describe LiveTrack, '#device_summary' do
  # Builds a track whose chain holds a plug-in.
  def track_with_devices(devices)
    xml = <<~XML
      <AudioTrack Id="1">
        <Name><EffectiveName Value="T"/></Name>
        <Freeze Value="false"/>
        <DeviceChain>
          <DeviceChain>
            <Devices>
              #{devices}
            </Devices>
          </DeviceChain>
        </DeviceChain>
      </AudioTrack>
    XML
    Nokogiri::Slop(xml).xpath('//AudioTrack').first
  end

  # Builds a track whose chain holds an AudioEffectGroupDevice, whose branch holds a plug-in.
  def track_with_group_branch
    xml = <<~XML
      <AudioTrack Id="1">
        <Name><EffectiveName Value="Member"/></Name>
        <Freeze Value="false"/>
        <DeviceChain>
          <DeviceChain>
            <Devices>
              <AudioEffectGroupDevice>
                <Branches>
                  <AudioEffectBranch>
                    <DeviceChain>
                      <AudioToAudioDeviceChain>
                        <Devices>
                          #{plugin_device_xml(name: 'OTT')}
                        </Devices>
                      </AudioToAudioDeviceChain>
                    </DeviceChain>
                  </AudioEffectBranch>
                </Branches>
              </AudioEffectGroupDevice>
            </Devices>
          </DeviceChain>
        </DeviceChain>
      </AudioTrack>
    XML
    Nokogiri::Slop(xml).xpath('//AudioTrack').first
  end

  it 'finds a plug-in nested in a group branch' do
    track = described_class.new '/tmp', track_with_group_branch

    expect(track.device_summary).to include('OTT')
  end

  it 'reports a plug-in nested in a group branch as blocking' do
    track = described_class.new '/tmp', track_with_group_branch

    expect(track.blocking_devices.length).to eq(1)
  end

  it 'does not report the group device itself as a device' do
    track = described_class.new '/tmp', track_with_group_branch

    expect(track.device_summary).not_to include('AudioEffectGroupDevice')
  end

  it 'finds a plug-in in the top level of the chain' do
    track = described_class.new '/tmp', track_with_devices(plugin_device_xml(name: 'Kontakt'))

    expect(track.device_summary).to include('Kontakt')
  end
end
