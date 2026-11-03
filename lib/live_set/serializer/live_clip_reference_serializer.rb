# TODO: This is a placeholder to start off the changes described as TODO comments in lib/live_set/live_palette.rb
# TODO Write unit tests
#
# Serializes a `LiveClipReference` model as markdown. Note that clips are not serialized to markdown, just their
# metadata, stored in `LiveClipReference`.
#
# Assuming a `LiveTrack` exposes member clip references through `clip_references`, the track serializer
# can delegate each clip reference to LiveClipReferenceSerializer.
#
# Sample usage:
# clip_reference = LiveClipReference.new(...)
# markdown = LiveClipReferenceSerializer.new(clip_reference).to_markdown
class LiveClipReferenceSerializer
  # Creates a serializer for the given clip reference.
  #
  # @param clip_reference [LiveClipReference] the reference whose metadata is to be serialized
  def initialize(clip_reference, hierarchical_number)
    @clip_reference = clip_reference
    @hierarchical_number = hierarchical_number
  end

  # Returns the clip reference metadata as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    # TODO: write me
  end
end
