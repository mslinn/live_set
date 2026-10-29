require 'spec_helper'
require 'live_set/live_set_group'

# A group track is a summing container, not a track that plays clips. It has no clips, so it is
# not reported alongside the tracks, but its members' audio is routed through its device chain, so
# its devices are checked.
#
# See docs/als_notes.md, "The group tracks".
RSpec.describe LiveGroup do
  it 'takes its name from the EffectiveName' do
    group = described_class.new group_track_element(name: 'VOZ')

    expect(group.name).to eq('VOZ')
  end

  it 'takes its id from the Id attribute' do
    group = described_class.new group_track_element(id: '43')

    expect(group.id).to eq('43')
  end

  it 'has no devices when its chain is empty' do
    group = described_class.new group_track_element

    expect(group.devices).to be_empty
  end

  it 'finds the devices in its chain' do
    group = described_class.new group_track_element(devices: plugin_device_xml(name: 'OTT'))

    expect(group.devices.length).to eq(1)
  end

  it 'reports a plug-in in its chain as blocking' do
    group = described_class.new group_track_element(devices: plugin_device_xml(name: 'OTT'))

    expect(group.blocking_devices.length).to eq(1)
  end

  it 'names the blocking device' do
    group = described_class.new group_track_element(devices: plugin_device_xml(name: 'OTT'))

    expect(group.blocking_devices.first.label).to eq('OTT')
  end

  it 'does not report a native device as blocking' do
    native = '<Eq8><LomId Value="0"/><Name Value="EQ Eight"/></Eq8>'
    group = described_class.new group_track_element(devices: native)

    expect(group.blocking_devices).to be_empty
  end

  it 'finds the tracks that belong to it' do
    group = described_class.new group_track_element(id: '34')
    tracks = [track_with_group('34'), track_with_group('27')]

    expect(group.member_tracks(tracks).length).to eq(1)
  end

  context 'when it is given the tracks in the set' do
    it 'keeps the tracks that belong to it as its members' do
      tracks = [member_track_element(name: 'VOX 1'), member_track_element(group_id: '27')]
      group = described_class.new group_track_element(id: '34'), tracks

      expect(group.members.length).to eq(1)
    end

    it 'names its members' do
      tracks = [member_track_element(name: 'VOX 1')]
      group = described_class.new group_track_element(id: '34'), tracks

      expect(group.member_names).to eq(['VOX 1'])
    end

    it 'has no members when the set has no tracks' do
      group = described_class.new group_track_element(id: '34'), []

      expect(group.members).to be_empty
    end
  end
end
