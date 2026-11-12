require_relative 'live_return_track_serializer'
require_relative 'live_track_collection_serializer'

# Writes a collection of return tracks.
#
# The collection is never written by itself: each track is written by the serializer of a
# track, and the outputs are mapped together.
#
# Sample usage:
# markdown = LiveReturnTracksSerializer.new(tracks, '1.1').to_markdown
class LiveReturnTracksSerializer < LiveTrackCollectionSerializer
  # Creates a serializer for a collection of return tracks.
  #
  # @param tracks [LiveReturnTracks] the tracks of the collection
  # @param first_number [HierarchicalNumber] the number of the first track of the collection
  def initialize(tracks, first_number)
    super(tracks, LiveReturnTrackSerializer, first_number)
  end
end
