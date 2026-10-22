require 'spec_helper'
require 'live_set/live_set_track'
require 'live_set/live_set_audio_clip'

# A frozen track keeps both sequencers. The MainSequencer holds the editable material, and the
# FreezeSequencer holds the rendered audio cache that replaces it during playback. Some frozen
# tracks hold their clips only in the FreezeSequencer.
#
# See docs/als_format.md section 11.
RSpec.describe LiveTrack, '#audio_clips' do
  context 'when the track is frozen' do
    it 'finds a clip that is only in the FreezeSequencer' do
      slots = clip_slot_xml(id: '1', relative_path: 'Samples/Processed/Freeze/frozen.wav')
      track = described_class.new '/tmp', frozen_track_element(clip_slots: slots)

      expect(track.audio_clips['Session view'].length).to eq(1)
    end

    it 'finds an arrangement clip that is only in the FreezeSequencer' do
      clip = audio_clip_xml(id: '0', relative_path: 'Samples/Processed/Freeze/frozen.wav')
      track = described_class.new '/tmp', frozen_track_element(arrangement_clips: clip)

      expect(track.audio_clips['Arrangement'].length).to eq(1)
    end

    it 'reports the size of a clip that is only in the FreezeSequencer' do
      clip = audio_clip_xml(id: '0', relative_path: 'Samples/Processed/Freeze/frozen.wav', file_size: '4096')
      track = described_class.new '/tmp', frozen_track_element(arrangement_clips: clip)

      expect(track.track_size).to eq(4096)
    end

    it 'reports the track as frozen' do
      track = described_class.new '/tmp', frozen_track_element

      expect(track.frozen?).to be true
    end
  end

  context 'when the track holds clips in both sequencers' do
    it 'finds the clips in each sequencer' do
      slots = clip_slot_xml(id: '1', relative_path: 'Samples/Imported/live.wav')
      clip = audio_clip_xml(id: '2', relative_path: 'Samples/Processed/Freeze/frozen.wav')
      track = described_class.new '/tmp', frozen_track_element(clip_slots: slots, arrangement_clips: clip)

      expect(track.audio_clips.values.flatten.length).to eq(2)
    end
  end
end
