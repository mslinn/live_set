# Base class for writing collections of various types of tracks.
#
# The tracks of a group are numbered after the group, as 1.1. The tracks at the top of the
# set are numbered from one in their own company, and the number of the first of them is
# given, so that the numbers of the tracks of the set are unique.
class LiveTrackCollectionSerializer
  # Creates a serializer for a collection of tracks.
  #
  # @param tracks [Enumerable] the tracks of the collection
  # @param track_serializer [Class] the serializer of a track of the collection
  # @param first_number [HierarchicalNumber] the number of the first track of the collection
  def initialize(tracks, track_serializer, first_number)
    if instance_of? LiveTrackCollectionSerializer
      raise NotImplementedError, "#{self.class} is an abstract base class and cannot be instantiated directly."
    end

    @tracks = tracks
    @track_serializer = track_serializer
    @first_number = first_number
  end

  # Returns the collection as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    numbered_tracks.map do |number, track|
      @track_serializer.new(track, number).to_markdown
    end.join("\n")
  end

  # The tracks of the collection, with the numbers they have in the report.
  #
  # @return [Array<Array>] the number and the track
  def numbered_tracks
    @numbered_tracks ||= begin
      number = @first_number.dup
      @tracks.map do |track|
        [number.dup, track].tap { number.increment }
      end
    end
  end
end
