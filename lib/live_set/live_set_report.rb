require 'markdown-tables'
require 'socket'
require 'time'
require_relative '../common/log'
require_relative '../common/xml'
require_relative 'live_palette'
require_relative 'model/header_block'
require_relative 'model/live_clips'
require_relative 'model/live_devices'
require_relative 'model/live_device'
require_relative 'model/live_samples'
require_relative 'serializer/als_model_serializer'
require_relative 'serializer/device_cross_reference_serializer'
require_relative 'serializer/live_device_serializer'
require_relative 'serializer/live_group_serializer'
require_relative 'serializer/live_samples_serializer'
require_relative 'serializer/live_track_serializer'
require_relative 'serializer/missing_samples_serializer'
require_relative 'serializer/p3s_compatibility'
require_relative 'serializer/report_header_serializer'
require_relative 'serializer/track_clip_cross_reference_serializer'

# Generates a report of a set in markdown.
#
# The report describes every important element in an ALS file. The report is
# written in markdown, so it can be read in a text editor, and it can be
# converted to HTML or PDF for printing.
#
# ## Report Organization
#
# TODO create classes: HeaderBlock, P3SCompatible, LiveClip, LiveClipReference, LiveClipSettings,
# LiveDevice, LiveSample, MissingSamples. Some of the functionality in this
# file belongs in those classes.
#
# ```text
# Header block
# Push 3 Standalone compatibility
# LiveGroup
#   LiveTrack & devices
#     TakeLanes & ClipReferences
#     ClipReferences & devices
# Missing samples
# Device / track cross reference
# Track / clip cross reference
# ```

