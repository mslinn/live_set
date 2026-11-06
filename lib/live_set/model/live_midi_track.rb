require_relative '../../common/xml'
require_relative '../serializer/live_midi_track_serializer'
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

  # TODO: if set_directory is not required, delete it and correct all call sites
  # @param set_directory [String] the directory of the set
  # @param element [Nokogiri::XML::Element] the `<MidiTrack>` element
  def initialize(_set_directory, element)
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

  # The markdown of the track.
  #
  # The track is written by the serializer of a track, which is given the track and the
  # number the track has in the report.
  #
  # @param number [String] the number of the track in the report
  # @return [String] the markdown
  def to_markdown(number)
    LiveMidiTrackSerializer.new(self, number).to_markdown
  end
end
