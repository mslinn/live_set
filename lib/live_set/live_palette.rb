# The default Live color palette.
#
# Live writes the color of a track or a clip as a number, and the number is an index into the default Live color palette.

class LivePalette
  # TODO: delete this stupid idea
  # Text color written on a dark background color.
  LIGHT = '#F0F0F0'.freeze

  # The default Live color palette, presented in the order of the Live drop down color menu. Taken from the `abletoolz`
  # project, which reads them out of Live:
  # https://github.com/elixirbeats/abletoolz/blob/master/abletoolz/live_set/colors.py
  COLORS = %w[
    FF94A6 FFA428 CD9827 F6F57C BEFA00 21FF41 25FEA9 5DFFE9 8AC5FE 5480E4 93A6FF D86CE4 E552A1 FFFEFE
    FE3637 F66D02 99734A FEF134 87FF67 3DC201 01BEAF 18E9FE 10A4EE 007DC0 886CE4 B776C6 FE38D4 D1D0D1
    E3665A FEA274 D2AD70 EDFFAE D3E499 BAD175 9AC58D D4FCE0 CCF0F8 B8C1E2 CDBBE4 AF98E4 E5DDE0 A9A8A8
    C6938A B68257 98826A BEBB69 A6BE00 7CB04C 89C3BA 9BB3C4 84A5C3 8392CD A494B5 BF9FBE BD7096 7B7A7A
    AF3232 A95131 734E41 DAC200 84971F 529E31 0A9C8E 236285 1A2F96 2E52A3 624BAD A24AAD CD2E6F FFFEFE
  ].freeze

  # Hash from track type to track icon.
  #
  # TODO Move to a new LiveTrackSerializer class
  # TODO rename to TRACK_TYPE_ICONS
  ICONS = {
    'Audio'  => '🎵',
    'Group'  => '👥',
    'Master' => '🎚️',
    'MIDI'   => '🎹',
    'Return' => '↩️',
  }.freeze

  class << self
    # @param value [Integer, String] the Live color number, expressed as a string or an int
    # @return [String, nil] the color, as six hex digits, or nil when the number
    #   is not in the palette
    def color_of(value)
      index = value.is_a?(String) ? Integer(value, 10) : value
      return unless index.is_a?(Integer) && index.between?(0, COLORS.length - 1)

      COLORS[index]
    end

    # TODO: rename to icon_for
    #
    # TODO Move to LiveTrackSerializer class. a serializer object initialized with a model instance. This keeps the
    # model focused on representing the XML entity, while the serializer owns XML formatting, escaping, namespaces, and
    # output rules. Keep serializers small and cohesive. If several XML entity serializers share behavior,
    # extract that behavior into a helper or a focused module. Avoid mixing serializer methods into models just for
    # testability; testability is better served by isolating the serializer and testing its output directly. Use model
    # methods when serialization is truly intrinsic to the model and there is one stable representation.
    #
    # TODO **Additional serializer classes are expected. Dialog with the user and get approval for each one.**
    #
    # Returns the icon for a known track type.  Logs unexpected values and returns a bomb icon for them.
    #
    # @param track_type [String] the track type, which should be present in TRACK_TYPE_ICONS @return [String] the track
    # icon, or a bomb icon for an unknown type
    def icon_of(track_type)
      return ICONS[track_type] if ICONS.key?(track_type)

      Log.warn("Unexpected track type: #{track_type.inspect}")
      '💣'
    end

    # @return CSS for a Markdown table cell filled with the Live palette color.
    #
    # @param value [Integer, String, nil] the number Live writes
    # @return [String, nil] the style, or nil when the number is not in the palette
    def style_of(value)
      color = color_of(value)
      return unless color

      "background-color:##{color};color:#{text_color(color)}"
    end

    # TODO: rename to colored_code
    #
    # TODO Move to LiveTrackSerializer class
    #
    # Applies a CSS style to a <code/> tag for good legibility.
    #
    # Tries and fails to select a background color based on a foreground color.
    # TODO: add a new parameter for background_color so proper colors can be specified.
    #
    # The Live color number is displayed the HTML tooltip.
    #
    # Strings containing a message that indicates incompatibility with Push 3 Standalone are written with a special CSS
    # style.
    #
    # Text incompatible with Push 3 Standalone is shown on a dark background
    # with light text.
    #
    # @param string [String] the string to colorize
    # @param color_number [Integer, String, nil] the Live color number
    # @param p3s_incompatible [Boolean] flag indicating the string warns the user that something cannot be used with Push 3 Standalone
    # @return [String] the colorized string, wrapped in a <code/> tag
    def name_span(string, color_number = nil, p3s_incompatible: false)
      if p3s_incompatible
        return code_span(
          string,
          style: 'background-color:#212121; color:#FFFFFF; vertical-align:middle'
        )
      end

      color = color_of(color_number)
      return code_span(string) unless color

      style = "background-color: ##{color}; color: #{text_color(color)}; vertical-align: middle"
      code_span(string, style: style, title: "Live color ##{color_number}")
    end

    # TODO: Move to LiveTrackSerializer class
    # Applies a readable background and foreground color to a <code> tag.
    #
    # @param string [String] the text to wrap
    # @param style [String, nil] CSS declarations for the tag
    # @param title [String, nil] the tooltip text
    # @return [String] the styled <code> tag
    def code_span(string, style: nil, title: nil)
      attributes = []
      attributes << %(style="#{style}") if style
      attributes << %(title="#{title}") if title
      opening_tag = attributes.empty? ? '<code>' : "<code #{attributes.join(' ')}>"

      %(#{opening_tag}#{string}</code>)
    end

    # TODO: Move to LiveTrackSerializer class
    #
    # Returns a colorized HTML table cell that displays the Ableton Live color number in
    # a cell with background color set to that value.
    #
    # TODO add another parameter for background color instead of attempting to compute it
    #
    # @param value [Integer, String, nil] the number Live writes
    # @return [String] the cell
    def swatch(value)
      return '' if value.nil?

      color = color_of value
      return value.to_s if color.nil?

      hex = "##{color}"
      style = "display: inline-block; min-width: 2.5em; padding: 0 .4em; background-color: #{hex};" \
              "color: #{text_color color}; text-align: right"
      %(<code style="#{style}">#{value}</code>)
    end

    # TODO: Delete this stupid idea
    #
    # The color of the text that is written on a color.
    #
    # How bright the color looks decides: black is written on a color that looks light, and
    # a light grey on a color that looks dark. The light grey is easier on the eye than
    # white, on a color as loud as the reds and the blues of Live's palette.
    #
    # @param color [String] the color, as six hex digits
    # @return [String] the color of the text
    def text_color(color)
      brightness(color) > 128 ? '#000000' : LIGHT
    end

    # TODO: Delete this stupid idea
    #
    # How bright a color looks.
    #
    # The brightness is the weighted sum of the three channels, the way the eye weighs them:
    # green counts the most, and blue the least.
    #
    # @param color [String] the color, as six hex digits
    # @return [Float] the brightness, from 0 to 255
    def brightness(color)
      digits = color.delete_prefix('#')
      red = digits[0, 2].to_i(16)
      green = digits[2, 2].to_i(16)
      blue = digits[4, 2].to_i(16)
      (0.299 * red) + (0.587 * green) + (0.114 * blue)
    end
  end
end
