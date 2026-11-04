require 'markdown-tables'
require 'socket'
require 'time'
require_relative '../common/log'
require_relative '../common/xml'
require_relative 'live_palette'
require_relative 'model/live_device'
require_relative 'serializer/live_device_serializer'
require_relative 'serializer/live_group_track_serializer'
require_relative 'serializer/live_track_serializer'
require_relative 'serializer/p3s_compatibility'

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

  # The places a clip can be in a track, and the paths of the clips in them.
  #
  # A track holds the clips of its session view slots and the clips of the arrangement. The
  # clips of its take lanes are in the lanes, which are subordinate to the track.
  #
  # @return [Array<Array>] the place, and the paths of the clips in it
  def clip_places
    [
      ['session view',
       ['./DeviceChain/MainSequencer/ClipSlotList/ClipSlot/ClipSlot/Value/AudioClip',
        './DeviceChain/MainSequencer/ClipSlotList/ClipSlot/ClipSlot/Value/MidiClip']],
      ['arrangement',
       ['./DeviceChain/MainSequencer/Sample/ArrangerAutomation/Events/AudioClip',
        './DeviceChain/MainSequencer/ClipTimeable/ArrangerAutomation/Events/MidiClip']]
    ]
  end

  # TODO: MiniMax 3.1 Flash insists on using the word "mark" but is unable to
  # define that term. We must delete the word "mark" from this body of code and
  # replace it with a commonly used term.

  # What the marks on a clip mean, and what a clip is.
  LEGEND = <<~TEXT.squish.freeze
    Clip properties include the name of the clip and the audio file.
    Clip references are found in session view slots, the arrangement, and a take lanes.
    Reference properties include launch method and warp mode.
    The take lanes of a track are under the track.
    The string `⚠ not in project` means the sample is not the project directory tree, so the set is not self-contained.
  TEXT

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
      ['On computer', computer],
      ['Directory', path_cell(directory)],
      ['Time zone', time_zone],
      ['Set created', created_at(@set_name)],
      ['Set last modified', modified_at(@set_name)],
      ['Project created', created_at(directory)],
      ['Project last modified', project_last_modified],
      ['Report generated', report_generated]
    ].sort_by { |row| row.first.downcase }
    MarkdownTables.make_table ['', ''], rows, align: %w[l r], is_rows: true
  end

  # A path, as a cell that can be broken where it has to be.
  #
  # The path is written in monospaced type, and a break is offered after each separator, so
  # that a long path does not make the table wider than the window.
  #
  # @param path [String] the path
  # @return [String] the cell
  def path_cell(path)
    "<code>#{path.gsub('/', '/<wbr/>')}</code>"
  end

  # The computer the report was made on: its name, and the hardware UUID of it.
  #
  # @return [String] the name of the computer
  def computer
    uuid = hardware_uuid
    uuid.empty? ? machine_name : "#{machine_name} (#{uuid})"
  end

  # The UUID of the machine, as Windows knows it.
  #
  # The registry of Windows holds it, and `reg.exe` reads it in a moment. The answer is the
  # same for every report of a process, so it is asked once.
  #
  # @return [String] the UUID, or an empty string when it cannot be found
  def self.hardware_uuid
    @hardware_uuid ||= `reg.exe query "HKLM\\SOFTWARE\\Microsoft\\Cryptography" /v MachineGuid 2>/dev/null`.split.last.to_s
  end

  # The hardware UUID of the computer.
  #
  # @return [String] the UUID, or an empty string when it cannot be found
  def hardware_uuid
    self.class.hardware_uuid
  end

  # The time zone the times of the report are written in, and the offset that was in force on
  # the day the set was last modified.
  #
  # @return [String] the zone, and the offset
  def time_zone
    name = time_zone_name
    offset = utc_offset_at File.mtime(@set_name)
    offset ? "#{name} (UTC#{offset})" : name
  end

  # The offset from UTC that was in force at a time, as it is written.
  #
  # @param time [Time] the time
  # @return [String, nil] the offset, or nil when it cannot be worked out
  def utc_offset_at(time)
    local = @time_zone ? time.getlocal(@time_zone) : time
    seconds = local.utc_offset
    return nil if seconds.zero? && @time_zone.nil?

    sign = seconds.negative? ? '-' : '+'
    hours = seconds.abs / 3600
    minutes = (seconds.abs % 3600) / 60
    minutes.zero? ? "#{sign}#{hours}" : "#{sign}#{hours}:#{format('%02d', minutes)}"
  end

  # When the report was made, and what made it.
  #
  # @return [String] the time and the version
  def report_generated
    "#{format_time Time.now} by live_set v#{LiveSetVersion::VERSION}"
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
    "#{path_cell relative}<br>#{format_time time}"
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
    tracks = @tracks.top_level
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
  # @param tracks [Array<LiveTrack, LiveGroup>] the tracks of the set
  # @return [Array<String>] the lines
  def top_level_lines(tracks)
    groups = 0
    others = 0
    tracks.flat_map do |track|
      if track.group?
        groups += 1
        LiveGroupTrackSerializer.new(track, groups).to_markdown.split("\n")
      else
        others += 1
        LiveTrackSerializer.new(track, others).to_markdown.split("\n")
      end
    end
  end

  # Every track of the set, with the number it has in the outline.
  #
  # The groups at the top of the set are numbered from one, and the tracks at the top of the set
  # are numbered from one as well: a group and a track are numbered in their own company. The
  # tracks of a group are numbered after the group, as 1.1.
  #
  # @yieldparam number [String] the number of the track
  # @yieldparam track [Array] the kind, the name, the element and the members of the track
  # @return [void]
  def each_numbered_track
    groups = 0
    others = 0
    track_tree.each do |track|
      number = if track[0] == 'Group'
                 groups += 1
                 groups.to_s
               else
                 others += 1
                 others.to_s
               end
      yield number, track
      track[3].each_with_index { |member, index| yield "#{number}.#{index + 1}", member }
    end
  end

  # The lines of a track, of the devices and the clips of it, and of the tracks in its group.
  #
  # @param track [Array] the kind, the name, the element and the members of the track
  # @param number [String] the number of the track
  # @param depth [Integer] how deep the track is
  # @return [Array<String>] the lines
  def track_lines(track, number, depth, boxed: false)
    kind, _name, element, members = track
    indent = '  ' * depth
    group = kind == 'Group'

    problem = problem_for? element

    label = group ? "Group track #{number}" : "Track #{number}"
    line = "#{indent}- #{label}  #{LiveTrackSerializer.icon_for kind} #{kind}  " \
           "#{track_label(track)}"
    states = states_of element
    line += "  #{states.join(', ')}" unless states.empty?
    lines = [line]

    lines += device_lines kind, number, element, "#{indent}  "
    lines += clip_lines element, number, "#{indent}  "
    lines += take_lane_lines element, number, "#{indent}  "

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
      letter = letter_of index
      serializer = LiveDeviceSerializer.new device, "#{number}#{letter}", track_frozen: frozen?(element)
      "#{indent}- #{device_slot_label kind} #{number}#{letter}  #{serializer.to_markdown}"
    end
  end

  # What kind of device a device is.
  #
  # @param device [LiveDevice] the device
  # @return [String] the kind
  def device_kind(device)
    device.kind
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

  # The clips of a track, and the references to them.
  #
  # A clip is the thing a reference refers to: the file it plays, or, for a MIDI clip, its own
  # content. The settings of a reference — how it is launched, how its sample is warped —
  # belong to the reference and not to the clip, so they are reported on the reference.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [Array<Hash>] each clip, its file, and its references
  def clips_of_track(track)
    groups_of references_of(track)
  end

  # The take lanes of a track, and the clips of each of them.
  #
  # A take lane holds the takes of a recording. The track holds the clips that are heard, and
  # the lanes hold the takes they were comped from, so the lanes are subordinate to the track.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [Array<Hash>] each lane, its name and its clips
  def take_lanes_of(track)
    lanes = []
    track.xpath('.//TakeLane').each do |lane|
      clips = lane.xpath('./ClipAutomation/Events/AudioClip | ./ClipAutomation/Events/MidiClip')
      lanes << { id: lane['Id'], name: lane.at('Name')&.[]('Value'), clips: clips }
    end
    lanes
  end

  # The references to the clips of a track.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [Array<Hash>] each reference, its clip, the place it is in, and its number
  def references_of(track)
    references = []
    clip_places.each do |place, paths|
      track.xpath(paths.join(' | ')).each do |clip|
        references << { clip: clip, place: place, index: references.length + 1 }
      end
    end
    references
  end

  # The clips of a list of references, grouped by the clip each one refers to.
  #
  # @param references [Array<Hash>] the references
  # @return [Array<Hash>] each clip, its file, and its references
  def groups_of(references)
    groups = {}
    references.each do |reference|
      key = identity_of reference[:clip]
      groups[key] ||= { clip: reference[:clip], file: file_of(reference[:clip]), references: [] }
      groups[key][:references] << reference
    end
    groups.values
  end

  # The identity of a clip: its name, and the file it plays.
  #
  # Every place a clip is in holds a reference to it, and the references are what carry the
  # settings of the clip in that place.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [String] the identity
  def identity_of(clip)
    "#{name_of_clip clip}:#{file_of clip}"
  end

  # The take lanes of a track, and the clips of each of them, as the outline shows them.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @param number [String] the number of the track
  # @param indent [String] the indentation of the lanes
  # @return [Array<String>] the lines
  def take_lane_lines(track, number, indent)
    lines = []

    take_lanes_of(track).each_with_index do |lane, index|
      lane_number = "#{number}.#{index + 1}"
      lines << "#{indent}- Take lane #{lane_number}  #{lane[:name]}"
      groups_of(lane[:clips].each_with_index.map { |clip, i| { clip: clip, place: 'take lane', index: i + 1 } })
        .each do |clip|
        lines += clip_group_lines [clip], lane_number, "#{indent}  "
      end
    end
    lines
  end

  # The clips of a track, as the outline shows them.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @param number [String] the number of the track
  # @param indent [String] the indentation of the clips
  # @return [Array<String>] the lines
  def clip_lines(track, number, indent)
    clip_group_lines clips_of_track(track), number, indent
  end

  # The lines of a set of clips: the clip, and the references to it.
  #
  # @param clips [Array<Hash>] each clip, its file, and its references
  # @param number [String] the number of the track or of the take lane
  # @param indent [String] the indentation of the clips
  # @return [Array<String>] the lines
  def clip_group_lines(clips, number, indent)
    lines = []

    clips.each do |clip|
      references = clip[:references]
      first = references.first
      marks = clip_marks clip[:clip]

      line = "#{indent}* Clip #{number}.#{first[:index]} (#{count_of references.length})  " \
             "#{clip_name(clip[:clip])}"
      line += "  #{marks.join(', ')}" unless marks.empty?
      line += "<br>`#{clip[:file]}`" if clip[:file]
      lines << line

      reference_lines(clip[:references]).each { |reference| lines << "#{indent}  #{reference}" }
    end
    lines
  end

  # The references to a clip, one line for each set of settings.
  #
  # The references that have the same settings are one line, with the number of them, and the
  # lines are ordered by the number of the references, so that the ones with the most
  # references come first.
  #
  # @param references [Array<Hash>] the references
  # @return [Array<String>] the lines
  def reference_lines(references)
    groups = Hash.new { |hash, key| hash[key] = [] }
    references.each do |reference|
      groups[settings_of(reference[:clip])] << reference
    end

    groups.map { |settings, group| [group.length, settings] }
          .sort_by { |count, settings| [-count, settings] }
          .map { |count, settings| "* References (#{count_of count}): #{settings}" }
  end

  # The settings of a reference: how it is launched, and how its sample is warped.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [String] the settings
  def settings_of(clip)
    settings = []
    settings << 'disabled' if clip.at('Disabled')&.[]('Value') == 'true'
    mode = clip.at('LaunchMode')&.[]('Value')
    settings << "launch: #{LAUNCH_MODES.fetch mode.to_i, mode}" if mode
    settings << if clip.at('WarpMode') && warped?(clip)
                  "warp: #{warp_of clip}"
                else
                  'warp: none'
                end
    settings.join(', ')
  end

  # Whether the sample of a clip is warped.
  #
  # The warp mode of a clip is written whether the sample is warped or not, so the mode says
  # nothing about it on its own.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [Boolean] true when the sample is warped
  def warped?(clip)
    clip.at('IsWarped')&.[]('Value') == 'true'
  end

  # A count of things, as the report writes it.
  #
  # @param count [Integer] the count
  # @return [String] the count
  def count_of(count)
    "×#{count}"
  end

  # The state of a track.
  #
  # TODO accept a LiveTrack instead of an XML element, and move this method to
  # the LiveTrack class.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [Array<String>] the marks
  def states_of(track)
    states = []
    # FIXME: In Ruby, frozen? is a built-in method belonging to the Object class. This frozen? method should be incorporated into the LiveTrack class
    states << "\u{1F976} frozen" if frozen?(track) # TODO: should be track.frozen? after cleanup
    states << "\u{1F142} solo" if soloed?(track) # TODO: should be track.soloed? after cleanup
    states << '🔴 armed' if armed?(track) # TODO: should be track.armed? after cleanup
    states << "\u{23FD} off" if off?(track) # TODO: should be track.off? after cleanup
    group = linked_group_of track
    states << "linked group #{group}" if group
    states
  end

  # In an Ableton Live .als XML file, the <LinkedTrackGroupId> element
  # identifies which tracks are bound together for phase-locked editing using
  # Ableton's "Link Tracks" feature.
  #
  # The Link tracks feature is completely separate from the nested structural
  # hierarchy used for Track Groups (<GroupTrack>).
  #
  # If a track is not linked to any other track, the LinkedTrackGroupId value
  # defaults to -1.
  #
  # When you select multiple tracks, right-click, and select Link Tracks,
  # Ableton assigns them a matching unique integer ID (starting at 0 and
  # incrementing for each new link group you create in the project).
  #
  # Because Ableton allows you to link tracks that live in completely different
  # parts of your session (e.g., linking a guitar track inside a "Guitars" Group
  # with a vocal track inside a "Vocals" Group), it cannot rely on the layout
  # tree of the XML to know they are connected.
  #
  # When your script or Ableton parses the .als file, it looks for any tracks
  # sharing the exact same LinkedTrackGroupId value. If they match, Ableton
  # instantly mirrors your mouse clicks, splits, crossfades, and warp markers
  # across all of them simultaneously.
  #
  # Track Linking works across both the Arrangement View and the Session View,
  # though it behaves differently depending for each view. When tracks share a
  # matching <LinkedTrackGroupId>, Ableton links specific workflow actions
  # across both views to keep your multi-mic takes or layered instruments in
  # perfect sync.
  #
  # ## Session View
  # While you can't "slice" a clip timeline in Session View, linking ensures
  # your mixing, routing, and recording workflows stay perfectly aligned across
  # your channels:
  #
  # • Arming one linked track automatically arms all other tracks in that link
  # group. This is crucial for multi-mic setups (like a drum kit or a stereo
  # piano) so you never accidentally miss recording a channel.
  #
  # • Toggling solo (🅂) or mute (🄼) on one channel immediately applies it to
  # the rest of the group.
  #
  # • Triggering, stopping, or deleting a clip in a Session row will launch,
  # stop, or delete the corresponding clips on the linked tracks simultaneously.
  #
  # ## Arrangement View
  #
  # In the arrangement view, a track group is edited as a unit. Operations are
  # applied to all of the tracks of the group at once. For example, moving and
  # resizing the clips, selecting, editing the time, splitting and
  # consolidating, the fades, arming, the take lanes. Live gives each group of
  # linked tracks an id.
  #
  # • Timeline Edits: Cutting (Ctrl+E / Cmd+E), duplicating, moving, or deleting
  # clips.
  #
  # • Warping & Quantization: Adjusting warp markers or applying transients to
  # one clip perfectly mirrors across all linked clips to maintain exact phase
  # relationships.
  #
  # • Fades & Crossfades: Drawing a volume fade on the edge of one track applies
  # the identical curve to the rest.
  #
  #
  # Ableton Live introduced Track Linking in version 11.
  #
  # See §6.14 "Linked-Track Editing" in the Live 12 manual:
  # https://www.ableton.com/en/live-manual/12/arrangement-view/#linked-track-editing
  #
  # @param track [Nokogiri::XML::Element] the track @return [String, nil] the
  # group, or nil when the track is linked to no other
  def linked_group_of(track)
    value = track.at('LinkedTrackGroupId')&.[]('Value')
    value == '-1' ? nil : value
  end

  # TODO: Move this method into the new MissingSamples class.
  #
  # The samples of the set that are not in the project, grouped by the pack they
  # are in.
  #
  # Live writes the absolute path of a sample in the set, and the path of the
  # pack it is in is in it: a sample of a factory pack is under a folder of the
  # pack, and the folder above the content of the pack is the pack.
  #
  # @return [String] the summary of missing samples as a markdown table, or a
  # message that there are no missing samples
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

  # TODO: Move this method into the new LiveDevices class and rename it to `markdown`.
  #
  # The devices of the set, and the tracks they are on.
  #
  # A device of a group is on the group and on the tracks in the group, because the chain of
  # the group processes the audio of the tracks in it.
  #
  # @return [String] the cross-reference
  def devices_markdown
    uses = device_uses
    lines = ['## Device/Track Cross-Reference', '']
    if uses.empty?
      lines << 'The set has no devices.'
      return lines.join("\n")
    end

    rows = uses.sort_by { |(label, _kind, _unusable), _| label.downcase }.map do |(label, kind, unusable), tracks|
      name = plain_name label, dark: unusable
      [name, kind, tracks.join(', ')]
    end
    lines << MarkdownTables.make_table(['Device', 'Kind', 'Tracks With This Device'], rows, align: %w[l l l], is_rows: true)
    lines.join("\n")
  end

  # TODO: Move this method into the new LiveDevices class and rename it to
  # `device_track_hash`.
  #
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
        uses[key] << track_label(track)
        members.each { |member| uses[key] << track_label(member) }
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
    lines = ['## Track / Clip Cross Reference', '']
    lines << '### Tracks and their clips'
    lines << ''
    lines << tracks_and_clips_table
    lines << ''
    lines << '### Clips and their tracks'
    lines << ''
    lines << clips_and_tracks_table
    lines.join("\n")
  end

  # The tracks of the set, and the clips each of them holds.
  #
  # The clips of the take lanes of a track are the clips of the track as well, and are marked
  # with the lane they are in.
  #
  # @return [String] the table
  def tracks_and_clips_table
    rows = []
    each_numbered_track do |number, track|
      places = clip_places_of_track track, number
      next if places.empty?

      listed = places.map do |label, counts|
        "`#{escape label}` " + counts.map { |place, count| "#{place} \u00d7#{count}" }.join(', ')
      end
      rows << [track[1], "#{number} #{track_label track}", listed.join('; ')]
    end
    return 'The set has no clips.' if rows.empty?

    rows.sort_by! { |row| row[0].downcase }
    MarkdownTables.make_table(%w[Track Clips], rows.map { |_, track, clips| [track, clips] },
                              align: %w[l l], is_rows: true)
  end

  # The places the clips of a track are in, and how many of them there are in each.
  #
  # The clips of the take lanes of the track are the clips of the track as well, and are marked
  # with the lane they are in.
  #
  # @param track [Array] the kind, the name, the element and the members of the track
  # @param number [String] the number of the track
  # @return [Hash] each clip, the places it is in, and the number of them in each
  def clip_places_of_track(track, number)
    places = Hash.new { |hash, key| hash[key] = Hash.new(0) }
    clips_of_track(track[2]).each do |clip|
      clip[:references].each { |reference| places[clip_label(clip)][reference[:place]] += 1 }
    end

    take_lanes_of(track[2]).each_with_index do |lane, index|
      lane_number = "#{number}.#{index + 1}"
      lane[:clips].each { |clip| places[label_of(clip)]["take lane #{lane_number}"] += 1 }
    end
    places
  end

  # The clips of the set, and the tracks that hold them.
  #
  # A clip of a take lane is marked with the lane it is in.
  #
  # @return [String] the table
  def clips_and_tracks_table
    uses = tracks_of_clips
    rows = uses.sort_by { |clip, _| clip.downcase }.map { |clip, tracks| ["`#{escape clip}`", tracks.join(', ')] }
    return 'The set has no clips.' if rows.empty?

    MarkdownTables.make_table(%w[Clip Tracks], rows, align: %w[l l], is_rows: true)
  end

  # The tracks that hold each clip of the set.
  #
  # A track that holds a clip in its take lanes as well as in itself is one entry, and the
  # lanes it holds the clip in are named with it.
  #
  # @return [Hash] each clip, and the tracks that hold it
  def tracks_of_clips
    uses = Hash.new { |hash, key| hash[key] = {} }
    each_numbered_track do |number, track|
      name = track_label track
      clips_of_track(track[2]).each { |clip| holds_of uses, clip_label(clip), number, name }
      holds_of_lanes uses, track, number, name
    end

    uses.transform_values { |holds| holds.map { |number, hold| hold_line number, hold } }
  end

  # The take lanes of a track, and the clips of them.
  #
  # @param uses [Hash] the clips and the tracks that hold them
  # @param track [Array] the kind, the name, the element and the members of the track
  # @param number [String] the number of the track
  # @param name [String] the name of the track, on its color
  # @return [void]
  def holds_of_lanes(uses, track, number, name)
    take_lanes_of(track[2]).each_with_index do |lane, index|
      lane_number = "#{number}.#{index + 1}"
      lane[:clips].each do |clip|
        hold = holds_of uses, label_of(clip), number, name
        hold[:lanes] << lane_number unless hold[:lanes].include? lane_number
      end
    end
  end

  # The line of a track that holds a clip.
  #
  # @param number [String] the number of the track
  # @param hold [Hash] the record of the track
  # @return [String] the line
  def hold_line(number, hold)
    lanes = hold[:lanes].empty? ? '' : " (take lane #{hold[:lanes].join(', ')})"
    "#{number} #{hold[:name]}#{lanes}"
  end

  # The record of a track that holds a clip.
  #
  # @param uses [Hash] the clips and the tracks that hold them
  # @param label [String] the name of the clip
  # @param number [String] the number of the track
  # @param name [String] the name of the track
  # @return [Hash] the record of the track
  def holds_of(uses, label, number, name)
    holds = uses[label]
    holds[number] ||= { name: name, lanes: [] }
    holds[number]
  end

  # The name of a clip, as the cross-reference names it: the file it plays, without its
  # extension, or, for a MIDI clip, the name of the clip.
  #
  # @param clip [Hash] the clip
  # @return [String] the name
  def clip_label(clip)
    label_of clip[:clip]
  end

  # The name of a clip element, as the cross-reference names it.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [String] the name
  def label_of(clip)
    file = file_of clip
    return File.basename(file, File.extname(file)) if file

    name_of_clip clip
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

  # TODO: move to a new LiveTracks class, and rename to `tree`. LiveTracks would
  # be a collection of LiveTrack objects, and LiveTrack sould be a wrapper
  # around a track element.
  #
  # The tracks of the set, as a tree: a group holds the tracks that are in it.
  #
  # A member track's TrackGroupId holds the id of the group it belongs to, and
  # -1 means the track is at the top level. See docs/als_notes.md, "A member
  # track names its group".
  #
  # @return [Array<Array>] the kind, the name, the element and the members of
  # each track
  def track_tree
    elements = @xml_doc.xpath('//MidiTrack | //AudioTrack | //GroupTrack | //Tracks/ReturnTrack | ' \
                              '//MasterTrack | //MainTrack')
    build_track_tree elements, nil
  end

  # TODO: move to a LiveGroup class, and rename. This method does not really
  # build a tree, because it returns an array. LiveTracks should be a collection
  # of LiveTrack, and LiveTrack should be a wrapper around a track element.
  #
  # This method should return an array of LiveTrack objects. The LiveTrack class
  # should have a method that returns the kind of the track, its name, and its
  # children.
  #
  # The LiveTracks class should have a method that returns
  # the tracks of the set as an array. The new name for this method should be
  # tracks_for_group, and it should be private to the LiveTracks class.
  #
  # The tracks at one level of the tree.
  #
  # TODO: this returns arrays of the element and its members. The model holds the tracks as
  # objects, and the report is to be written from them: see docs/serializer_plan.md, step 5.
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

  # The group id a track belongs to.
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
    reference = clip.at 'SampleRef/FileRef'
    return nil if reference.nil?

    relative = reference.at('RelativePath')&.[]('Value')
    return relative unless relative.nil? || relative.empty?

    # Live 12 writes an empty relative path for a sample that is not in the project, and
    # keeps only the absolute path of it.
    absolute = reference.at('Path')&.[]('Value')
    absolute.nil? || absolute.empty? ? nil : absolute
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
  # The marks of a clip: the facts about the clip itself, and not about a reference to it.
  #
  # @param clip [Nokogiri::XML::Element] the clip
  # @return [Array<String>] the marks
  def clip_marks(clip)
    marks = []
    marks << NOT_COLLECTED unless collected? clip
    marks
  end

  # The mark of a clip whose sample is not in the project.
  #
  # The mark is on a dark red, in white text, and the style is on the code element itself: a
  # renderer that gives code its own color would otherwise win. The mark is aligned with the
  # text beside it, whose glyphs are of an ordinary height.
  NOT_COLLECTED =
    '<code style="background-color:#8B0000;color:#FFFFFF;vertical-align:middle">⚠ not in project</code>'.freeze

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
  # @return [String] the name of the mode
  def warp_of(clip)
    value = clip.at('WarpMode')&.[]('Value').to_i
    WARP_MODES.fetch value, 'unknown'
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
