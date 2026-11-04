require_relative 'live_take_lane'

# The take lanes of a track.
#
# A collection of the lanes of a track, in the order Live wrote them.
class LiveTakeLanes
  include Enumerable

  attr_reader :lanes

  # @param track [Nokogiri::XML::Element] the track
  def initialize(track)
    @lanes = track.xpath('.//TakeLane').each_with_index.map do |element, index|
      LiveTakeLane.new element, index + 1
    end
  end

  # @return [Integer] the number of lanes
  def size
    lanes.length
  end

  # @return [Boolean] true when the track has no lanes
  def empty?
    lanes.empty?
  end

  # @param index [Integer] the number of the lane, from one
  # @return [LiveTakeLane, nil] the lane
  def [](index)
    lanes[index - 1]
  end

  # @yieldparam lane [LiveTakeLane] a lane
  # @return [Enumerator, LiveTakeLanes] the lanes
  def each(&)
    return enum_for(:each) unless block_given?

    lanes.each(&)
    self
  end
end
