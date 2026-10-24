require 'spec_helper'
require 'live_set/live_set_track'
require 'live_set/live_set_audio_clip'

RSpec.describe LiveTrack, '#audio_clips' do
  around { |example| silence_stdout { example.run } }

  # Builds a track with clips in the session view, the arrangement, and a take lane.
  def track_for(session: 0, arrangement: 0, take_lane: 0)
    slots = (1..session).map { |i| clip_slot_xml(id: i.to_s, relative_path: "Samples/Imported/s#{i}.mp3") }.join
    arrangement_xml = (1..arrangement).map do |i|
      audio_clip_xml(id: (100 + i).to_s, relative_path: "Samples/Imported/a#{i}.mp3")
    end.join
    take_lane_xml = (1..take_lane).map do |i|
      audio_clip_xml(id: (200 + i).to_s, relative_path: "Samples/Imported/t#{i}.mp3")
    end.join

    described_class.new '/tmp', audio_track_element(
      clip_slots:        slots,
      arrangement_clips: arrangement_xml,
      take_lane_clips:   take_lane_xml
    )
  end

  # Builds a track in which the same file is referenced from all three sources.
  def track_with_shared_file
    shared = audio_clip_xml(id: '0', relative_path: 'Samples/Imported/shared.mp3', file_size: '1000')
    slot = "<ClipSlot Id=\"0\"><LomId Value=\"0\"/><ClipSlot><Value>#{shared}</Value></ClipSlot></ClipSlot>"

    described_class.new '/tmp', audio_track_element(
      clip_slots:        slot,
      arrangement_clips: shared,
      take_lane_clips:   shared
    )
  end

  it 'groups the clips by where they come from' do
    track = track_for(session: 1, arrangement: 1, take_lane: 1)

    expect(track.audio_clips.keys).to eq(['Session view', 'Arrangement', 'Take lanes'])
  end

  it 'finds a clip in a single session-view slot' do
    track = track_for(session: 1)

    expect(track.audio_clips['Session view'].length).to eq(1)
  end

  it 'finds all of the clips in several session-view slots' do
    track = track_for(session: 3)

    expect(track.audio_clips['Session view'].length).to eq(3)
  end

  it 'finds the clips in the arrangement' do
    track = track_for(arrangement: 2)

    expect(track.audio_clips['Arrangement'].length).to eq(2)
  end

  it 'finds the clips in the take lanes' do
    track = track_for(take_lane: 2)

    expect(track.audio_clips['Take lanes'].length).to eq(2)
  end

  it 'reports no clips for a track that has none' do
    track = track_for

    expect(track.distinct_clips).to be_empty
  end

  it 'reads the sample path from each clip' do
    track = track_for(session: 2)

    expect(track.audio_clips['Session view'].map(&:relative_path))
      .to eq(['Samples/Imported/s1.mp3', 'Samples/Imported/s2.mp3'])
  end

  it 'lists the reference in each source' do
    track = track_with_shared_file

    expect(track.audio_clips.values.map(&:length)).to eq([1, 1, 1])
  end
end
