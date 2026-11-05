require_relative 'live_master_track_serializer'
require_relative 'live_track_collection_serializer'

# Writes a collection of master tracks.
#
# The collection is never written by itself: each track is written by the serializer of a
# track, and the outputs are mapped together.
#
# Sample usage:
# markdown = LiveMasterTracksSerializer.new(tracks, '1.1').to_markdown
class LiveMasterTracksSerializer < LiveTrackCollectionSerializer
  # Creates a serializer for a collection of master tracks.
  #
  # @param tracks [LiveMasterTracks] the tracks of the collection
  # @param hierarchical_number [String, nil] the number of the collection in the report, or
  #   nil when the tracks are at the top of the set
  # @param start [Integer] the number of the first track of the collection
  # @param indent [String] the indentation of the lines of the collection
  def initialize(tracks, hierarchical_number = nil, start = 1, indent = '')
    super(tracks, LiveMasterTrackSerializer, hierarchical_number, start, indent)
  end
end
