require_relative 'live_clip'

# The clips of a set: every clip of every track.
#
# A clip is written once for each place it is in, and the copies of it are alike. The
# outline counts the copies that are alike, and the cross-reference says which tracks hold
# them.
#
# A group holds no clips of its own; the clips of the tracks in it are the clips of the set.
class LiveClips
  include Enumerable

  attr_reader :tracks

  # @param tracks [LiveTracks] the tracks of the set
  def initialize(tracks)
    @tracks = tracks
  end

  # Every clip of the set, with the track that holds it and the number of that track.
  #
  # The clips of the take lanes of a track are the clips of the track as well, and the lane
  # they are in is named with them.
  #
  # @yieldparam clip [LiveClip] a clip
  # @yieldparam number [String] the number of the track that holds it
  # @yieldparam track [LiveTrack, LiveGroup] the track that holds it
  # @yieldparam lane [String, nil] the number of the lane it is in, or nil when it is not
  #   in a lane
  # @return [void]
  def each_with_its_track
    tracks.each_numbered_track do |number, track|
      next if track.group?

      track.clips.each { |clip| yield clip, number, track, nil }
      track.take_lanes.each_with_index do |lane, index|
        lane_number = "#{number}.#{index + 1}"
        lane.clips.each { |clip| yield clip, number, track, lane_number }
      end
    end
  end

  # Every clip of the set.
  #
  # @yieldparam clip [LiveClip] a clip
  # @return [Enumerator, LiveClips] the clips
  def each(&)
    return enum_for(:each) unless block_given?

    each_with_its_track { |clip, _number, _track, _lane| yield clip }
    self
  end
end
