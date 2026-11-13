require_relative 'live_midi_track'

# The MIDI tracks of a set, and the MIDI tracks of a group.
#
# A collection of the tracks, in the order they appear in the file.
class LiveMidiTracks
  include Enumerable

  attr_reader :tracks

  # @param elements [Array<Nokogiri::XML::Element>] the `<MidiTrack>` elements, in the order
  #   they appear in the file
  def initialize(elements)
    @tracks = elements.map { |element| LiveMidiTrack.new element }
  end

  # The tracks at the top of the set: the tracks that are in no group.
  #
  # @return [Array<LiveMidiTrack>] the tracks
  def top_level
    tracks.reject(&:group_id)
  end

  # @return [Integer] the number of tracks
  def size
    tracks.length
  end

  # @return [Boolean] true when there are no tracks
  def empty?
    tracks.empty?
  end

  # @yieldparam track [LiveMidiTrack] a track
  # @return [Enumerator, LiveMidiTracks] the tracks
  def each(&)
    return enum_for(:each) unless block_given?

    tracks.each(&)
    self
  end
end
