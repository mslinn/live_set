require_relative '../../common/xml'
require_relative 'live_midi_clip'
require_relative 'live_track_facts'

# A MIDI track of a set: the `<MidiTrack>` element of the XML.
#
# A MIDI track holds MIDI clips, and it plays no file. The audio track of the set is
# `LiveAudioTrack`, and it is a different thing: it holds the files it plays.
#
# The model holds no number: the XML has no notion of a track number, and the serializer
# generates the numbers of the report.
#
# not implemented: parsing of elements AutomationEnvelopes, AutomationLane and the
# arrangement of a track
class LiveMidiTrack
  include Xml
  include LiveTrackFacts

  # The places a MIDI clip of a track can be in.
  #
  # The clips of the take lanes are in the lanes, which are subordinate to the track.
  PLACES = {
    'session view' => 'DeviceChain/MainSequencer/ClipSlotList/ClipSlot/ClipSlot/Value/MidiClip',
    'arrangement'  => 'DeviceChain/MainSequencer/ClipTimeable/ArrangerAutomation/Events/MidiClip',
  }.freeze

  attr_reader :clips

  # @param element [Nokogiri::XML::Element] the `<MidiTrack>` element
  def initialize(element)
    @element = element
    read_track_facts 'MidiTrack'
    @clips = clips_of_track
  end

  # The kind of the track.
  #
  # @return [String] the kind
  def kind
    'MIDI'
  end

  # The clips of the track, and the place each of them is in.
  #
  # @return [Array<LiveMidiClip>] the clips
  def clips_of_track
    PLACES.flat_map do |place, path|
      @element.xpath(path).map { |node| LiveMidiClip.new node, place: place }
    end
  end
end
