require 'spec_helper'
require 'live_set/live_set_track'
require 'live_set/live_set_audio_clip'

# These specs document the CURRENT behaviour of clip-slot parsing, which is
# broken in several ways. See TODO.md S3 for the analysis and the recommended fix.
#
# The expectations below are the behaviour a correct implementation should have. The examples
# that currently fail are marked `pending`, so the suite stays green while the defect is
# tracked. RSpec reports a pending example as a failure if it unexpectedly passes, so these
# specs will flag the moment the underlying behaviour changes.
RSpec.describe LiveTrack, 'clip slot parsing (see TODO.md S3)' do
  def track_for(slot_count:, nested:)
    slots = (1..slot_count).map do |i|
      clip_slot_xml(nested: nested, id: (13 + i).to_s, relative_path: "Samples/Imported/song#{i}.mp3")
    end.join
    described_class.new '/tmp', audio_track_element(clip_slots: slots)
  end

  describe 'the Live 8 nested layout' do
    it 'finds the clip when the track has a single clip slot' do
      pending 'TODO.md S3: a single ClipSlot is returned as an Element, whose #each yields attribute pairs'
      track = track_for(slot_count: 1, nested: true)

      expect(track.audio_clips.length).to eq(1)
    end

    it 'finds all of the clips when the track has several clip slots' do
      track = track_for(slot_count: 3, nested: true)

      expect(track.audio_clips.length).to eq(3)
    end

    it 'reads the sample path from each clip' do
      pending 'TODO.md M9: LiveAudioClip reads RelativePath with .text, but the Value attribute holds the path'
      track = track_for(slot_count: 2, nested: true)

      expect(track.audio_clips.map(&:relative_path))
        .to eq(['Samples/Imported/song1.mp3', 'Samples/Imported/song2.mp3'])
    end
  end

  describe 'the Live 12 flat layout' do
    it 'finds the clip when the track has a single clip slot' do
      pending 'TODO.md S3: the ClipSlot accessor yields attribute pairs for a single match'
      track = track_for(slot_count: 1, nested: false)

      expect(track.audio_clips.length).to eq(1)
    end

    it 'finds all of the clips when the track has several clip slots' do
      pending 'TODO.md S3: the nested-ClipSlot fallback raises instead of returning nil'
      track = track_for(slot_count: 3, nested: false)

      expect(track.audio_clips.length).to eq(3)
    end
  end

  describe 'a track with no clip slots' do
    it 'reports no clips rather than raising' do
      pending 'TODO.md S3: the ClipSlot accessor raises when nothing matches'
      track = track_for(slot_count: 0, nested: false)

      expect(track.audio_clips).to be_empty
    end
  end
end
