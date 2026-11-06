require_relative 'live_midi_track'

# The MIDI tracks of a set, and the MIDI tracks of a group.
#
# A collection of the tracks, in the order Live wrote them.
class LiveMidiTracks
  include Enumerable

  attr_reader :tracks

  # @param set_directory [String] the directory of the set
  # @param elements [Array<Nokogiri::XML::Element>] the `<MidiTrack>` elements, in the order
  #   Live wrote them
  def initialize(set_directory, elements)
    @tracks = elements.map { |element| LiveMidiTrack.new set_directory, element }
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

  # TODO: Model classes should not contain a `to_markdown` method. This class and its parent class should have a
  # corresponding serializer, which should contain this method. See docs/report_design.md
  #
  # The markdown of the tracks of the collection.
  #
  # @param hierarchical_number [String, nil] the number of the collection in the report, or
  #   nil when the tracks are at the top of the set
  # @param start [Integer] the number of the first track of the collection
  # @return [String] the markdown
  def to_markdown(hierarchical_number = nil, start = 1)
    tracks.each_with_index.map do |track, index|
      track.to_markdown number_of(hierarchical_number, start + index)
    end.join("\n")
  end

  private

  # TODO: Model classes should not contain a `number_of` method. This class and its parent class should have a
  # corresponding serializer, which should contain this method. See docs/report_design.md
  #
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
