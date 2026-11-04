# TODO: This is a placeholder to start off the changes described as TODO comments in lib/live_set/live_palette.rb
# TODO Write unit tests
#
require_relative '../../common/log'
require_relative '../live_palette'
require_relative 'live_clip_reference_serializer'
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
  def initialize(track, hierarchical_number)
    @track = track
    @hierarchical_number = hierarchical_number
  end

  # Returns the track as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    # TODO: finish writing me.

    # Serialize clip references associated with a track. Similar code needs to be
    # written for take lanes and arrangement view:
    clips_markdown = @track.clip_references.map do |clip_reference|
      LiveClipReferenceSerializer.new(clip_reference).to_markdown
    end.join("\n")

    # Serialize devices associated with a track
    track_devices_markdown = @track.clip_references.map do |track|
      LiveDeviceSerializer.new(track.devices).to_markdown
    end.join("\n")

    # TODO: include header line, e.g.: Track 1.1 🎹 MIDI Kontakt 7
    <<~END_MARKDOWN
      #{group_track_devices_markdown}
      #{track_devices_markdown}
      #{clips_markdown}
    END_MARKDOWN
  end
end
