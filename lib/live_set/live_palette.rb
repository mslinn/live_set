require 'paleta'

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
  # The least contrast the WCAG asks for of text of the size of the names in a report.
  MINIMUM_CONTRAST = 4.5

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
    # A thing that Push 3 Standalone cannot use is written on the dark background of those
    # things instead of the color of the thing, and the name of it is in light text.
    #
    # @param name [String] the name
    # @param value [Integer, String, nil] the number Live writes for the color
    # @param dark [Boolean] true when the thing cannot be used on Push 3 Standalone
    # @return [String] the name
    def name_span(name, value = nil, dark: false)
      return %(<span style="background-color:#212121;color:#FFFFFF"><code>#{name}</code></span>) if dark

      color = color_of value
      return "<code>#{name}</code>" unless color

      hex = "##{color}"
      style = "background-color:#{hex};color:#{text_color color}"
      %(<span style="#{style}" title="color #{value}"><code>#{name}</code></span>)
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
      %(<span style="#{style}">#{value}</span>)
    end

    # The color of the text that is written on a color.
    #
    # The text is the complementary color of the background — the color on the other side of
    # the wheel — and it is made as dark as it has to be, or as light, to be read on the
    # background. The contrast ratio of the two decides, and the WCAG asks for 4.5 to 1 for
    # text of this size.
    #
    # A few colors have no complementary color that can be read on them, and the text on those
    # is black or white, whichever has the higher ratio.
    #
    # @param color [String] the color, as six hex digits
    # @return [String] the color of the text
    def text_color(color)
      background = Paleta::Color.new(:hex, color)
      complement = background.complement

      candidates = [darkened_text(background, complement), lightened_text(background, complement)]
      candidates.select! { |candidate| contrast(hex_of(candidate), color) >= MINIMUM_CONTRAST }
      return hex_of(candidates.max_by { |candidate| contrast(hex_of(candidate), color) }) unless candidates.empty?

      luminance = luminance_of color
      on_black = (luminance + 0.05) / 0.05
      on_white = 1.05 / (luminance + 0.05)
      on_black >= on_white ? '#000000' : '#FFFFFF'
    end

    # The hex of a color, with the hash that a style needs.
    #
    # @param color [Paleta::Color] the color
    # @return [String] the hex
    def hex_of(color)
      hex = color.hex
      hex.start_with?('#') ? hex : "##{hex}"
    end

    # The complementary color, made as dark as it has to be to be read on the background.
    #
    # @param background [Paleta::Color] the background
    # @param text [Paleta::Color] the complementary color
    # @return [Paleta::Color] the text
    def darkened_text(background, text)
      20.times do
        break if contrast(hex_of(text), hex_of(background)) >= MINIMUM_CONTRAST
        break if text.lightness <= 0

        text = text.darken 10
      end
      text
    end

    # The complementary color, made as light as it has to be to be read on the background.
    #
    # @param background [Paleta::Color] the background
    # @param text [Paleta::Color] the complementary color
    # @return [Paleta::Color] the text
    def lightened_text(background, text)
      20.times do
        break if contrast(hex_of(text), hex_of(background)) >= MINIMUM_CONTRAST
        break if text.lightness >= 100

        text = text.lighten 10
      end
      text
    end

    # The contrast ratio of two colors.
    #
    # @param one [String] a color, as six hex digits
    # @param other [String] a color, as six hex digits
    # @return [Float] the ratio
    def contrast(one, other)
      first = luminance_of one
      second = luminance_of other
      lighter, darker = first > second ? [first, second] : [second, first]
      (lighter + 0.05) / (darker + 0.05)
    end

    # The relative luminance of a color.
    #
    # @param color [String] the color, as six hex digits
    # @return [Float] the luminance
    def luminance_of(color)
      digits = color.delete_prefix('#')
      red = channel digits[0, 2]
      green = channel digits[2, 2]
      blue = channel digits[4, 2]
      (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
    end

    # One channel of a color, as the relative luminance of it.
    #
    # @param value [String] the channel, as two hex digits
    # @return [Float] the luminance of the channel
    def channel(value)
      part = value.to_i(16) / 255.0
      part <= 0.03928 ? part / 12.92 : (((part + 0.055) / 1.055)**2.4)
    end
  end
end
