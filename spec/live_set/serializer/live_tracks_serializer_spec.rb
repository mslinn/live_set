require 'spec_helper'
require 'live_set/model/live_tracks'
require 'live_set/serializer/live_tracks_serializer'
require 'support/live_sets'

# The tracks of a set.
#
# The set is the Live 11 reference set, which is checked in. It has groups, and the members
# of a group are numbered after it.
RSpec.describe LiveTracksSerializer, '#to_markdown' do
  # The tracks of the set.
  #
  # @return [LiveTracks] the tracks of the set
  def tracks
    @tracks ||= begin
      elements = LiveSets.nodes(LiveSets.fascination,
                                '//MidiTrack | //AudioTrack | //GroupTrack | //Tracks/ReturnTrack')
      LiveTracks.new LiveSets.directory(LiveSets.fascination), elements
    end
  end

  # The serializer of the tracks of the set.
  #
  # @return [LiveTracksSerializer] the serializer
  def serializer
    @serializer ||= described_class.new tracks
  end

  it 'writes a line for every track at the top of the set' do
    markdown = serializer.to_markdown
    lines = markdown.lines.grep(/\A- Track \d+  /)

    expect(lines.length).to eq tracks.top_level_tracks.length
  end

  it 'numbers the tracks at the top of the set from one, in the order Live wrote them' do
    numbers = serializer.numbered_tracks_of_the_set.map(&:first)

    expect(numbers).to eq (1..tracks.top_level_tracks.length).map(&:to_s)
  end

  it 'numbers the members of a group after the group' do
    members = serializer.numbered_members

    expect(members).not_to be_empty
    expect(members.map(&:first)).to all(match(/\A\d+\.\d+\z/))
  end

  it 'numbers every track of the set: the tracks at the top of it, and the members of the groups' do
    numbered = serializer.numbered_tracks
    expected = serializer.numbered_tracks_of_the_set.length + serializer.numbered_members.length

    expect(numbered.length).to eq expected
  end

  it 'gives a track of the set one number in the report' do
    numbers = serializer.numbered_tracks.map(&:first)

    expect(numbers.uniq.length).to eq numbers.length
  end
end
