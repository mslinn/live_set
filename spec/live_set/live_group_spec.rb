require 'spec_helper'
require 'live_set/live_set_group'
require 'support/live_sets'

# A group track is a summing container, not a track that plays clips. It has no clips, so it is
# not reported alongside the tracks, but its members' audio is routed through its device chain, so
# its devices are checked.
#
# See docs/als_notes.md, "The group tracks".
#
# The groups are real ones. The Live 11 Suite demo set holds a group of four tracks whose chain
# holds native devices only, and the checked-in set with return tracks holds a group whose chain
# holds a Max for Live device, which blocks a transfer to Push 3 Standalone.
RSpec.describe LiveGroup do
  # The group of the Live 11 Suite demo set.
  def suite_group
    @suite_group ||= LiveSets.node LiveSets.suite, '//GroupTrack[@Id="76"]'
  end

  # The tracks of the Live 11 Suite demo set.
  def suite_tracks
    @suite_tracks ||= LiveSets.nodes LiveSets.suite, '//AudioTrack'
  end

  # The group of the checked-in set with return tracks.
  def fascination_group
    @fascination_group ||= LiveSets.node LiveSets.fascination, '//GroupTrack[@Id="17"]'
  end

  it 'takes its name from the EffectiveName' do
    group = described_class.new suite_group

    expect(group.name).to eq('Vocals')
  end

  it 'takes its id from the Id attribute' do
    group = described_class.new suite_group

    expect(group.id).to eq('76')
  end

  it 'finds the devices in its chain' do
    group = described_class.new suite_group

    expect(group.devices.length).to eq(6)
  end

  it 'has no devices when its chain is empty' do
    element = LiveSets.without suite_group, './DeviceChain/DeviceChain/Devices'
    group = described_class.new element

    expect(group.devices).to be_empty
  end

  it 'reports a third-party device in its chain as blocking' do
    group = described_class.new fascination_group

    expect(group.blocking_devices.length).to eq(1)
  end

  it 'names the blocking device' do
    group = described_class.new fascination_group

    expect(group.blocking_devices.first.label).to eq('Filter')
  end

  it 'does not report a native device as blocking' do
    group = described_class.new suite_group

    expect(group.blocking_devices).to be_empty
  end

  it 'finds the tracks that belong to it' do
    group = described_class.new suite_group

    expect(group.member_tracks(suite_tracks).length).to eq(4)
  end

  context 'when it is given the tracks in the set' do
    it 'keeps the tracks that belong to it as its members' do
      group = described_class.new suite_group, suite_tracks

      expect(group.members.length).to eq(4)
    end

    it 'names its members' do
      group = described_class.new suite_group, suite_tracks

      expect(group.member_names).to eq(['Lead', 'Harmony', 'Delay Vox', 'Extra Line'])
    end

    it 'has no members when the set has no tracks' do
      group = described_class.new suite_group, []

      expect(group.members).to be_empty
    end
  end
end
