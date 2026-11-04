require_relative '../live_palette'
require_relative 'live_track_serializer'

# Serializes a `LiveClip` model as markdown.
#
# A clip is written once for each place it is in, and the copies of it are alike, so the
# report counts them. The number of the clip is the number of the track it is on and the
# number of the copy among the clips of the track.
#
# Sample usage:
# clip = LiveClip.new(...)
# markdown = LiveClipSerializer.new(clip, '1.1.1').to_markdown
class LiveClipSerializer
  # Creates a serializer for the given clip.
  #
  # @param clip [LiveClip] the clip to be serialized
  # @param hierarchical_number [String] the number of the clip in the report
  def initialize(clip, hierarchical_number)
    @clip = clip
    @hierarchical_number = hierarchical_number
  end

  # Returns the clip as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    text = name_markdown
    text += "  #{@clip.marks.join(', ')}" unless @clip.marks.empty?
    text += "<br>`#{@clip.file}`" if @clip.file
    text
  end

  private

  # The name of the clip, on the colour Live gave it.
  #
  # @return [String] the name of the clip
  def name_markdown
    color = LivePalette.color_of @clip.color
    return "<code>#{@clip.name}</code>" unless color

    LiveTrackSerializer.colored_code @clip.name,
                                     color_number:     @clip.color,
                                     background_color: "##{color}",
                                     foreground_color: LiveTrackSerializer.text_color(color)
  end
end