# ## Report Content
#
# The report of a set is written for a person to read, and it is checked in, so
# that what a set holds is written down where it can be read again.
#
# The colour of a track, a group and a clip is the background of its name, and
# the name of the colour Live writes for it is in the tooltip of the name. The
# text on the colour is black or white, and how bright the colour looks decides
# which of the two is written on it. A track, a group and a device that Push 3
# Standalone cannot use is written on the dark background of those things
# instead.
class LiveSetReport
  include Xml

  # The kinds of track, and the element that holds each of them.
  KINDS = {
    'MidiTrack' => 'MIDI', 'AudioTrack' => 'Audio', 'GroupTrack' => 'Group',
    'ReturnTrack' => 'Return', 'MasterTrack' => 'Master', 'MainTrack' => 'Main'
  }.freeze

  # The ways a clip can be launched.
  LAUNCH_MODES = { 0 => 'trigger', 1 => 'toggle', 2 => 'gate' }.freeze

  # The background a thing that Push 3 Standalone cannot use is written on.
  DARK_BACKGROUND = '#212121'.freeze

  # The color the text on a dark background is written in.
  LIGHT_TEXT = '#FFFFFF'.freeze

  # The warp modes of a sample, in the order of the manual.
  #
  # The number Live writes for the mode is the number of the mode in the manual:
  # Beats, Tones, Texture, Re-Pitch, Complex, and, in Live 12, Complex Pro.
  #
  # See "Warp Modes" in the manual of Live 12, section 9.3:
  # https://www.ableton.com/en/live-manual/12/audio-clips-tempo-and-warping/#warp-modes
  WARP_MODES = {
    0 => 'Beats', 1 => 'Tones', 2 => 'Texture', 3 => 'Re-Pitch', 4 => 'Complex', 5 => 'Complex Pro'
  }.freeze

  # The folders the content of a pack is in.
  CONTENT_FOLDERS = %w[Samples Sounds IRs Devices Racks Presets].freeze

  # What a clip is, and what the marks on a clip mean.
  LEGEND = AlsModelSerializer::LEGEND

  # @param set_name [String] the path of the set
  # @param xml_doc [Nokogiri::XML::Document] the set
  # @param tracks [LiveTracks] the tracks that hold clips
  # @param time_zone [String, nil] the time zone the times are written in
  def initialize(set_name, xml_doc, tracks, time_zone = nil)
    @set_name = set_name
    @xml_doc = xml_doc
    @tracks = tracks
    @time_zone = time_zone
    @ableton = xml_doc.at('Ableton')
  end

  # The report.
  #
  # @return [String] the report
  def to_markdown
    <<~END_REPORT
      # `#{File.basename @set_name}`

      #{metadata_markdown}

      #{P3SCompatibility.new(@tracks).to_markdown}

      #{tracks_markdown}

      #{missing_samples_markdown}

      #{samples_markdown}

      #{devices_markdown}

      #{cross_reference_markdown}
    END_REPORT
  end

  # The facts about the set: the version of Live that wrote it, where it is, and when.
  #
  # @return [String] the table
  def metadata_markdown
    header = HeaderBlock.new @set_name, @xml_doc, @time_zone
    LiveHeaderSerializer.new(header).to_markdown
  end

  # The tracks of the set, as an outline.
  #
  # Everything in the set is numbered by the path of the tree it is in: the tracks at the top
  # of the set are numbered from one, and the groups at the top of the set are numbered from one
  # as well; a track in a group is numbered after the group and after itself, as 1.1; the
  # devices of a track are numbered after the track and after the device, as 1.1a; and the
  # clips of a track are numbered after the track and after the clip, as 1.1.1.
  #
  # @return [String] the outline
  def tracks_markdown
    return 'The set has no tracks.' if @tracks.top_level.empty?

    als_model_serializer.hierarchy_markdown
  end

  # The serializer of the model of the set.
  #
  # @return [AlsModelSerializer] the serializer
  def als_model_serializer
    AlsModelSerializer.new als_model
  end

  # The model of the set.
  #
  # @return [AlsModel] the model
  def als_model
    @als_model ||= AlsModel.new @set_name, @xml_doc, created_at(@set_name), modified_at(@set_name),
                                    @time_zone
  end

  # The samples of the set that are not in the project, by the pack they are in.
  #
  # @return [String] the section of the report
  def missing_samples_markdown
    MissingSamplesSerializer.new(samples.missing).to_markdown
  end

  # The samples of the set, by the pack they are in.
  #
  # @return [String] the section of the report
  def samples_markdown
    LiveSamplesSerializer.new(samples).to_markdown
  end

  # The samples of the set.
  #
  # @return [LiveSamples] the samples
  def samples
    @samples ||= LiveSamples.new clips_of_the_set
  end

  # The clips of the set.
  #
  # @return [Array<LiveClip>] the clips
  def clips_of_the_set
    LiveClips.new(@tracks).to_a
  end

  # The devices of the set, and the tracks they are on.
  #
  # A device of a group is on the group and on the tracks in the group, because the chain of
  # the group processes the audio of the tracks in it.
  #
  # @return [String] the cross-reference
  def devices_markdown
    DeviceCrossReferenceSerializer.new(LiveDevices.new(@tracks.top_level)).to_markdown
  end

  # The clips of the set, and the tracks that use them.
  #
  # The clips are the clips of the outline: a clip is the same clip when it has the same name,
  # the same file, the same color and the same state. A clip that is on more than one track is
  # a clip the set shares, and it is marked as one.
  #
  # @return [String] the cross-reference
  def cross_reference_markdown
    TrackClipCrossReferenceSerializer.new(@tracks).to_markdown
  end

  # The key a clip is known by: its name, the file it refers to, its color and its state.
  #
  # It is the same key the clips of a track are grouped by, so that the clips of the outline
  # and the clips of the cross-reference are the same clips.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [String] the key
  def clip_key(clip)
    [name_of_clip(clip), file_of(clip), color_of(clip), clip_marks(clip).join(', ')].join(' | ')
  end

  # The icon of a clip: a musical note for an audio clip, a keyboard for a MIDI clip.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [String] the icon
  def clip_icon(clip)
    clip.name == 'MidiClip' ? '🎹' : '🎵'
  end

  # The mark of a clip whose sample is not in the project.
  #
  # The mark is on a dark red, in white text, and the style is on the code element itself: a
  # renderer that gives code its own color would otherwise win. The mark is aligned with the
  # text beside it, whose glyphs are of an ordinary height.
  NOT_COLLECTED =
    '<code style="background-color:#8B0000;color:#FFFFFF;vertical-align:middle">⚠ not in project</code>'.freeze

  # The clips of a track.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [Array<Nokogiri::XML::Element>] the clips
  def clips_of(track)
    track.xpath('.//AudioClip | .//MidiClip')
  end

  # The name of a device, and what kind of device it is.
  #
  # @param device [Nokogiri::XML::Element] the device
  # @return [String] the name
  def device_label(device)
    device = LiveDevice.new device
    label = device.label
    device.plug_in? ? "#{label} (plug-in)" : label
  end

  # Whether a track is frozen.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [Boolean] true when the track is frozen
  def frozen?(track)
    value_of(track, 'Freeze') == 'true'
  end

  # Whether a track is soloed.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [Boolean] true when the track is soloed
  def soloed?(track)
    value_of(track, 'IsSoloed') == 'true'
  end

  # Whether a track is armed for recording.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [Boolean] true when the track is armed
  def armed?(track)
    value_of(track, 'IsArmed') == 'true'
  end

  # Whether a track is switched off.
  #
  # The on/off state of a track is in the mixer of the track: the Manual value of the On
  # element is false when the track is off.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [Boolean] true when the track is off
  def off?(track)
    track.at_xpath('./Mixer/On/Manual | ./On/Manual')&.[]('Value') == 'false'
  end

  # The color of a track or a clip, as the number Live writes for it.
  #
  # @param element [Nokogiri::XML::Element] the track or the clip
  # @return [Integer, nil] the number
  def color_of(element)
    value = element.at('Color')&.[]('Value')
    value&.to_i
  end

  # The name of a track, on the color Live gave it.
  #
  # @param track [Array] the kind, the name, the element and the members of the track
  # @return [String] the name of the track, on its color
  def track_label(track)
    name_on_color track[1], track[2], dark: problem_for?(track[2])
  end

  # The name of a clip, on the color Live gave it.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [String] the name of the clip, on its color
  def clip_name(clip)
    name_on_color name_of_clip(clip), clip
  end

  # The name of a thing, on the color Live gave it.
  #
  # A thing that Push 3 Standalone cannot use is written on the dark background of those
  # things, and the name of it is in light text.
  #
  # @param name [String] the name of the thing
  # @param element [Nokogiri::XML::Element] the track or the clip
  # @param dark [Boolean] true when the thing cannot be used on Push 3 Standalone
  # @return [String] the name, on its color
  def name_on_color(name, element, dark: false)
    return plain_name(name, dark: true) if dark

    color = LivePalette.color_of color_of(element)
    return plain_name(name) unless color

    LiveTrackSerializer.colored_code escape(name), color_number:     color_of(element),
                                                   background_color: "##{color}",
                                                   foreground_color: text_color(color)
  end

  # The name of a thing that has no color of its own.
  #
  # @param name [String] the name of the thing
  # @param dark [Boolean] true when the thing cannot be used on Push 3 Standalone
  # @return [String] the name
  def plain_name(name, dark: false)
    if dark
      return LiveTrackSerializer.colored_code escape(name), background_color: DARK_BACKGROUND,
                                                            foreground_color: LIGHT_TEXT
    end

    "<code>#{escape name}</code>"
  end

  # The color the text on a color is written in.
  #
  # Black is written on a color that looks light, and white on a color that looks dark.
  #
  # @param color [String] the color, as six hex digits
  # @return [String] the color of the text
  def text_color(color)
    brightness(color) > 128 ? '#000000' : LIGHT_TEXT
  end

  # How bright a color looks.
  #
  # The brightness is the weighted sum of the three channels, the way the eye weighs them:
  # green counts the most, and blue the least.
  #
  # @param color [String] the color, as six hex digits
  # @return [Float] the brightness, from 0 to 255
  def brightness(color)
    red = color[0, 2].to_i(16)
    green = color[2, 2].to_i(16)
    blue = color[4, 2].to_i(16)
    (0.299 * red) + (0.587 * green) + (0.114 * blue)
  end

  # The value of an element of a track or a clip.
  #
  # @param element [Nokogiri::XML::Element] the track or the clip
  # @param name [String] the name of the element
  # @return [String, nil] the value, or nil when there is no such element
  def value_of(element, name)
    element.at_xpath(".//#{name}")&.[]('Value')
  end

  # A checkmark for a state of a track.
  # TODO rename this method to checkmark
  #
  # @param state [Boolean] the state to test
  # @return [String] a checkmark character, or the empty string when the state is falsey
  def mark(state)
    state ? '✓' : ''
  end

  # Escapes the characters that would break the table.
  #
  # @param text [String] the text string to escape
  # @return [String] the escaped string
  def escape(text)
    text.to_s.gsub('|', '&#124;')
  end
end
