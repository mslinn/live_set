require 'socket'
require 'time'
require_relative '../common/log'
require_relative '../common/xml'
require_relative 'live_device'
require_relative 'live_palette'

# The report of a set, in markdown.
#
# The report names every track of the set, with the state of each one, the effects on it, and
# the clips of it. The members of a group are under the group, and the clips of a track are
# under the track.
#
# The report of a set is written for a person to read, and it is checked in, so that what a
# set holds is written down where it can be read again.
#
# The tables are HTML, and not markdown, because the cell of the color of a track is filled
# with the color, and a markdown table has no way of saying that.
class LiveSetReport
  include Xml

  # The kinds of track, and the element that holds each of them.
  KINDS = {
    'MidiTrack' => 'MIDI', 'AudioTrack' => 'Audio', 'GroupTrack' => 'Group',
    'ReturnTrack' => 'Return', 'MasterTrack' => 'Master', 'MainTrack' => 'Main'
  }.freeze

  # The ways a clip can be launched.
  LAUNCH_MODES = { 0 => 'trigger', 1 => 'toggle', 2 => 'gate' }.freeze

  # @param set_name [String] the path of the set
  # @param xml_doc [Nokogiri::XML::Document] the set
  # @param tracks [LiveTracks] the tracks that hold clips
  def initialize(set_name, xml_doc, tracks)
    @set_name = set_name
    @xml_doc = xml_doc
    @tracks = tracks
    @ableton = xml_doc.at('Ableton')
  end

  # The report.
  #
  # @return [String] the report
  def to_markdown
    <<~END_REPORT
      # `#{File.basename @set_name}`

      #{metadata_markdown}

      #{@tracks.verdict_markdown}

      #{tracks_markdown}

      #{clips_markdown}

      #{cross_reference_markdown}
    END_REPORT
  end

  # The facts about the set: the version of Live that wrote it, where it is, and when.
  #
  # Live writes no date of its own in a set, so the dates here are the dates of the files:
  # the set, and the project folder it is in.
  #
  # @return [String] the table
  def metadata_markdown
    lines = ['| | |', '| --- | --- |']
    lines << "| Written by | #{@ableton['Creator']} |"
    lines << "| Format | #{@ableton['MinorVersion']} |"
    lines << "| SchemaChangeCount | #{@ableton['SchemaChangeCount']} |"
    lines << "| Revision | #{@ableton['Revision']} |"
    lines << "| Machine | #{machine_name} |"
    lines << "| Directory | `#{directory}` |"
    lines << "| Set created | #{created_at @set_name} |"
    lines << "| Set modified | #{modified_at @set_name} |"
    lines << "| Folder created | #{created_at directory} |"
    lines << "| Folder modified | #{modified_at directory} |"
    lines.join("\n")
  end

  # The machine the set is on.
  #
  # @return [String] the name of the machine
  def machine_name
    Socket.gethostname
  end

  # The directory the set is in.
  #
  # @return [String] the path of the directory
  def directory
    File.dirname File.expand_path(@set_name)
  end

  # The time a file was created, as the machine that holds it says.
  #
  # A Windows drive mounted under WSL does not say when a file was created: the mount reports
  # the time the file was last changed, which is not the same thing. Windows itself knows, so
  # Windows is asked. Where the machine cannot say, the time the file was last written is used.
  #
  # @param path [String] the path of the file
  # @return [String] the time
  def created_at(path)
    (creation_time(path) || File.mtime(path)).strftime('%Y-%m-%d %H:%M:%S %z')
  end

  # The time a file was created, as Windows says it.
  #
  # @param path [String] the path of the file
  # @return [Time, nil] the time, or nil when the machine cannot say
  def creation_time(path)
    windows = windows_path_of path
    return nil unless windows

    output = `powershell.exe -NoProfile -Command "(Get-Item -LiteralPath '#{windows.gsub("'", "''")}').CreationTime.ToString('o')" 2>/dev/null`
    Time.parse output.strip
  rescue ArgumentError, TypeError
    nil
  end

  # The path of a file, as Windows names it.
  #
  # @param path [String] the path
  # @return [String, nil] the path, or nil when the file is not on a Windows drive
  def windows_path_of(path)
    match = path.match(%r{\A/mnt/([a-z])/(.*)\z})
    return nil unless match

    "#{match[1].upcase}:\\#{match[2].tr('/', '\\')}"
  end

  # The time a file was last written.
  #
  # @param path [String] the path of the file
  # @return [String] the time
  def modified_at(path)
    File.mtime(path).strftime('%Y-%m-%d %H:%M:%S %z')
  end

  # The tracks of the set, as a table.
  #
  # @return [String] the table
  def tracks_markdown
    tracks = track_tree
    lines = ['## Tracks', '']

    if tracks.empty?
      lines << 'The set has no tracks.'
      return lines.join("\n")
    end

    lines << '<table>'
    lines << '<thead><tr><th>Track</th><th>Kind</th><th>Frozen</th><th>Off</th><th>Solo</th>' \
             '<th>Armed</th><th>Color</th><th>Clips</th></tr></thead>'
    lines << '<tbody>'
    tracks.each { |track| lines += track_rows track, 0 }
    lines << '</tbody>'
    lines << '</table>'
    lines.join("\n")
  end

  # The rows of a track and of the tracks in its group.
  #
  # @param track [Array] the kind, the name, the element and the members of the track
  # @param depth [Integer] how deep the track is
  # @return [Array<String>] the rows
  def track_rows(track, depth)
    kind, name, element, members = track
    cells = [
      "<td><code>#{'&nbsp;' * depth}#{escape name}</code></td>",
      "<td>#{LivePalette.icon_of kind} #{kind}</td>",
      "<td>#{mark frozen?(element)}</td>",
      "<td>#{mark off?(element)}</td>",
      "<td>#{mark soloed?(element)}</td>",
      "<td>#{mark armed?(element)}</td>",
      color_cell(element),
      "<td>#{clips_of(element).length}</td>"
    ]
    rows = ["<tr>#{cells.join}</tr>"]
    members.each { |member| rows += track_rows member, depth + 1 }
    rows
  end

  # The cell of the color of a track, filled with the color.
  #
  # @param element [Nokogiri::XML::Element] the track
  # @return [String] the cell
  def color_cell(element)
    value = color_of element
    style = LivePalette.style_of value
    style ? %(<td style="#{style}">#{value}</td>) : "<td>#{value}</td>"
  end

  # The clips of the set, under the track they are on.
  #
  # @return [String] the clips
  def clips_markdown
    tracks = track_tree
    lines = ['## Clips', '']

    if tracks.empty?
      lines << 'The set has no clips.'
      return lines.join("\n")
    end

    tracks.each { |track| lines += clip_lines track, 0 }
    lines.join("\n")
  end

  # The lines of a track, of the tracks in its group, and of their clips.
  #
  # @param track [Array] the kind, the name, the element and the members of the track
  # @param depth [Integer] how deep the track is
  # @return [Array<String>] the lines
  def clip_lines(track, depth)
    kind, name, element, members = track
    indent = '  ' * depth
    lines = ["#{indent}- #{LivePalette.icon_of kind} `#{escape name}` — #{kind}"]

    devices = own_devices element
    lines << "#{indent}  - Effects: #{devices.map { |device| device_label device }.join(', ')}" unless devices.empty?

    clips = clips_of element
    lines << "#{indent}  - Clips: #{clips.length}"
    grouped_clips(clips).each { |clip, count| lines += clip_line(clip, count, depth + 2) }

    unless members.empty?
      lines << "#{indent}  - Members:"
      members.each { |member| lines += clip_lines member, depth + 2 }
    end
    lines
  end

  # The clips of a track that are the same, and how many of each there are.
  #
  # A set holds the same clip in every slot of a track, and again in the arrangement, so the
  # clips of a track are often many copies of one clip.
  #
  # @param clips [Array<Nokogiri::XML::Element>] the clips
  # @return [Array<Array>] each clip and the number of copies of it
  def grouped_clips(clips)
    groups = {}
    clips.each do |clip|
      key = [name_of_clip(clip), file_of(clip), color_of(clip), clip_marks(clip).join(', ')]
      groups[key] = [clip, 0]
      groups[key][1] += 1
    end
    groups.values
  end

  # The line of a clip.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @param count [Integer] how many copies of the clip there are
  # @param depth [Integer] how deep the clip is
  # @return [Array<String>] the lines
  def clip_line(clip, count, depth)
    indent = '  ' * depth
    marks = clip_marks clip
    copies = count > 1 ? " × #{count}" : ''
    lines = ["#{indent}- #{clip_icon clip} `#{escape name_of_clip(clip)}`#{copies} — " \
             "#{LivePalette.swatch color_of(clip)}#{" — #{marks.join(', ')}" unless marks.empty?}"]

    file = file_of clip
    lines << "#{indent}  - File: `#{file}`" if file

    effects = own_devices clip
    lines << "#{indent}  - Effects: #{effects.map { |device| device_label device }.join(', ')}" unless effects.empty?

    lines
  end

  # The clips of the set, and the tracks that use them.
  #
  # A clip that is on more than one track is a clip the set shares, and it is marked as one.
  #
  # @return [String] the cross-reference
  def cross_reference_markdown
    uses = {}
    track_tree.each { |track| collect_uses track, uses }

    lines = ['## Track / Clip Cross Reference', '']
    if uses.empty?
      lines << 'The set has no clips.'
      return lines.join("\n")
    end

    lines << '<table>'
    lines << '<thead><tr><th>Clip</th><th>Color</th><th>Tracks</th></tr></thead>'
    lines << '<tbody>'
    uses.each do |key, entry|
      clip, tracks = entry
      shared = tracks.length > 1
      name = shared ? "<strong><code>#{escape key}</code></strong>" : "<code>#{escape key}</code>"
      tracks = tracks.map { |track| shared ? "<strong><code>#{escape track}</code></strong>" : "<code>#{escape track}</code>" }
                     .join(', ')
      lines << "<tr><td>#{name}</td>#{color_cell clip}<td>#{tracks}</td></tr>"
    end
    lines << '</tbody>'
    lines << '</table>'
    lines.join("\n")
  end

  # The tracks that use a clip, and the tracks of the groups they are in.
  #
  # @param track [Array] the kind, the name, the element and the members of the track
  # @param uses [Hash] the clips and the tracks that use them
  # @return [void]
  def collect_uses(track, uses)
    _kind, name, element, members = track
    clips_of(element).each do |clip|
      key = clip_key clip
      uses[key] ||= [clip, []]
      uses[key][1] << name unless uses[key][1].include? name
    end
    members.each { |member| collect_uses member, uses }
  end

  # The key a clip is known by: its name, and the file it refers to.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [String] the key
  def clip_key(clip)
    file = file_of clip
    file ? "#{name_of_clip clip} — #{file}" : name_of_clip(clip)
  end

  # The tracks of the set, as a tree: a group holds the tracks that are in it.
  #
  # A member track's TrackGroupId holds the id of the group it belongs to, and -1 means the
  # track is at the top level. See docs/als_notes.md, "A member track names its group".
  #
  # @return [Array<Array>] the kind, the name, the element and the members of each track
  def track_tree
    elements = @xml_doc.xpath('//MidiTrack | //AudioTrack | //GroupTrack | //Tracks/ReturnTrack | ' \
                              '//MasterTrack | //MainTrack')
    build_track_tree elements, nil
  end

  # The tracks at one level of the tree.
  #
  # @param elements [Array<Nokogiri::XML::Element>] the tracks of the set
  # @param parent_id [String, nil] the id of the group the tracks belong to
  # @return [Array<Array>] the tracks
  def build_track_tree(elements, parent_id)
    elements.select { |element| group_id_of(element) == parent_id }.map do |element|
      # The master track has no id, and a track without an id has no members.
      id = element['Id']
      members = id ? build_track_tree(elements, id) : []
      [KINDS.fetch(element.name, element.name), name_of_track(element), element, members]
    end
  end

  # The group a track belongs to.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [String, nil] the id of the group, or nil when the track is at the top level
  def group_id_of(track)
    value = track.at('TrackGroupId')&.[]('Value')
    value == '-1' ? nil : value
  end

  # The name of a track, as Live wrote it.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [String] the name
  def name_of_track(track)
    track.at('Name/EffectiveName')&.[]('Value') || track.at('Name/UserName')&.[]('Value') || '(unnamed)'
  end

  # The name of a clip, as Live wrote it.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [String] the name
  def name_of_clip(clip)
    clip.at('Name')&.[]('Value') || '(unnamed)'
  end

  # The file a clip refers to.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [String, nil] the path of the file, or nil when the clip refers to none
  def file_of(clip)
    clip.at('SampleRef/FileRef/RelativePath')&.[]('Value') ||
      clip.at('SampleRef/FileRef/Path')&.[]('Value')
  end

  # The icon of a clip: a musical note for an audio clip, a keyboard for a MIDI clip.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [String] the icon
  def clip_icon(clip)
    clip.name == 'MidiClip' ? '🎹' : '🎵'
  end

  # The state of a clip.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [Array<String>] the marks
  def clip_marks(clip)
    marks = []
    marks << '🔴 disabled' if clip.at('Disabled')&.[]('Value') == 'true'
    mode = clip.at('LaunchMode')&.[]('Value')
    marks << "launch: #{LAUNCH_MODES.fetch mode.to_i, mode}" if mode
    marks << 'linked' if clip.at('IsLinked')&.[]('Value') == 'true'
    marks << 'warped' if clip.at('IsWarped')&.[]('Value') == 'true'
    marks
  end

  # The clips of a track.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [Array<Nokogiri::XML::Element>] the clips
  def clips_of(track)
    track.xpath('.//AudioClip | .//MidiClip')
  end

  # The devices of a track, and not the devices of the group it belongs to.
  #
  # A track in a group holds the chain of the group in an AudioEffectGroupDevice, and the
  # devices of the group are in it.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [Array<Nokogiri::XML::Element>] the devices
  def own_devices(track)
    track.xpath('.//Devices/*').reject do |node|
      LiveDevice::CONTAINER_ELEMENTS.include?(node.name) ||
        node.ancestors.any? { |ancestor| LiveDevice::CONTAINER_ELEMENTS.include? ancestor.name }
    end
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

  # The value of an element of a track or a clip.
  #
  # @param element [Nokogiri::XML::Element] the track or the clip
  # @param name [String] the name of the element
  # @return [String, nil] the value, or nil when there is no such element
  def value_of(element, name)
    element.at_xpath(".//#{name}")&.[]('Value')
  end

  # A mark for a state of a track.
  #
  # @param state [Boolean] the state
  # @return [String] the mark, or nothing when the state does not hold
  def mark(state)
    state ? '✓' : ''
  end

  # A name, with the characters that would break the table escaped.
  #
  # @param text [String] the name
  # @return [String] the name
  def escape(text)
    text.to_s.gsub('|', '&#124;')
  end
end
