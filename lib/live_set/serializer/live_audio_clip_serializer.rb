require 'bytesize'
require_relative '../model/live_palette'
require_relative 'live_markup'

# Serializes a `LiveAudioClip` model as markdown.
#
# A clip of the audio side of a track plays a file, and the file is what the report is
# about: where it is, how big it is, and whether it is in the project. The place the clip is
# in is written with it, because the same file is in the session view, in the arrangement
# and in the take lanes at the same time.
#
# Sample usage:
# clip = LiveAudioClip.new(...)
# markdown = LiveAudioClipSerializer.new(clip, '1.1.1').to_markdown
class LiveAudioClipSerializer
  # The background a clip whose sample is not in the project is marked on.
  NOT_COLLECTED_BACKGROUND = '#8B0000'.freeze

  # Creates a serializer for the given clip.
  #
  # @param clip [LiveAudioClip] the clip to be serialized
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
    text += "  #{warning_markdown}" unless @clip.messages.empty?
    text += "<br>`#{@clip.file}`" if @clip.file
    text += "  #{place_markdown}" if @clip.place
    text += "  #{size_markdown}" if @clip.file_size.positive?
    text
  end

  private

  # The warnings for a clip.
  #
  # A clip whose sample is not in the project is highlighted.
  #
  # @return [String] the messages for a clip
  #
  # TODO Extract the warning decoration to a method that can replace what LiveAssetsSerializer.MISSING is doing when
  # called by LiveAssetsSerializer#marker_of.
  def warning_markdown
    @clip.messages.map do |warning|
      LiveMarkup.code_span warning,
                           style: "background-color: #{NOT_COLLECTED_BACKGROUND}; " \
                                  "color: #{LiveMarkup::LIGHT_TEXT}; vertical-align:middle;"
    end.join ', '
  end

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

  # The place the clip is in.
  #
  # @return [String] the place
  def place_markdown
    @clip.place
  end

  # The size of the file the clip plays.
  #
  # @return [String] the size
  def size_markdown
    "#{ByteSize.new @clip.file_size} (#{@clip.file_size} bytes)"
  end
end
