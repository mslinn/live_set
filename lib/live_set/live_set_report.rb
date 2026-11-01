require 'markdown-tables'
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
# The colour of a track, a group and a clip is the background of its name, and the name of the
# colour Live writes for it is in the tooltip of the name. The text on the colour is the
# complementary colour, made as dark or as light as it has to be to be read on it. A track, a
# group and a device that Push 3 Standalone cannot use is written on the dark background of
# those things instead.
class LiveSetReport
  include Xml

  # The kinds of track, and the element that holds each of them.
  KINDS = {
    'MidiTrack' => 'MIDI', 'AudioTrack' => 'Audio', 'GroupTrack' => 'Group',
    'ReturnTrack' => 'Return', 'MasterTrack' => 'Master', 'MainTrack' => 'Main'
  }.freeze

  # The ways a clip can be launched.
  LAUNCH_MODES = { 0 => 'trigger', 1 => 'toggle', 2 => 'gate' }.freeze

  # The warp modes of a sample, in the order of Live's menu.
  WARP_MODES = { 0 => 'Beads', 1 => 'Texture', 2 => 'Complex', 3 => 'Complex Pro', 4 => 'Melody' }.freeze

  # The folders the content of a pack is in.
  CONTENT_FOLDERS = %w[Samples Sounds IRs Devices Racks Presets].freeze

  # What the marks on a clip mean.
  LEGEND = 'The marks on a clip: `linked` means the clip shares its sample with the other ' \
           'clips of a linked group, so that editing one of them edits them all; `warped` means ' \
           'the sample is time-stretched; `⚠ not in project` means the sample is not in the ' \
           'folder of the project, and the set is not self-contained.'.freeze

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

      #{@tracks.verdict_markdown}

      #{tracks_markdown}

      #{missing_samples_markdown}

      #{devices_markdown}

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
    rows = [
      ['Written by', @ableton['Creator']],
      ['Format', @ableton['MinorVersion']],
      ['SchemaChangeCount', @ableton['SchemaChangeCount']],
      ['Revision', @ableton['Revision']],
      ['Machine', machine_name],
      ['Directory', "`#{directory}`"],
      ['Time zone', time_zone_name],
      ['Set created', created_at(@set_name)],
      ['Set last modified', modified_at(@set_name)],
      ['Project created', created_at(directory)],
      ['Project last modified', project_last_modified]
    ]
    MarkdownTables.make_table ['', ''], rows, align: %w[l r], is_rows: true
  end

  # The name of the time zone the times of the report are written in.
  #
  # The times are written in the time zone of the computer unless another one is asked for.
  #
  # @return [String] the name of the zone
  def time_zone_name
    return @time_zone if @time_zone

    local_zone_name || Time.now.zone
  end

  # The name of the time zone of the computer.
  #
  # @return [String, nil] the name of the zone, or nil when it cannot be found
  def local_zone_name
    target = begin
      File.readlink '/etc/localtime'
    rescue SystemCallError
      nil
    end
    return nil unless target

    target.split('zoneinfo/').last
  end

  # A time, as the report writes it.
  #
  # The times are written in the time zone of the report, and without a time zone of their
  # own, because the zone is named at the top of the report.
  #
  # @param time [Time] the time
  # @return [String] the time
  def format_time(time)
    return time.strftime('%Y-%m-%d %H:%M:%S') unless @time_zone

    previous = ENV.fetch('TZ', nil)
    ENV['TZ'] = @time_zone
    time.getlocal.strftime('%Y-%m-%d %H:%M:%S')
  ensure
    ENV['TZ'] = previous
  end

  # The time the project was last changed.
  #
  # The time of a folder is the time an entry was added to it or taken from it, and not the
  # time the work in it last changed. The project was last changed when the file in it that
  # was changed last was changed, and the file is named, so that the time can be explained.
  #
  # @return [String] the file, and the time it was changed
  def project_last_modified
    path, time = newest_file_of directory
    return modified_at(directory) unless path

    relative = path.delete_prefix("#{directory}/")
    "`#{relative}`<br>#{format_time time}"
  end

  # The file of a folder that was changed last.
  #
  # @param root [String] the folder
  # @return [Array] the path of the file and the time it was changed
  def newest_file_of(root)
    newest = nil
    Dir.glob(File.join(root, '**', '*'), File::FNM_DOTMATCH).each do |path|
      next unless File.file?(path)

      time = File.mtime path
      newest = [path, time] if newest.nil? || time > newest[1]
    end
    newest
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
    format_time creation_time(path) || File.mtime(path)
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
    format_time File.mtime(path)
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
    tracks = track_tree
    lines = ['## Groups/Tracks/Clips/Devices', '']

    if tracks.empty?
      lines << 'The set has no tracks.'
      return lines.join("\n")
    end

    lines << LEGEND
    lines << ''
    lines += top_level_lines(tracks)
    lines.join("\n")
  end

  # The lines of the tracks and the groups at the top of the set.
  #
  # The groups at the top of the set are numbered from one, and the tracks at the top of the
  # set are numbered from one as well: a group and a track are numbered in their own company.
  #
  # @param tracks [Array<Array>] the tracks of the set
  # @return [Array<String>] the lines
  def top_level_lines(tracks)
    groups = 0
    others = 0
    tracks.flat_map do |track|
      if track[0] == 'Group'
        groups += 1
        track_lines track, groups, 0
      else
        others += 1
        track_lines track, others, 0
      end
    end
  end

  # The lines of a track, of the devices and the clips of it, and of the tracks in its group.
  #
  # @param track [Array] the kind, the name, the element and the members of the track
  # @param number [String] the number of the track
  # @param depth [Integer] how deep the track is
  # @return [Array<String>] the lines
  def track_lines(track, number, depth, boxed: false)
    kind, name, element, members = track
    indent = '  ' * depth
    group = kind == 'Group'

    problem = problem_for? element

    label = group ? "Group track #{number}" : "Track #{number}"
    line = "#{indent}- #{label}  #{LivePalette.name_span escape(name), color_of(element), dark: problem}"
    line += "  #{LivePalette.icon_of kind} #{kind}"
    states = states_of element
    line += "  #{states.join(', ')}" unless states.empty?
    lines = [line]

    lines += device_lines kind, number, element, indent

    grouped_clips(clips_of(element)).each do |clip, count, index|
      lines += clip_lines clip, "#{number}.#{index}", depth + 1, count
    end

    members.each_with_index do |member, index|
      lines += track_lines member, "#{number}.#{index + 1}", depth + 1, boxed: boxed || problem
    end

    lines
  end

  # Whether a track is a problem for a transfer to Push 3 Standalone.
  #
  # A track that is not frozen and that has a device Push 3 cannot run cannot be transferred: the
  # device has to be rendered away by freezing the track.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [Boolean] true when the track is a problem
  def problem_for?(track)
    return false if frozen?(track)

    own_devices(track).any? { |device| LiveDevice.new(device).blocking? }
  end

  # The lines of the devices of a track.
  #
  # @param kind [String] the kind of the track
  # @param number [String] the number of the track
  # @param element [Nokogiri::XML::Element] the track
  # @param indent [String] the indentation of the track
  # @return [Array<String>] the lines
  def device_lines(kind, number, element, indent)
    own_devices(element).each_with_index.map do |node, index|
      device = LiveDevice.new node
      unusable = device.blocking? && !frozen?(element)
      parts = [LivePalette.name_span(device.label, nil, dark: unusable), device_kind(device)]
      parts << '⚠ not usable on Push 3' if unusable
      "#{indent}  - #{device_slot_label kind} #{number}#{letter_of index}  #{parts.join '  '}"
    end
  end

  # What kind of device a device is.
  #
  # @param device [LiveDevice] the device
  # @return [String] the kind
  def device_kind(device)
    return 'plug-in' if device.plug_in?
    return 'Max for Live' if device.max_for_live?

    'native device'
  end

  # The name of the devices of a kind of track.
  #
  # @param kind [String] the kind of track
  # @return [String] the name
  def device_slot_label(kind)
    kind == 'Group' ? 'Group Track Device' : 'Track Device'
  end

  # The letter of a device.
  #
  # @param index [Integer] the number of the device, counting from zero
  # @return [String] the letter
  def letter_of(index)
    ('a'.ord + index).chr
  end

  # The clips of a track that are the same, and how many of each there are.
  #
  # A set holds the same clip in every slot of a track, and again in the arrangement, so the
  # clips of a track are often many copies of one clip.
  #
  # @param clips [Array<Nokogiri::XML::Element>] the clips
  # @return [Array<Array>] each clip, the number of copies of it, and the number of the first
  #   of them
  def grouped_clips(clips)
    groups = {}
    clips.each_with_index do |clip, index|
      key = [name_of_clip(clip), file_of(clip), color_of(clip), clip_marks(clip).join(', ')]
      groups[key] ||= [clip, 0, index + 1]
      groups[key][1] += 1
    end
    groups.values
  end

  # The lines of a clip, and of the devices of it.
  #
  # A clip of a set of Live 11 or Live 12 has no devices of its own: the devices that shape
  # the sound of a clip are the devices of the track it is on, and the devices of a sample are
  # in the file of the sample, not in the set.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @param number [String] the number of the clip
  # @param depth [Integer] how deep the clip is
  # @param count [Integer] how many copies of the clip the track holds
  # @return [Array<String>] the lines
  def clip_lines(clip, number, depth, count = 1)
    indent = '  ' * depth
    marks = clip_marks clip
    line = "#{indent}- Clip #{number}  #{LivePalette.name_span escape(name_of_clip(clip)), color_of(clip)}"
    line += "  #{marks.join(', ')}" unless marks.empty?
    line += "  × #{count}" if count > 1
    file = file_of clip
    line += "  `#{file}`" if file
    [line]
  end

  # The state of a track.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [Array<String>] the marks
  def states_of(track)
    states = []
    states << '✓ frozen' if frozen?(track)
    states << '✓ solo' if soloed?(track)
    states << '🔴 ✓ armed' if armed?(track)
    states << 'off' if off?(track)
    states
  end

  # The samples of the set that are not in the project, grouped by the pack they are in.
  #
  # Live writes the absolute path of a sample in the set, and the path of the pack it is in is
  # in it: a sample of a factory pack is under a folder of the pack, and the folder above the
  # content of the pack is the pack.
  #
  # @return [String] the summary
  def missing_samples_markdown
    packs = Hash.new { |hash, key| hash[key] = [] }
    each_clip do |clip|
      next if collected? clip

      path = absolute_path_of clip
      next unless path

      name = File.basename path
      samples = packs[pack_of path]
      samples << name unless samples.include? name
    end

    lines = ['## Missing Samples', '']
    if packs.empty?
      lines << 'Every sample of the set is in the project.'
      return lines.join("\n")
    end

    rows = packs.sort.map do |pack, samples|
      [pack, samples.map { |name| "`#{name}`" }.join(', ')]
    end
    lines << MarkdownTables.make_table(%w[Pack Samples], rows, align: %w[l l], is_rows: true)
    lines.join("\n")
  end

  # The devices of the set, and the tracks they are on.
  #
  # A device of a group is on the group and on the tracks in the group, because the chain of
  # the group processes the audio of the tracks in it.
  #
  # @return [String] the cross-reference
  def devices_markdown
    uses = device_uses
    lines = ['## Device Cross-Reference', '']
    if uses.empty?
      lines << 'The set has no devices.'
      return lines.join("\n")
    end

    rows = uses.sort_by { |(label, _kind, _unusable), _| label }.map do |(label, kind, unusable), tracks|
      name = LivePalette.name_span escape(label), nil, dark: unusable
      [name, kind, tracks.map { |track| "`#{escape track}`" }.join(', ')]
    end
    lines << MarkdownTables.make_table(['Device', 'Kind', 'Used in'], rows, align: %w[l l l], is_rows: true)
    lines.join("\n")
  end

  # The devices of the set, and the tracks they are on.
  #
  # @return [Hash] each device, with the tracks it is on
  def device_uses
    uses = Hash.new { |hash, key| hash[key] = [] }
    each_track do |track, members|
      own_devices(track[2]).each do |node|
        device = LiveDevice.new node
        unusable = device.blocking? && !frozen?(track[2])
        key = [device.label, device_kind(device), unusable]
        uses[key] << track[1]
        members.each { |member| uses[key] << member[1] }
      end
    end
    uses
  end

  # Every track of the set, with the tracks of its group.
  #
  # @yieldparam track [Array] the track
  # @yieldparam members [Array<Array>] the tracks in the group of the track
  # @return [void]
  def each_track
    track_tree.each do |track|
      yield track, track[3]
      track[3].each { |member| yield member, [] }
    end
  end

  # Every clip of the set.
  #
  # @yieldparam clip [Nokogiri::XML::Element] a clip of the set
  # @return [void]
  def each_clip(&)
    track_tree.each do |track|
      clips_of(track[2]).each(&)
      track[3].each do |member|
        clips_of(member[2]).each(&)
      end
    end
  end

  # The path of the file a clip refers to, as Live wrote it.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [String, nil] the path
  def absolute_path_of(clip)
    clip.at('SampleRef/FileRef/Path')&.[]('Value')
  end

  # The pack a file is in.
  #
  # The content of a pack is under a folder of its own — Samples, Sounds, IRs, Devices — and
  # the pack is the folder above it. A file that is not under such a folder is not in a pack.
  #
  # @param path [String] the path of the file
  # @return [String] the name of the pack
  def pack_of(path)
    parts = path.split('/')
    index = parts.index { |part| CONTENT_FOLDERS.include? part }
    return File.basename(path) unless index&.positive?

    parts[index - 1]
  end

  # The clips of the set, and the tracks that use them.
  #
  # The clips are the clips of the outline above: a clip is the same clip when it has the
  # same name, the same file, the same color and the same state. A clip that is on more than
  # one track is a clip the set shares, and it is marked as one.
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

    rows = uses.map do |_key, entry|
      clip, tracks = entry
      shared = tracks.length > 1
      name = LivePalette.name_span escape(name_of_clip(clip)), color_of(clip)
      name = "**#{name}**" if shared
      tracks = tracks.map { |track| shared ? "**`#{escape track}`**" : "`#{escape track}`" }.join(', ')
      [name, tracks]
    end
    lines << MarkdownTables.make_table(%w[Clip Tracks], rows, align: %w[l l], is_rows: true)
    lines.join("\n")
  end

  # The tracks that use a clip, and the tracks of the groups they are in.
  #
  # @param track [Array] the kind, the name, the element and the members of the track
  # @param uses [Hash] the clips and the tracks that use them
  # @return [void]
  def collect_uses(track, uses)
    _kind, name, element, members = track
    grouped_clips(clips_of(element)).each do |clip, _count, _index|
      key = clip_key clip
      uses[key] ||= [clip, []]
      uses[key][1] << name unless uses[key][1].include? name
    end
    members.each { |member| collect_uses member, uses }
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
  # Live numbers the tracks it makes itself: the first audio track of a set is named
  # `1-Audio`, the second MIDI track `2-MIDI`. The number is the number of the track and not
  # part of its name, and it is left out of the name here. A track that the user has named
  # keeps the name the user gave it, number and all.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [String] the name
  def name_of_track(track)
    user_name = track.at('Name/UserName')&.[]('Value')
    effective_name = track.at('Name/EffectiveName')&.[]('Value')
    name = user_name.nil? || user_name.empty? ? effective_name : user_name
    return '(unnamed)' if name.nil? || name.empty?

    user_name.nil? || user_name.empty? ? name.sub(/\A\d+-/, '') : name
  end

  # The name of a clip, as Live wrote it.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [String] the name
  # The name of a clip, as Live wrote it.
  #
  # Live names a clip after the track it is on, with the number of the track in front of the
  # name of the track and a number of its own behind it: the first clip of the third track is
  # `3-Kontakt 7 1`. The number of the track is not part of the name of the clip.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [String] the name
  def name_of_clip(clip)
    name = clip.at('Name')&.[]('Value')
    return '(unnamed)' if name.nil? || name.empty?

    name.sub(/\A\d+-/, '')
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
    marks << '⚠ not in project' unless collected? clip
    marks << '🔴 disabled' if clip.at('Disabled')&.[]('Value') == 'true'
    mode = clip.at('LaunchMode')&.[]('Value')
    marks << "launch: #{LAUNCH_MODES.fetch mode.to_i, mode}" if mode
    marks << 'linked' if clip.at('IsLinked')&.[]('Value') == 'true'
    marks << 'warped' if clip.at('IsWarped')&.[]('Value') == 'true'
    marks << "warp: #{warp_of clip}" if clip.at('WarpMode')
    marks
  end

  # Whether the sample of a clip is in the folder of the project.
  #
  # A sample that is not in the folder of the project is not part of the set, and the set is
  # not self-contained: the samples have to be collected before the set can be transferred.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [Boolean] true when the sample is in the project
  def collected?(clip)
    path = file_of clip
    !path.nil? && path.start_with?('Samples/Imported/')
  end

  # The warp mode of a sample.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [String] the name of the mode and the number Live writes for it
  def warp_of(clip)
    value = clip.at('WarpMode')&.[]('Value').to_i
    "#{WARP_MODES.fetch value, 'unknown'} (#{value})"
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
