require 'spec_helper'
require 'live_set/live_set_track'
require 'live_set/live_set_audio_clip'

RSpec.describe LiveTrack, '#distinct_clips' do
  around { |example| silence_stdout { example.run } }

  # Builds a track in which the same file is referenced from all three sources.
  def track_with_shared_file(file_size: '1000')
    shared = audio_clip_xml(id: '0', relative_path: 'Samples/Imported/shared.mp3', file_size: file_size)
    slot = "<ClipSlot Id=\"0\"><LomId Value=\"0\"/><ClipSlot><Value>#{shared}</Value></ClipSlot></ClipSlot>"

    described_class.new '/tmp', audio_track_element(
      clip_slots:        slot,
      arrangement_clips: shared,
      take_lane_clips:   shared
    )
  end

  it 'counts a file that is referenced from more than one source once' do
    track = track_with_shared_file

    expect(track.distinct_clips.length).to eq(1)
  end

  it 'counts a file that is referenced from more than one source once in the size' do
    track = track_with_shared_file(file_size: '1000')

    expect(track.track_size).to eq(1000)
  end
end
