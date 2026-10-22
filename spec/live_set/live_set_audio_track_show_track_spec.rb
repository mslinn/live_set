require 'spec_helper'
require 'live_set/live_set_audio_track'

RSpec.describe LiveAudioTrack, '#show_track' do
  # Builds a track without running #initialize, so that the frozen state can be
  # exercised independently of the clip-slot parsing discussed in TODO.md S3.
  def track_with(frozen:, clip_count:)
    track = described_class.allocate
    track.instance_variable_set(:@audio_track, audio_track_element(freeze: frozen.to_s))
    track.instance_variable_set(:@id, '3')
    track.instance_variable_set(:@frozen, frozen)
    track.instance_variable_set(:@audio_clips, Array.new(clip_count) { FakeClip.new(0) })
    track.instance_variable_set(:@track_size, 0)
    track
  end

  context 'when the track is frozen' do
    it "reports the track as 'frozen'" do
      track = track_with(frozen: true, clip_count: 1)

      expect(track.show_track(false)).to include('frozen')
    end

    it "does not report the track as '**not frozen**'" do
      track = track_with(frozen: true, clip_count: 1)

      expect(track.show_track(false)).not_to include('not frozen')
    end
  end

  context 'when the track is not frozen' do
    it "reports the track as '**not frozen**'" do
      track = track_with(frozen: false, clip_count: 1)

      expect(track.show_track(false)).to include('**not frozen**')
    end
  end

  context 'when every track in the set is frozen' do
    it 'omits the frozen marker entirely' do
      track = track_with(frozen: true, clip_count: 1)

      expect(track.show_track(true)).not_to include('frozen')
    end
  end

  context 'when the track has no clips' do
    it 'omits the frozen marker entirely' do
      track = track_with(frozen: false, clip_count: 0)

      expect(track.show_track(false)).not_to include('not frozen')
    end
  end
end
