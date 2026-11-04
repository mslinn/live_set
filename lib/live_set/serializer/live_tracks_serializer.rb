require_relative 'live_track_serializer'

# Writes a collection of tracks.
#
# The collection is never written by itself: each track is written by the serializer of a
# track, and the outputs are mapped together.
#
# Sample usage:
# markdown = LiveTracksSerializer.new(tracks, '1.1').to_markdown
class LiveTracksSerializer
  # Creates a serializer for a collection of tracks.
  #
  # @param tracks [Array<LiveTrack>] the tracks of the collection
  # @param hierarchical_number [String] the number of the collection in the report
  # @param indent [String] the indentation of the lines of the collection
  def initialize(tracks, hierarchical_number, indent = '')
    @tracks = tracks
    @hierarchical_number = hierarchical_number
    @indent = indent
  end

  # Returns the collection as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    @tracks.each_with_index.map do |track, index|
      number = "#{@hierarchical_number}.#{index + 1}"
      LiveTrackSerializer.new(track, number, @indent).to_markdown
    end.join("\n")
  end
end
