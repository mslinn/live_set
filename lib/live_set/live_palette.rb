# The default Live color palette.
#
# Live writes the color of a track or a clip as a number, and the number is an index into the default Live color palette.
#
class LivePalette
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

  class << self
    # @param value [Integer, String] the Live color number, expressed as a string or an int
    # @return [String, nil] the color, as six hex digits, or nil when the number
    #   is not in the palette
    def color_of(value)
      index = value.is_a?(String) ? Integer(value, 10) : value
      return unless index.is_a?(Integer) && index.between?(0, COLORS.length - 1)

      COLORS[index]
    end
  end
end
