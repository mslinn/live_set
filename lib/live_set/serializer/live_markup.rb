require 'cgi'

# This module generates markup for `als_report`.
#
module LiveMarkup
  # The background color for text associated with P3S Standalone incompatibility.
  DARK_BACKGROUND = '#212121'.freeze
  LIGHT_TEXT      = '#FFFFFF'.freeze

  # The background color of a warning.
  WARNING_BACKGROUND = '#8B0000'.freeze

  # The indentation of one level of the outline.
  #
  # Two spaces, the width of the list marker, so that the content of a list item is indented
  # far enough for a renderer to take it for the content of the item and not for a list of
  # its own.
  INDENT = '  '.freeze

  class << self
    # Return a string containing colored HTML code tags with embedded text.
    #
    # The style is applied to the <code> element and not on a <span around the element>.
    #
    # The Live track number is included in the tooltip when possible.
    #
    # @param text [String] the name, already escaped
    # @param color_number [Integer, String, nil] the number Live writes for the colour
    # @param background_color [String, nil] the colour the name is written on
    # @param foreground_color [String, nil] the colour the name is written in
    # @return [String] the name, on its colour
    def colored_code(text, color_number: nil, background_color: nil, foreground_color: nil)
      return "<code>#{text}</code>" unless background_color

      styles = [
        ("color: #{foreground_color}" if foreground_color),
        "background-color: #{background_color}",
        'vertical-align: middle'
      ].compact
      style = CGI.escapeHTML("#{styles.join('; ')};")
      title = %( title="Live color ##{color_number}") if color_number

      "<code style=\"#{style}\"#{title}>#{text}</code>"
    end

    # The text, in code type.
    #
    # @param text [String] the text to wrap
    # @param style [String, nil] CSS declarations for the tag
    # @param title [String, nil] the tooltip text
    # @return [String] the styled code tag
    def code_span(text, style: nil, title: nil)
      attributes = []
      attributes << %(style="#{style}") if style
      attributes << %(title="#{title}") if title
      opening_tag = attributes.empty? ? '<code>' : "<code #{attributes.join(' ')}>"

      %(#{opening_tag}#{text}</code>)
    end

    # A warning, in a span of its own.
    #
    # A warning is written on the dark background of the nodes that cannot be used, and in
    # light text, so that a reader sees it in the report. The decoration of a warning is
    # made in one place, and every warning is written with it: the warning of a clip, and the
    # marker of a sample.
    #
    # @param message [String] the message
    # @return [String] the message, decorated
    def warning_span(message)
      code_span message,
                style: "background-color: #{WARNING_BACKGROUND}; " \
                       "color: #{LIGHT_TEXT}; vertical-align:middle;"
    end

    # Return a string containing colored HTML code tags with embedded text and CSS so it completely fills its
    # container. Originally written to fill table cells.
    #
    # The number Live writes for a colour, in a cell filled with that colour.
    #
    # @param value [Integer, String, nil] the number Live writes @param background_color [String, nil] the colour the
    # cell is filled with @param foreground_color [String, nil] the colour the number is written in @return [String] the
    # cell
    def swatch(value, background_color: nil, foreground_color: nil)
      return '' if value.nil?

      escaped_value = CGI.escapeHTML(value.to_s)
      return escaped_value unless background_color

      styles = [
        'display: inline-block',
        'min-width: 2.5em',
        'padding: 0 .4em',
        ("color: #{foreground_color}" if foreground_color),
        "background-color: #{background_color}",
        'text-align: right'
      ].compact

      style = CGI.escapeHTML("#{styles.join('; ')};")
      "<code style=\"#{style}\">#{escaped_value}</code>"
    end

    # Return colour the text on a background colour is written in.
    #
    # Black text is written on a lignt background colour, and white text on a colour that looks dark.
    #
    # @param background_color [String] the colour, as six hex digits
    # @return [String] the colour of the text
    def text_color(background_color)
      brightness(background_color) > 128 ? '#000000' : LIGHT_TEXT
    end

    # Escape the characters of a name that would break a table, or the markup around it.
    #
    # The text is escaped for HTML, and the pipe is escaped as well, because a pipe in a
    # name would break the table the name is written in.
    #
    # @param text [String] the text
    # @return [String] the text, escaped
    def escape(text)
      CGI.escapeHTML(text.to_s).gsub('|', '&#124;')
    end

    # How bright a colour looks.
    #
    # The brightness is the weighted sum of the three channels, the way the eye weighs them:
    # green counts the most, and blue the least.
    #
    # @param color [String] the colour, as six hex digits
    # @return [Float] the brightness, from 0 to 255
    def brightness(color)
      red   = color[0, 2].to_i(16)
      green = color[2, 2].to_i(16)
      blue  = color[4, 2].to_i(16)
      (0.299 * red) + (0.587 * green) + (0.114 * blue)
    end
  end
end
