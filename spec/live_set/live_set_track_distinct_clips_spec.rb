require 'spec_helper'
require 'live_set/live_set_track'
require 'live_set/live_set_audio_clip'
require 'support/live_sets'

# The clips of a track, counted by the file they come from.
#
# The track is a real one: the "Lead" track of the Live 11 Suite demo set. Its 27 clips all
# refer to one file, and that file is referred to from the session view, the arrangement and the
# take lanes at the same time.
RSpec.describe LiveTrack, '#distinct_clips' do
  around { |example| silence_output { example.run } }

  # The path of the set the track is in.
  def path
    LiveSets.suite
  end

  # The track.
  def track
    @track ||= described_class.new LiveSets.directory(path),
                                   LiveSets.node(path, '//AudioTrack[@Id="150"]')
  end

  it 'counts a file that is referenced from more than one source once' do
    expect(track.distinct_clips.length).to eq(1)
  end

  it 'counts a file that is referenced from more than one source once in the size' do
    expect(track.track_size).to eq(38_102_454)
  end

  it 'reports the same count as the number of distinct files' do
    expect(track.distinct_file_count).to eq(track.distinct_clips.length)
  end
end
