# The clips of the audio side of a track.
#
# A collection of the clips, in the order they appear in the file. Each of them knows the
# place it is in: the session view, the arrangement, or a take lane.
class LiveAudioClips
  include Enumerable

  attr_reader :clips

  # @param clips [Array<LiveAudioClip>] the clips of the track
  def initialize(clips)
    @clips = clips
  end

  # The clips of the track, with each file counted once.
  #
  # The same file can be referenced from the session view, the arrangement and the take lanes
  # at the same time. It occupies space once, so it is counted once. See docs/als_notes.md,
  # "Where a track's audio is".
  #
  # @return [Array<LiveAudioClip>] the distinct clips
  def distinct
    clips.uniq(&:absolute_path)
  end

  # The clips that are in the given place.
  #
  # @param place [String] the place: `session view`, `arrangement`, or a take lane
  # @return [Array<LiveAudioClip>] the clips
  def in_place(place)
    clips.select { |clip| clip.place == place }
  end

  # The clips that are in the take lanes of the track.
  #
  # @return [Array<LiveAudioClip>] the clips
  def in_lanes
    clips.select { |clip| clip.place&.start_with? 'take lane ' }
  end

  # @return [Integer] the number of clips
  def size
    clips.length
  end

  # @return [Boolean] true when the track has no audio clips
  def empty?
    clips.empty?
  end

  # @yieldparam clip [LiveAudioClip] a clip
  # @return [Enumerator, LiveAudioClips] the clips
  def each(&)
    return enum_for(:each) unless block_given?

    clips.each(&)
    self
  end
end
