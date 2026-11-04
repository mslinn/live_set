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
  # The background a clip whose sample is not in the project is marked on.
  NOT_COLLECTED_BACKGROUND = '#8B0000'.freeze

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
    text += "  #{marks_markdown}" unless @clip.marks.empty?
    text += "<br>`#{@clip.file}`" if @clip.file
    text
  end

  private

  # The marks of the clip.
  #
  # A clip whose sample is not in the project is marked on a dark red, in white text.
  #
  # @return [String] the marks
  def marks_markdown
    @clip.marks.map do |mark|
      LiveTrackSerializer.code_span mark,
                                    style: "background-color:#{NOT_COLLECTED_BACKGROUND}; " \
                                           "color:#{LiveTrackSerializer::LIGHT_TEXT}; vertical-align:middle"
    end.join ', '
  end

  # The name of the clip, on the colour Live gave it.
  #
  # @return [String] the name of the clip
  def name_markdown
    color = LivePalette.color_of @clip.color
    return "<code>#{LiveTrackSerializer.escape @clip.name}</code>" unless color

    LiveTrackSerializer.colored_code LiveTrackSerializer.escape(@clip.name),
                                     color_number:     @clip.color,
                                     background_color: "##{color}",
                                     foreground_color: LiveTrackSerializer.text_color(color)
  end
end
