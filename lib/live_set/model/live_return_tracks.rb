require_relative 'live_return_track'

# The return tracks of a set.
#
# A collection of the tracks, in the order they appear in the file.
class LiveReturnTracks
  include Enumerable

  attr_reader :tracks

  # @param set_directory [String] the directory of the set
  # @param elements [Array<Nokogiri::XML::Element>] the `<ReturnTrack>` elements, in the order
  #   they appear in the file
  def initialize(set_directory, elements)
    @tracks = elements.map { |element| LiveReturnTrack.new set_directory, element }
  end

  # @return [Integer] the number of tracks
  def size
    tracks.length
  end

  # @return [Boolean] true when there are no tracks
  def empty?
    tracks.empty?
  end

  # @yieldparam track [LiveReturnTrack] a track
  # @return [Enumerator, LiveReturnTracks] the tracks
  def each(&)
    return enum_for(:each) unless block_given?

    tracks.each(&)
    self
  end
end
