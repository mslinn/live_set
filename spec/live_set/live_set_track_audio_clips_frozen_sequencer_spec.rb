require 'spec_helper'
require 'live_set/live_set_track'
require 'live_set/live_set_audio_clip'
require 'support/live_sets'

# A frozen track keeps both sequencers. The MainSequencer holds the editable material, and the
# FreezeSequencer holds the rendered audio cache that replaces it during playback. Some frozen
# tracks hold their clips only in the FreezeSequencer.
#
# See docs/als_notes.md, "The two sequencers of a track, and the frozen track that keeps both".
#
# No set in the corpus holds a frozen track, so the case is made from a real track whose clips are
# moved into its FreezeSequencer. See LiveSets.frozen_with_clips_in_freeze_sequencer.
RSpec.describe LiveTrack, '#audio_clips' do
  around { |example| silence_output { example.run } }

  # The path of the set the track is in.
  def path
    LiveSets.suite
  end

  # The track, with its clips in the FreezeSequencer.
  def track
    @track ||= begin
      element = LiveSets.frozen_with_clips_in_freeze_sequencer LiveSets.node(path, '//AudioTrack[@Id="150"]')
      described_class.new LiveSets.directory(path), element
    end
  end

  context 'when the track is frozen' do
    it 'reports the track as frozen' do
      expect(track.frozen?).to be true
    end

    it 'finds the session view clips in the FreezeSequencer' do
      expect(track.audio_clips['Session view'].length).to eq(3)
    end

    it 'finds the arrangement clips in the FreezeSequencer' do
      expect(track.audio_clips['Arrangement'].length).to eq(21)
    end

    it 'reports the size of the clips in the FreezeSequencer' do
      expect(track.track_size).to eq(38_102_454)
    end
  end

  context 'when the track holds clips in both sequencers' do
    # The track whose clips are in both sequencers.
    def track_in_both
      @track_in_both ||= begin
        element = LiveSets.frozen_with_clips_in_freeze_sequencer LiveSets.node(path, '//AudioTrack[@Id="150"]'),
                                                                 keep_main: true
        described_class.new LiveSets.directory(path), element
      end
    end

    it 'finds the clips in each sequencer' do
      expect(track_in_both.audio_clips['Session view'].length).to eq(6)
      expect(track_in_both.audio_clips['Arrangement'].length).to eq(42)
    end

    it 'counts the file the two sequencers share once' do
      expect(track_in_both.distinct_clips.length).to eq(1)
    end
  end
end
