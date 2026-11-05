require_relative '../model/live_palette'
require_relative 'live_markup'

# Serializes a `LiveMidiClip` model as markdown.
#
# A MIDI clip holds notes and plays no file, so the line of it is its name on the colour
# Live gave it. The settings of the clip — how it is launched and how its sample is warped —
# are written under the line, by the group of alike clips the clip is in.
#
# Sample usage:
# clip = LiveMidiClip.new(...)
# markdown = LiveMidiClipSerializer.new(clip, '1.1.1').to_markdown
class LiveMidiClipSerializer
  # Creates a serializer for the given clip.
  #
  # @param clip [LiveMidiClip] the clip to be serialized
  # @param hierarchical_number [String] the number of the clip in the report
  def initialize(clip, hierarchical_number)
    @clip = clip
    @hierarchical_number = hierarchical_number
  end

  # Returns the clip as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    name_markdown
  end

  private

  # The name of the clip, on the colour Live gave it.
  #
  # @return [String] the name of the clip
  def name_markdown
    color = LivePalette.color_of @clip.color
    return "<code>#{LiveMarkup.escape @clip.name}</code>" unless color

    LiveMarkup.colored_code LiveMarkup.escape(@clip.name),
                            color_number:     @clip.color,
                            background_color: "##{color}",
                            foreground_color: LiveMarkup.text_color(color)
  end
end
