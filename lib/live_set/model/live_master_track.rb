require_relative '../../common/xml'
require_relative '../serializer/live_master_track_serializer'
require_relative 'live_track_facts'

# The master track of a set: the `<MasterTrack>` element of the XML, which Live 12 writes
# as `<MainTrack>`.
#
# The master track is a child of the set and not of the tracks of the set, and it holds no
# clips of its own.
#
# The model holds no number: the XML has no notion of a track number, and the serializer
# generates the numbers of the report.
class LiveMasterTrack
  include Xml
  include LiveTrackFacts

  # The kinds of master track, and the element that holds each of them.
  KINDS = { 'MasterTrack' => 'Master', 'MainTrack' => 'Main' }.freeze

  # @param set_directory [String] the directory of the set
  # @param element [Nokogiri::XML::Element] the `<MasterTrack>` element
  def initialize(_set_directory, element)
    @element = element
    read_track_facts 'MasterTrack'
  end

  # The kind of the track.
  #
  # Live 12 renamed the master track to the main track, and it is the same thing.
  #
  # @return [String] the kind
  def kind
    KINDS.fetch(@element.name, @element.name)
  end

  # The markdown of the track.
  #
  # The track is written by the serializer of a track, which is given the track and the
  # number the track has in the report.
  #
  # @param number [String] the number of the track in the report
  # @return [String] the markdown
  def to_markdown(number)
    LiveMasterTrackSerializer.new(self, number).to_markdown
  end
end
