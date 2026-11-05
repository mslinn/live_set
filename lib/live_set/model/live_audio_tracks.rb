require_relative 'live_audio_track'

# The audio tracks of a set, and the audio tracks of a group.
#
# A collection of the tracks, in the order Live wrote them.
class LiveAudioTracks
  include Enumerable

  attr_reader :tracks

  # @param set_directory [String] the directory of the set
  # @param elements [Array<Nokogiri::XML::Element>] the `<AudioTrack>` elements, in the order
  #   Live wrote them
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

  # The markdown of the tracks of the collection.
  #
  # Each track is written by the track itself, which delegates to the serializer of a track.
  #
  # @param hierarchical_number [String, nil] the number of the collection in the report, or
  #   nil when the tracks are at the top of the set
  # @param start [Integer] the number of the first track of the collection
  # @param indent [String] the indentation of the lines
  # @return [String] the markdown
  def to_markdown(hierarchical_number = nil, start = 1, indent = '')
    tracks.each_with_index.map do |track, index|
      track.to_markdown number_of(hierarchical_number, start + index), indent
    end.join("\n")
  end

  private

  # The number of a track of the collection.
  #
  # @param hierarchical_number [String, nil] the number of the collection in the report
  # @param number [Integer] the number of the track
  # @return [String] the number
  def number_of(hierarchical_number, number)
    return number.to_s if hierarchical_number.nil?

    "#{hierarchical_number}.#{number}"
  end
end
