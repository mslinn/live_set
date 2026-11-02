# The palette of colors that Live writes numbers of.
#
# Live writes the color of a track or a clip as a number, and the number is an index into the
# palette that Live's color menu holds. The palette can be changed by the user in the
# Preferences of Live, so the palette here is Live's default.
#
# The values are the ones of Live's color menu, in the order of the menu. They are taken from
# the `abletoolz` project, which reads them out of Live:
# https://github.com/elixirbeats/abletoolz/blob/main/abletoolz/live_set/colors.py
class LivePalette
  # The color of the text that is written on a color that looks dark.
  LIGHT = '#F0F0F0'.freeze

  # The colors of the palette, in the order of the menu.
  COLORS = %w[
    FF94A6 FFA428 CD9827 F6F57C BEFA00 21FF41 25FEA9 5DFFE9 8AC5FE 5480E4 93A6FF D86CE4 E552A1 FFFEFE
    FE3637 F66D02 99734A FEF134 87FF67 3DC201 01BEAF 18E9FE 10A4EE 007DC0 886CE4 B776C6 FE38D4 D1D0D1
    E3665A FEA274 D2AD70 EDFFAE D3E499 BAD175 9AC58D D4FCE0 CCF0F8 B8C1E2 CDBBE4 AF98E4 E5DDE0 A9A8A8
    C6938A B68257 98826A BEBB69 A6BE00 7CB04C 89C3BA 9BB3C4 84A5C3 8392CD A494B5 BF9FBE BD7096 7B7A7A
    AF3232 A95131 734E41 DAC200 84971F 529E31 0A9C8E 236285 1A2F96 2E52A3 624BAD A24AAD CD2E6F FFFEFE
  ].freeze

  # The icon that stands for each kind of track.
  ICONS = {
    'MIDI' => '🎹', 'Audio' => '🎵', 'Group' => '👥', 'Return' => '↩️', 'Master' => '🎚️'
  }.freeze

  class << self
    # The color of a number, as Live's palette holds it.
    #
    # @param value [Integer, String] the number Live writes
    # @return [String, nil] the color, as six hex digits, or nil when the number is not one
    #   of the palette
    def color_of(value)
      return nil if value.nil?

      COLORS[value.to_i]
    end

    # The icon of a kind of track.
    #
    # @param kind [String] the kind
    # @return [String] the icon
    def icon_of(kind)
      ICONS.fetch kind, '🎵'
    end

    # The style of a cell that is filled with the color of a number.
    #
    # @param value [Integer, String, nil] the number Live writes
    # @return [String, nil] the style, or nil when the number is not one of the palette
    def style_of(value)
      color = color_of value
      return nil unless color

      hex = "##{color}"
      "background-color:#{hex};color:#{text_color color}"
    end

    # The name of a thing, on the color of the thing.
    #
    # The name is written on the color, in a color that can be read against it, and the
    # number Live writes for the color is in the tooltip of the name.
    #
    # The style is on the code element and not on a span around it: a renderer that gives
    # code its own color would otherwise win, and the name would be unreadable on the color.
    #
    # A thing that Push 3 Standalone cannot use is written on the dark background of those
    # things instead of the color of the thing, and the name of it is in light text.
    #
    # @param name [String] the name
    # @param value [Integer, String, nil] the number Live writes for the color
    # @param dark [Boolean] true when the thing cannot be used on Push 3 Standalone
    # @return [String] the name
    def name_span(name, value = nil, dark: false)
      return %(<code style="background-color:#212121;color:#FFFFFF;vertical-align:middle">#{name}</code>) if dark

      color = color_of value
      return "<code>#{name}</code>" unless color

      hex = "##{color}"
      style = "background-color:#{hex};color:#{text_color color};vertical-align:middle"
      %(<code style="#{style}" title="color #{value}">#{name}</code>)
    end

    # The color of a number, as a cell that can be read.
    #
    # The number is written on the color, in a color that can be read against it.
    #
    # @param value [Integer, String, nil] the number Live writes
    # @return [String] the cell
    def swatch(value)
      return '' if value.nil?

      color = color_of value
      return value.to_s if color.nil?

      hex = "##{color}"
      style = "display:inline-block;min-width:2.5em;padding:0 .4em;background-color:#{hex};" \
              "color:#{text_color color};text-align:right"
      %(<code style="#{style}">#{value}</code>)
    end

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
