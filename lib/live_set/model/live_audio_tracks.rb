require_relative 'live_audio_track'

# The audio tracks of a set, and the audio tracks of a group.
#
# A collection of the tracks, in the order they appear in the file.
class LiveAudioTracks
  include Enumerable

  attr_reader :tracks

  # @param set_directory [String] the directory of the set
  # @param elements [Array<Nokogiri::XML::Element>] the `<AudioTrack>` elements, in the order
  #   they appear in the file
  def initialize(set_directory, elements)
    @tracks = elements.map { |element| LiveAudioTrack.new set_directory, element }
  end

  # The tracks at the top of the set: the tracks that are in no group.
  #
  # @return [Array<LiveAudioTrack>] the tracks
  def top_level
    tracks.reject(&:group_id)
  end

  # The audio clips of every track of the collection.
  #
  # @return [Array<LiveAudioClip>] the clips
  def audio_clips
    @audio_clips ||= tracks.flat_map { |track| track.audio_clips.to_a }
  end

  # @return [Integer] the number of tracks
  def size
    tracks.length
  end

  # @return [Boolean] true when there are no tracks
  def empty?
    tracks.empty?
  end

  # @yieldparam track [LiveAudioTrack] a track
  # @return [Enumerator, LiveAudioTracks] the tracks
  def each(&)
    return enum_for(:each) unless block_given?

    tracks.each(&)
    self
  end
end
