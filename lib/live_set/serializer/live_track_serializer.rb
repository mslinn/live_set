# TODO: This is a placeholder to start off the changes described as TODO comments in lib/live_set/live_palette.rb
# TODO Write unit tests
#
require_relative '../../common/log'
require_relative '../live_palette'
require_relative 'live_clip_serializer'
require_relative 'live_device_serializer'
#
# Serializes a LiveTrack model as markdown by serializing each member.
#
# It also owns the formatting of the report: the icons of the kinds of track, and the way a
# name is written on the colour it is written on. The palette holds the colours of Live and
# nothing else, and the caller says which colour the text is written on.
#
# Sample usage:
# track = LiveTrack.new(...)
# markdown = LiveTrackSerializer.new(track).to_markdown
class LiveTrackSerializer
  # The background a thing that Push 3 Standalone cannot use is written on.
  DARK_BACKGROUND = '#212121'.freeze

  # The color the text on a dark background is written in.
  LIGHT_TEXT = '#FFFFFF'.freeze

  # Hash from track type to track icon.
  #
  # Live 12 renamed the master track to the main track, and it is the same thing, so it has
  # the same icon.
  TRACK_TYPE_ICONS = {
    'Audio'  => '🎵',
    'Group'  => '👥',
    'Main'   => '🎚️',
    'Master' => '🎚️',
    'MIDI'   => '🎹',
    'Return' => '↩️',
  }.freeze

  class << self
    # The icon of a kind of track.
    #
    # A kind of track that is not in the map is a kind that a version of Live has written
    # that this program does not know about, and it is reported.
    #
    # @param track_type [String] the kind of track
    # @return [String] the icon, or a bomb for a kind that is not in the map
    def icon_for(track_type)
      return TRACK_TYPE_ICONS[track_type] if TRACK_TYPE_ICONS.key?(track_type)

      Log.warn("Unexpected track type: #{track_type.inspect}")
      '💣'
    end

    # The name of a thing, on the colour it is written on.
    #
    # The style is on the code element and not on a span around it: a renderer that gives
    # code its own color would otherwise win, and the name would be unreadable on the
    # colour.
    #
    # The number Live writes for the colour is in the tooltip of the name, when there is
    # one.
    #
    # @param text [String] the name, already escaped
    # @param color_number [Integer, String, nil] the number Live writes for the colour
    # @param background_color [String, nil] the colour the name is written on
    # @param foreground_color [String, nil] the colour the name is written in
    # @return [String] the name, on its colour
    def colored_code(text, color_number: nil, background_color: nil, foreground_color: nil)
      return "<code>#{text}</code>" unless background_color

      style = "background-color: #{background_color}; color: #{foreground_color}; vertical-align: middle"
      title = color_number ? %( title="Live color ##{color_number}") : ''
      %(<code style="#{style}"#{title}>#{text}</code>)
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

    # The number Live writes for a colour, in a cell filled with that colour.
    #
    # @param value [Integer, String, nil] the number Live writes
    # @param background_color [String, nil] the colour the cell is filled with
    # @param foreground_color [String, nil] the colour the number is written in
    # @return [String] the cell
    def swatch(value, background_color: nil, foreground_color: nil)
      return '' if value.nil?
      return value.to_s unless background_color

      style = 'display: inline-block; min-width: 2.5em; padding: 0 .4em; ' \
              "background-color: #{background_color}; color: #{foreground_color}; text-align: right"
      %(<code style="#{style}">#{value}</code>)
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

    # The name of a thing, as the report writes it.
    #
    # The name the user typed is the name of the thing. When there is none, the name Live
    # resolved is the name, without the number Live gives the things that share a name.
    #
    # @param thing [LiveTrack, LiveGroup] the thing
    # @return [String] the name
    def display_name(thing)
      user_name = thing.user_name
      return user_name unless user_name.nil? || user_name.empty?

      thing.name.sub(/\A\d+[- ]/, '')
    end

    # The characters of a name that would break a table.
    #
    # @param text [String] the text
    # @return [String] the text, escaped
    def escape(text)
      text.to_s.gsub('|', '&#124;')
    end

    # How bright a colour looks.
    #
    # The brightness is the weighted sum of the three channels, the way the eye weighs them:
    # green counts the most, and blue the least.
    #
    # @param color [String] the colour, as six hex digits
    # @return [Float] the brightness, from 0 to 255
    def brightness(color)
      red = color[0, 2].to_i(16)
      green = color[2, 2].to_i(16)
      blue = color[4, 2].to_i(16)
      (0.299 * red) + (0.587 * green) + (0.114 * blue)
    end

    # The CSS for a table cell filled with a colour.
    #
    # @param background_color [String, nil] the colour the cell is filled with
    # @param foreground_color [String, nil] the colour the number is written in
    # @return [String, nil] the style, or nil when there is no colour
    def style_of(background_color: nil, foreground_color: nil)
      return nil unless background_color

      "background-color:#{background_color};color:#{foreground_color}"
    end
  end

  # Creates a serializer for the given track.
  #
  # @param track [LiveTrack] the track to serialize
  # @param hierarchical_number [String] the number of the track in the report
  # @param indent [String] the indentation of the lines of the track
  def initialize(track, hierarchical_number, indent = '')
    @track = track
    @hierarchical_number = hierarchical_number
    @indent = indent
  end

  # Returns the track as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = [track_line]
    lines += device_lines
    lines += clip_lines
    lines += take_lane_lines
    lines.join "\n"
  end

  private

  # The line of the track: its number, its icon, its kind, its name and its state.
  #
  # @return [String] the line
  def track_line
    states = states_of @track
    name = LiveTrackSerializer.display_name @track
    line = "#{@indent}- Track #{@hierarchical_number}  #{TRACK_TYPE_ICONS[@track.kind]} #{@track.kind}  " \
           "#{name_markdown(name)}"
    line += "  #{states.join(', ')}" unless states.empty?
    line
  end

  # The name of the track, on the colour Live gave it.
  #
  # A track that Push 3 Standalone cannot use is written on the dark background of those
  # things, and the name of it is in light text.
  #
  # @return [String] the name of the track
  def name_markdown(name)
    if problem?
      return LiveTrackSerializer.colored_code LiveTrackSerializer.escape(name),
                                              background_color: DARK_BACKGROUND,
                                              foreground_color: LIGHT_TEXT
    end

    color = LivePalette.color_of @track.color
    return "<code>#{LiveTrackSerializer.escape name}</code>" unless color

    LiveTrackSerializer.colored_code LiveTrackSerializer.escape(name),
                                     color_number:     @track.color,
                                     background_color: "##{color}",
                                     foreground_color: LiveTrackSerializer.text_color(color)
  end

  # The state of the track.
  #
  # @param track [LiveTrack] the track
  # @return [Array<String>] the marks
  def states_of(track)
    states = []
    states << "\u{1F976} frozen" if track.frozen?
    states << "\u{1F142} solo" if track.soloed?
    states << '🔴 armed' if track.armed?
    states << "\u{23FD} off" if track.off?
    states << "linked group #{track.linked_group}" if track.linked_group
    states
  end

  # Whether the track cannot be transferred to Push 3 Standalone.
  #
  # @return [Boolean] true when the track is a problem
  def problem?
    @track.problem?
  end

  # The lines of the devices of the track.
  #
  # @return [Array<String>] the lines
  def device_lines
    @track.devices.each_with_index.map do |device, index|
      letter = ('a'.ord + index).chr
      number = "#{@hierarchical_number}#{letter}"
      serializer = LiveDeviceSerializer.new device, number, track_frozen: @track.frozen?
      "#{@indent}  - #{slot_label} #{number}  #{serializer.to_markdown}"
    end
  end

  # The name of the devices of a kind of track.
  #
  # @return [String] the name
  def slot_label
    @track.group? ? 'Group Track Device' : 'Track Device'
  end

  # The lines of the clips of the track.
  #
  # @return [Array<String>] the lines
  def clip_lines
    LiveClipGroups.new(@track.clips).to_markdown(@hierarchical_number).map { |line| "#{@indent}  #{line}" }
  end

  # The lines of the take lanes of the track.
  #
  # @return [Array<String>] the lines
  def take_lane_lines
    return [] if @track.take_lanes.empty?

    serializer = LiveTakeLanesSerializer.new @track.take_lanes, @hierarchical_number, "#{@indent}  "
    serializer.to_markdown.split("\n")
  end
end
