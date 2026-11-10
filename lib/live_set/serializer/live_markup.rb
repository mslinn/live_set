require 'cgi'
require_relative '../../common/log'
require_relative '../model/live_palette'

# This module generates markup for `als_report`.
#
module LiveMarkup
  # The background color for text associated with P3S Standalone incompatibility.
  DARK_BACKGROUND = '#212121'.freeze
  LIGHT_TEXT      = '#FFFFFF'.freeze

  # The background color of a warning.
  WARNING_BACKGROUND = '#8B0000'.freeze

  # Hash from track type to track icon.
  #
  # Live 12 renamed the master track to the main track, and it is the same thing, so it has the same icon.
  TRACK_TYPE_ICONS = {
    'Audio'  => '🎵',
    'Group'  => '👥',
    'Main'   => '🎚️',
    'Master' => '🎚️',
    'MIDI'   => '🎹',
    'Return' => '↩️',
  }.freeze

  # The indentation of one level of the outline.
  #
  # Four spaces, so that the content of a list item is indented far enough for a renderer to
  # take it for the content of the item and not for a list of its own.
  INDENT = '    '.freeze

  class << self
    # Returns an icon denoting the type of track it was passed.
    #
    # If a track is not recognized, then this a programming error, and it is reported.
    #
    # @param track_type [String] the kind of the track @return [String] the icon, or a bomb for a track type that is not
    # in the map
    def icon_for(track_type)
      return TRACK_TYPE_ICONS[track_type] if TRACK_TYPE_ICONS.key?(track_type)

      Log.warn("Unexpected track type: #{track_type.inspect}")
      '💣'
    end

    # The indentation of a thing with the given number in the report.
    #
    # The number of a thing says how deep it is: "1" is a track at the top of the set, "1.1"
    # is a child of it, and "1a" — a device of the track "1" — is a child of it too. The
    # indent is derived from the number, so that the number of a thing and the place of it in
    # the outline can never disagree.
    #
    # @param number [String] the number of the thing in the report
    # @return [String] the indentation
    def indent_for(number)
      INDENT * (levels_of(number) - 1)
    end

    # The number of levels of a thing with the given number in the report.
    #
    # @param number [String] the number of the thing in the report
    # @return [Integer] the number of levels
    def levels_of(number)
      parts = number.to_s.split('.')
      parts.last.match?(/[a-z]\z/) ? parts.length + 1 : parts.length
    end

    # The name of a thing, on the colour it is written on.
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
    # A warning is written on the dark background of the things that cannot be used, and in
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

    # The number Live writes for a colour, in a cell filled with that colour.
    #
    # @param value [Integer, String, nil] the number Live writes
    # @param background_color [String, nil] the colour the cell is filled with
    # @param foreground_color [String, nil] the colour the number is written in
    # @return [String] the cell
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

    # The colour the text on a colour is written in.
    #
    # Black is written on a colour that looks light, and white on a colour that looks dark.
    #
    # @param color [String] the colour, as six hex digits
    # @return [String] the colour of the text
    def text_color(color)
      brightness(color) > 128 ? '#000000' : LIGHT_TEXT
    end

    # A number, as the default locale writes it.
    #
    # Ruby does not format numbers by locale, so the grouping of the default locale is
    # written here: the thousands separator of US English.
    #
    # @param value [Integer] the number
    # @return [String] the number, with its thousands separated
    def number(value)
      value.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
    end

    # The characters of a name that would break a table, or the markup around it.
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

    # The CSS for a table cell filled with a colour.
    #
    # @param background_color [String, nil] the colour the cell is filled with
    # @param foreground_color [String, nil] the colour the number is written in
    # @return [String, nil] the style, or nil when there is no colour
    def style_of(background_color: nil, foreground_color: nil)
      return nil unless background_color

      "background-color: #{background_color}; color: #{foreground_color}"
    end

    # track detail: its number, its icon, its kind, its name and its state.
    #
    # The indentation of the line comes from the number of the track, so that the number and
    # the place of the track in the outline always agree.
    #
    # @param track [LiveMidiTrack, LiveAudioTrack, LiveReturnTrack, LiveMasterTrack] the track
    # @param number [String] the number of the track in the report
    # @return [String] the line
    def track_detail(track, number)
      states = states_of(track)
      name = track.display_name
      states_suffix = states.empty? ? '' : "  #{states.join(', ')}"

      "#{indent_for(number)}- Track #{number}  #{icon_for(track.kind)} #{track.kind}  " \
        "#{track_name_markdown(track, name)}#{states_suffix}"
    end

    # colored code containing the track name, using the color from the Live set.
    #
    # A track that is incompatible with the P3S Standalone is highlighted.
    #
    # The name of a track in a table cell does not break across lines, which is what the
    # `nobr` element is for. Only the name of a track that has a colour is wrapped.
    #
    # @param track [LiveMidiTrack, LiveAudioTrack, LiveReturnTrack, LiveMasterTrack] the track
    # @param name [String] the name of the track
    # @param in_a_cell [Boolean] true when the name is written in a table cell
    # @return [String] the name of the track
    def track_name_markdown(track, name, in_a_cell: false)
      if track.problem?
        # TODO: surface this to a configurable parameter driven from a default style sheet.
        return colored_code escape(name),
                            background_color: DARK_BACKGROUND,
                            foreground_color: LIGHT_TEXT
      end

      color = LivePalette.color_of track.color
      return "<code>#{escape name}</code>" unless color

      label = colored_code escape(name),
                           color_number:     track.color,
                           background_color: "##{color}",
                           foreground_color: text_color(color)
      return label unless in_a_cell

      "<nobr>#{label}</nobr>"
    end

    # The complete state of a track.
    #
    # Ableton Live does not display a small icon to denote a frozen track. Instead, it indicates a frozen track by
    # turning the frozen clips and devices a light/icy blue colour.
    #
    # Ableton Live displays the Solo button for a track by the letter S without a background set.
    # See `../assets/images/live_*_button*.png`
    # • When the track is soloed it gets a blue background.
    # • Half Blue / Half White: A half-blue and half-white S button indicates that a sub-track or a device chain
    #   inside a group track is soloed rather than the main track itself.
    #
    # @param track [LiveMidiTrack, LiveAudioTrack, LiveReturnTrack, LiveMasterTrack] the track
    # @return [Array<String>] the track states (frozen, solo, armed, off, linked group)
    def states_of(track)
      states = []
      states << "\u{1F976} frozen" if track.frozen?
      if track.soloed?
        # TODO: this needs a stylesheet in Markdown (preferred, but perhaps not possible) or in Ruby
        colors = colored_code('solo', background_color: '#0066cc', foreground_color: 'white')
        states << "\u{1F142} #{colors}"
      end
      states << '🔴 armed' if track.armed?
      states << "\u{23FD} off" if track.off?
      states << "linked group #{track.linked_group}" if track.linked_group
      states
    end
  end
end
