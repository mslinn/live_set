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
  # @param hierarchical_number [String, nil] the number of the collection in the report, or
  #   nil when the tracks are at the top of the set
  # @param start [Integer] the number of the first track of the collection
  def initialize(tracks, track_serializer, hierarchical_number = nil, start = 1)
    if instance_of? LiveTrackCollectionSerializer
      raise NotImplementedError, "#{self.class} is an abstract base class and cannot be instantiated directly."
    end

    @tracks = tracks
    @track_serializer = track_serializer
    @hierarchical_number = hierarchical_number
    @start = start
  end

  # Returns the collection as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    @tracks.each_with_index.map do |track, index|
      @track_serializer.new(track, number_of(index)).to_markdown
    end.join("\n")
  end

  private

  # The number of a track of the collection.
  #
  # @param index [Integer] the number of the track, counting from zero
  # @return [String] the number
  def number_of(index)
    number = @start + index
    return number.to_s if @hierarchical_number.nil?

    "#{@hierarchical_number}.#{number}"
  end
end
