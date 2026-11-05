require_relative 'live_master_track'

# The master track of a set.
#
# The master track is a child of the set and not of the tracks of the set, so it is a
# collection of its own. There is one of them, and the collection holds it.
class LiveMasterTracks
  include Enumerable

  attr_reader :tracks

  # @param set_directory [String] the directory of the set
  # @param elements [Array<Nokogiri::XML::Element>] the `<MasterTrack>` elements, in the order
  #   Live wrote them
  def initialize(set_directory, elements)
    @tracks = elements.map { |element| LiveMasterTrack.new set_directory, element }
  end

  # @return [Integer] the number of tracks
  def size
    tracks.length
  end

  # @return [Boolean] true when there is no master track
  def empty?
    tracks.empty?
  end

  # @yieldparam track [LiveMasterTrack] a track
  # @return [Enumerator, LiveMasterTracks] the tracks
  def each(&)
    return enum_for(:each) unless block_given?

    tracks.each(&)
    self
  end
end
