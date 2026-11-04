require_relative '../../common/xml'
require_relative 'live_clip'

# A take lane of a track.
#
# A lane holds the takes of a recording, and the track holds the clips that are heard. The
# lanes are subordinate to the track.
#
# not implemented: parsing of elements ArrangementClipsListWrapper and Audition
class LiveTakeLane
  include Xml

  attr_reader :name, :index, :clips

  # @param element [Nokogiri::XML::Element] the take lane
  # @param index [Integer] the number of the lane among the lanes of its track, from one
  def initialize(element, index = 1)
    @element = element
    @index = index
    @name = element.at('Name')&.[]('Value')
    @clips = element.xpath('./ClipAutomation/Events/AudioClip | ./ClipAutomation/Events/MidiClip')
                    .map { |clip| LiveClip.new clip, place: 'take lane' }
  end

  # The id Live gave the lane.
  #
  # @return [String, nil] the id
  def id
    @element['Id']
  end
end
