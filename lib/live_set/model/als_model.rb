require_relative 'header_block'
require_relative 'live_tracks'

# The complete model of the contents of an ALS file.
#
# The file is a set: the XML of it, the times of it, and the Live contents of it.
class AlsModel
  attr_reader :path, :xml, :file_created, :file_last_modified, :time_zone

  # @param path [String] the path of the file
  # @param xml [Nokogiri::XML::Document] the XML of the file
  # @param file_created [Time] the time the file was created
  # @param file_last_modified [Time] the time the file was last written
  # @param time_zone [String, nil] the time zone the times are written in
  def initialize(path, xml, file_created, file_last_modified, time_zone = nil)
    @path = path
    @xml = xml
    @file_created = file_created
    @file_last_modified = file_last_modified
    @time_zone = time_zone
  end

  # The Live contents of the file.
  #
  # Every track of the set is in the model: the MIDI tracks, the audio tracks, the groups,
  # the return tracks and the master track, in the order Live wrote them.
  #
  # @return [LiveTracks] the tracks of the set
  def live_set
    @live_set ||= LiveTracks.new directory, track_elements
  end

  # The facts about the file.
  #
  # @return [HeaderBlock] the facts about the set
  def header_block
    @header_block ||= HeaderBlock.new path, xml, time_zone
  end

  # The directory the file is in.
  #
  # @return [String] the path of the directory
  def directory
    File.dirname File.expand_path(path)
  end

  private

  # The elements of the tracks of the set, in the order Live wrote them.
  #
  # @return [Array<Nokogiri::XML::Element>] the elements
  def track_elements
    xml.xpath('//MidiTrack | //AudioTrack | //GroupTrack | //Tracks/ReturnTrack | ' \
              '//MasterTrack | //MainTrack')
  end
end
