require_relative 'live_track_serializer'

# Writes a collection of tracks.
#
# The collection is never written by itself: each track is written by the serializer of a
# track, and the outputs are mapped together.
#
# The tracks of a group are numbered after the group, as 1.1. The tracks at the top of the
# set are numbered from one in their own company, so they are given no base number.
#
# Sample usage:
# markdown = LiveTracksSerializer.new(tracks, '1.1').to_markdown
class LiveTracksSerializer
  # Creates a serializer for a collection of tracks.
  #
  # @param tracks [Array<LiveTrack>] the tracks of the collection
  # @param hierarchical_number [String, nil] the number of the collection in the report, or
  #   nil when the tracks are at the top of the set
  # @param indent [String] the indentation of the lines of the collection
  def initialize(tracks, hierarchical_number = nil, indent = '')
    @tracks = tracks
    @hierarchical_number = hierarchical_number
    @indent = indent
  end

  # Returns the collection as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    @tracks.each_with_index.map do |track, index|
      LiveTrackSerializer.new(track, number_of(index), @indent).to_markdown
    end.join("\n")
  end

  private

  # The number of a track of the collection.
  #
  # @param index [Integer] the number of the track, counting from zero
  # @return [String] the number
  def number_of(index)
    return (index + 1).to_s if @hierarchical_number.nil?

    "#{@hierarchical_number}.#{index + 1}"
  end
end
