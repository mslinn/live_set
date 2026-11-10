require_relative '../../common/xml'
require_relative 'live_track_facts'

# A return track of a set: the `<ReturnTrack>` element of the XML.
#
# A return track receives the sends of the set and holds no clips of its own.
#
# The model holds no number: the XML has no notion of a track number, and the serializer
# generates the numbers of the report.
class LiveReturnTrack
  include Xml
  include LiveTrackFacts

  # @param set_directory [String] the directory of the set
  # @param element [Nokogiri::XML::Element] the `<ReturnTrack>` element
  def initialize(_set_directory, element)
    @element = element
    read_track_facts 'ReturnTrack'
  end

  # The kind of the track.
  #
  # @return [String] the kind
  def kind
    'Return'
  end
end
