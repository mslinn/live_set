require_relative '../model/live_palette'
require_relative 'live_markup'

# The markdown of a track.
#
# The line of a track is the same for every kind of track: its number, its icon, its kind,
# its name and its state. The name of a track is written on the colour Live gave it, and
# the states of a track are the icons and the words that say what the track is doing.
#
# The methods are here, and not in `LiveMarkup`, because they are about tracks and not
# about markup in general.
module LiveTrackMarkup
  # The line of a track: its number, its icon, its kind, its name and its state.
  #
  # The indentation of the line comes from the number of the track, so that the number and
  # the place of the track in the outline always agree.
  #
  # @param track [LiveMidiTrack, LiveAudioTrack, LiveReturnTrack, LiveMasterTrack] the track
  # @param number [HierarchicalNumber] the number of the track in the report
  # @return [String] the line
  def track_detail(track, number)
    "#{number.indent_for(LiveMarkup::INDENT)}- #{track_text(track, number)}"
  end

  # The text of a track: its number, its icon, its kind, its name and its state.
  #
  # @param track [LiveMidiTrack, LiveAudioTrack, LiveReturnTrack, LiveMasterTrack] the track
  # @param number [HierarchicalNumber] the number of the track in the report
  # @return [String] the text
  def track_text(track, number)
    states = full_status(track)
    name = track.display_name
    states_suffix = states.empty? ? '' : "  #{states.join(', ')}"

    "Track #{number}  #{track.icon} #{track.kind}  #{track_name_markdown(track, name)}#{states_suffix}"
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
      return LiveMarkup.colored_code LiveMarkup.escape(name),
                                     background_color: LiveMarkup::DARK_BACKGROUND,
                                     foreground_color: LiveMarkup::LIGHT_TEXT
    end

    color = LivePalette.color_of track.color
    return "<code>#{LiveMarkup.escape name}</code>" unless color

    label = LiveMarkup.colored_code LiveMarkup.escape(name),
                                    color_number:     track.color,
                                    background_color: "##{color}",
                                    foreground_color: LiveMarkup.text_color(color)
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
  def full_status(track)
    states = []
    states << "\u{1F976} frozen" if track.frozen?
    if track.soloed?
      # TODO: this needs a stylesheet in Markdown (preferred, but perhaps not possible) or in Ruby
      colors = LiveMarkup.colored_code('solo', background_color: '#0066cc', foreground_color: 'white')
      states << "\u{1F142} #{colors}"
    end
    states << '🔴 armed' if track.armed?
    states << "\u{23FD} off" if track.off?
    states << "linked group #{track.linked_group}" if track.linked_group
    states
  end
end
