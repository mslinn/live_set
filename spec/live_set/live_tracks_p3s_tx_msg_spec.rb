require 'spec_helper'
require 'live_set/live_set_track'
require 'live_set/live_set_live_tracks'

RSpec.describe LiveTracks, '#p3s_tx_msg' do
  # Builds a LiveTracks holding the given stand-in tracks.
  def tracks_with(*tracks, groups: [])
    tracks_object = described_class.allocate
    tracks_object.instance_variable_set(:@tracks, tracks)
    tracks_object.instance_variable_set(:@track_instances, tracks)
    tracks_object.instance_variable_set(:@group_instances, groups)
    tracks_object
  end

  # A track with one clip, so that the advice is not skipped.
  def track_with_clip(name: 'T', device_summary: '')
    FakeTrack.new(name, [FakeTrackClip.new('/music/song.mp3', true)], [], device_summary)
  end

  context 'when the set has no problems' do
    it 'reports that the set is ready' do
      track = FakeTrack.new('T', [], [], '')
      tracks = tracks_with(track)

      expect(tracks.send(:p3s_tx_msg)).to include('Ready for transfer to Push 3 Standalone')
    end
  end

  context 'when a clip has not been collected' do
    it 'reports that the set is not ready' do
      clip = FakeTrackClip.new('/music/song.mp3', false)
      track = FakeTrack.new('T', [clip], [], '')
      tracks = tracks_with(track)

      expect(tracks.send(:p3s_tx_msg)).to include('should not be transferred')
    end

    it 'names the uncollected clip once, however many tracks refer to it' do
      clip = FakeTrackClip.new('/music/song.mp3', false)
      tracks = tracks_with(FakeTrack.new('T', [clip], [], ''))

      expect(tracks.send(:p3s_tx_msg).scan('has not been collected').length).to eq(1)
    end
  end

  context 'when an unfrozen track uses a third-party device' do
    it 'reports that the set is not ready' do
      track = FakeTrack.new('T', [], [FakeDevice.new('Some Plugin')], 'Some Plugin')
      tracks = tracks_with(track)

      expect(tracks.send(:p3s_tx_msg)).to include('should not be transferred')
    end
  end

  context 'when an unfrozen track uses only native devices' do
    it 'still reports that the set is ready' do
      tracks = tracks_with(track_with_clip(device_summary: 'EQ Eight'))

      expect(tracks.send(:p3s_tx_msg)).to include('Ready for transfer to Push 3 Standalone')
    end

    it 'gives the advice without changing the verdict' do
      tracks = tracks_with(track_with_clip(device_summary: 'EQ Eight'))

      expect(tracks.send(:p3s_tx_msg)).to include('is unfrozen; devices: EQ Eight')
    end
  end

  context 'when a group uses a third-party device' do
    # A group's members are routed to the group, so the group's devices process the members' audio.
    # A plug-in in a group's chain blocks a transfer just as much as one on a track.
    #
    # A group track cannot be frozen, and freezing a member does not help: a frozen member stays
    # routed into its group, so the device is still in the signal path. The remedy is to remove
    # the device from the group's chain, or to bounce the group.
    it 'reports that the set is not ready' do
      group = FakeGroup.new('VOZ', [FakeDevice.new('OTT')])
      tracks = tracks_with(groups: [group])

      expect(tracks.send(:p3s_tx_msg)).to include('should not be transferred')
    end

    it 'names the group' do
      group = FakeGroup.new('VOZ', [FakeDevice.new('OTT')])
      tracks = tracks_with(groups: [group])

      expect(tracks.send(:p3s_tx_msg)).to include("Group 'VOZ'")
    end

    it 'names the device' do
      group = FakeGroup.new('VOZ', [FakeDevice.new('OTT')])
      tracks = tracks_with(groups: [group])

      expect(tracks.send(:p3s_tx_msg)).to include('OTT')
    end

    it 'says how to render the device away' do
      group = FakeGroup.new('VOZ', [FakeDevice.new('OTT')])
      tracks = tracks_with(groups: [group])

      expect(tracks.send(:p3s_tx_msg)).to include("Remove it from the group's device chain")
    end

    it 'offers bouncing the group as another way to render it away' do
      group = FakeGroup.new('VOZ', [FakeDevice.new('OTT')])
      tracks = tracks_with(groups: [group])

      expect(tracks.send(:p3s_tx_msg)).to include('bounce the group')
    end

    it 'names the tracks whose audio the device affects' do
      member = member_track_element(name: 'VOX 1')
      group = FakeGroup.new('VOZ', [FakeDevice.new('OTT')], [member])
      tracks = tracks_with(groups: [group])

      expect(tracks.send(:p3s_tx_msg)).to include('It affects VOX 1.')
    end

    it 'does not name a member that is routed somewhere other than the group' do
      member = member_track_element(name: 'VOX 1', target: 'AudioOut/Main')
      group = FakeGroup.new('VOZ', [FakeDevice.new('OTT')], [member])
      tracks = tracks_with(groups: [group])

      expect(tracks.send(:p3s_tx_msg)).not_to include('It affects')
    end

    it 'names a track once when several tracks share its name' do
      members = [member_track_element(name: 'VOX 2'), member_track_element(name: 'VOX 2')]
      group = FakeGroup.new('VOZ', [FakeDevice.new('OTT')], members)
      tracks = tracks_with(groups: [group])

      expect(tracks.send(:p3s_tx_msg)).to include('It affects VOX 2.')
    end
  end

  context 'when a group uses only native devices' do
    it 'still reports that the set is ready' do
      group = FakeGroup.new('VOZ', [])
      tracks = tracks_with(groups: [group])

      expect(tracks.send(:p3s_tx_msg)).to include('Ready for transfer to Push 3 Standalone')
    end
  end
end
