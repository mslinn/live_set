require 'bytesize'
require 'colorator'
require 'fileutils'
require 'nokogiri'
require 'pathname'
require 'time'
require 'zlib'
require_relative '../common/log'
require_relative 'als_file'
require_relative 'live_set_converter'

# See https://www.ionos.ca/digitalguide/websites/web-development/xpath-tutorial/
# See https://www.scrapingbee.com/webscraping-questions/selenium/how-to-find-elements-by-xpath-selenium
# See https://nokogiri.org/tutorials/searching_a_xml_html_document.html#slop-1

class LiveSet
  # Report on a Live set, or convert it to the Live 11 format.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Integer] the exit status of the command
  def self.run(args)
    options, remaining = parse_options(args)

    abort help('An Ableton Live set name must be provided.') if remaining.empty?

    set_name = remaining.join(' ').expand_env
    abort help("#{set_name} does not exist") unless File.exist? set_name
    abort help("#{set_name} is a directory") if File.directory? set_name

    live_set = new set_name, **options

    if options[:convert11]
      report_conversion live_set.modify_als
    else
      puts live_set.show
    end
    0
  rescue LiveSetConverter::AlreadyExists => e
    puts e.message.red
    1
  end

  # Says what a conversion did.
  #
  # @param result [LiveSetConverter::Result] what the conversion did
  # @return [void]
  def self.report_conversion(result)
    case result.status
    when :already_compatible
      puts 'The Live set is already compatible with Live 11.'.yellow
    when :converted
      if result.overwritten
        puts "Overwriting existing #{result.path}".green
      else
        puts "Writing #{result.path}".green
      end
      puts 'Conversion complete'.green
    end
  end

  def initialize(set_name, **options)
    # Can set with a string ('WARN') or an int (Logger::WARN is 2)
    Log.level = options[:loglevel] || Logger::WARN

    @set_directory = File.dirname(File.realpath(set_name))

    @overwrite = options[:force]
    @set_name = set_name

    @contents = AlsFile.read_text(set_name)

    @xml_doc = Nokogiri::Slop @contents

    @ableton = @xml_doc.Ableton
    @minor_version = @ableton['MinorVersion']

    @live_set = @ableton.LiveSet

    # Get AudioTrack elements safely - returns empty NodeSet if none exist
    #
    # Only the tracks that play clips are reported. A group track is a summing container and
    # holds no clips, so it is not one of these. See docs/als_notes.md, "A group track holds no
    # clips".
    audio_tracks = begin
      # Use XPath directly on the document to avoid Slop method_missing issues
      result = @xml_doc.xpath('//AudioTrack')
      result
    rescue StandardError => e
      Log.error "Error accessing AudioTrack elements: #{e.message}"
      []
    end

    # A group track is a summing container, not a track that plays clips. It holds no clips, so it
    # is not reported alongside the tracks, but its members' audio is routed through its device
    # chain, so its devices are checked. See docs/als_notes.md, "The group tracks".
    group_tracks = @xml_doc.xpath('//GroupTrack')

    @tracks = LiveTracks.new @set_directory, audio_tracks, group_tracks
    @scenes = @live_set.Scenes.map { |scene| LiveScene.new scene }
  end

  # The report of the set.
  #
  # The report is markdown. It is written to stdout, and the log is written to stderr, so that
  # the report can be read as a document and not as the output of a program.
  #
  # @return [String] the report
  def show
    check_ableton_project_info
    <<~END_REPORT
      # #{File.basename @set_name}

      | | |
      | --- | --- |
      | Created by | #{@ableton['Creator']} |
      | Major version | #{@ableton['MajorVersion']} |
      | Minor version | #{@minor_version} |
      | SchemaChangeCount | #{@ableton['SchemaChangeCount']} |
      | Revision | #{@ableton['Revision']} |
      | Created | #{created_at} |
      | Modified | #{modified_at} |

      #{@tracks.verdict_markdown}

      #{tracks_markdown}
    END_REPORT
  end

  # The time the set was written, as the filesystem says.
  #
  # A Windows drive mounted under WSL does not say when a file was created: the mount reports
  # the time the file was last changed, which is not the same thing. Windows itself knows, so
  # Windows is asked. Where the machine cannot say, the time the file was last written is
  # used.
  #
  # @return [String] the time
  def created_at
    (creation_time || File.mtime(@set_name)).strftime('%Y-%m-%d %H:%M:%S %z')
  end

  # The time the set was created, as the machine that holds it says.
  #
  # @return [Time, nil] the time, or nil when the machine cannot say
  def creation_time
    path = windows_path_of @set_name
    return nil unless path

    output = `powershell.exe -NoProfile -Command "(Get-Item -LiteralPath '#{path.gsub("'", "''")}').CreationTime.ToString('o')" 2>/dev/null`
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

  # The time the set was last written.
  #
  # @return [String] the time
  def modified_at
    File.mtime(@set_name).strftime('%Y-%m-%d %H:%M:%S %z')
  end

  # The tracks of the set, in markdown.
  #
  # The report that is written for the terminal is about the tracks that hold clips, because
  # that is what a transfer to Push 3 Standalone is about. A set of the A/B program holds
  # tracks that hold no clips at all, so the report of the set names every track of it, with
  # the state of each one and the members of a group under the group they belong to.
  #
  # @return [String] the markdown
  def tracks_markdown
    tracks = track_inventory
    lines = ['## Tracks', '']

    if tracks.empty?
      lines << 'The set has no tracks.'
      return lines.join("\n")
    end

    lines << '| Track | Kind | Frozen | Off | Solo | Armed | Color | Clips |'
    lines << '| --- | --- | --- | --- | --- | --- | --- | --- |'
    tracks.each do |kind, name, element, depth|
      lines << "| #{'↳ ' * depth}#{name.empty? ? '(unnamed)' : name.gsub('|', '\|')} | #{kind} | " \
               "#{mark frozen?(element)} | #{mark off?(element)} | #{mark soloed?(element)} | " \
               "#{mark armed?(element)} | #{color_of(element)} | #{clips_of(element)} |"
    end
    lines << ''
    lines << 'The color of a track is the number Live writes for it. The palette that turns the ' \
             'number into a color is not available to this tool.'
    lines.join("\n")
  end

  # The tracks of the set, by kind and name, with the members of a group under their group.
  #
  # A member track's TrackGroupId holds the id of the group it belongs to, and -1 means the
  # track is at the top level. See docs/als_notes.md, "A member track names its group".
  #
  # @return [Array<Array>] the kind, the name, the element and the depth of each track
  def track_inventory
    elements = @xml_doc.xpath('//MidiTrack | //AudioTrack | //GroupTrack | //Tracks/ReturnTrack | ' \
                              '//MasterTrack | //MainTrack')

    tracks = []
    elements.each do |element|
      next unless top_level? element

      tracks << [kind_of(element), name_of_track(element), element, 0]
      tracks += members_of element, elements, 1
    end
    tracks
  end

  # The members of a group, and the members of the groups among them.
  #
  # @param group [Nokogiri::XML::Element] the group
  # @param elements [Array<Nokogiri::XML::Element>] the tracks of the set
  # @param depth [Integer] how deep the members are
  # @return [Array<Array>] the tracks
  def members_of(group, elements, depth)
    members = elements.select { |element| element.at('TrackGroupId')&.[]('Value') == group['Id'] }
    members.flat_map do |element|
      [[kind_of(element), name_of_track(element), element, depth]] + members_of(element, elements, depth + 1)
    end
  end

  # Whether a track is at the top level of the set.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [Boolean] true when the track is not in a group
  def top_level?(track)
    track.at('TrackGroupId')&.[]('Value') == '-1'
  end

  # The kind of a track, as the element that holds it is named.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [String] the kind
  def kind_of(track)
    { 'MidiTrack' => 'MIDI', 'AudioTrack' => 'Audio', 'GroupTrack' => 'Group',
      'ReturnTrack' => 'Return', 'MasterTrack' => 'Master', 'MainTrack' => 'Main' }[track.name] || track.name
  end

  # The name of a track, as Live wrote it.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [String] the name, or an empty string when the track has none
  def name_of_track(track)
    track.at('Name/EffectiveName')&.[]('Value') || track.at('Name/UserName')&.[]('Value') || ''
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
    value = track.at_xpath('./Mixer/On/Manual | ./On/Manual')&.[]('Value')
    value == 'false'
  end

  # The color of a track, as the number Live writes for it.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [String] the number, or an empty string when the track has no color
  def color_of(track)
    value_of(track, 'Color') || ''
  end

  # The clips of a track, by kind.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [String] the clips
  def clips_of(track)
    audio = track.xpath('.//AudioClip').count
    midi = track.xpath('.//MidiClip').count
    counts = []
    counts << "#{audio} audio" if audio.positive?
    counts << "#{midi} MIDI" if midi.positive?
    counts.empty? ? '' : counts.join(', ')
  end

  # The value of an element of a track.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @param name [String] the name of the element
  # @return [String, nil] the value, or nil when the track has no such element
  def value_of(track, name)
    track.at_xpath(".//#{name}")&.[]('Value')
  end

  # A mark for a state of a track.
  #
  # @param state [Boolean] the state
  # @return [String] the mark, or nothing when the state does not hold
  def mark(state)
    state ? '✓' : ''
  end

  # Writes out a Live 11 session
  #
  # The conversion itself is done by LiveSetConverter.
  #
  # @return [LiveSetConverter::Result] what the conversion did
  def modify_als
    return LiveSetConverter::Result.new status: :already_compatible if @minor_version.start_with? '11.'

    LiveSetConverter.new(@set_name, @xml_doc, overwrite: @overwrite).convert
  end
end
