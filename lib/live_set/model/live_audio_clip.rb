require 'colorator'
require 'date'
require 'pathname'
require_relative '../../common/xml'
require_relative 'live_clip_settings'

# A clip of the audio side of a track.
#
# The clip plays a file, and the file is what the report is about: where it is, how big it
# is, and whether it is in the project. The clip of the MIDI side of a track is
# `LiveMidiClip`, and it holds notes instead.
#
# Every value in an .als file is stored in a Value attribute, e.g.
# <RelativePath Value="Samples/Imported/song1.mp3" />. This holds for every Live version from
# 8.2 to 12.4. See docs/als_notes.md, "Every value is stored in a `Value` attribute".
#
# The file size tag is <OriginalFileSize> in newer versions of Live, and <FileSize> in older
# ones (like Live 8).
#
# Ableton stores the absolute path in a <Path> element and the path relative to the set's
# directory in a <RelativePath> element. Either may be empty, meaning the file is not in the
# project folder. See docs/als_notes.md, "The sample references of a clip".
#
# @param audio_clip is an inner <ClipSlot/> element from an Ableton Live .als file as parsed by Nokogiri
# @return the absolute path to a referenced clip, or nil if the clip is not stored in a file.
# Not all clips contain audio samples:
# - MIDI clips do not have audio files.
# - Empty clip slots have no associated files.
# - Internal devices and resampled clips reference internal Ableton data rather than external files.
#
# An <AudioClip> is not always inside a <ClipSlot>. Live 12 moved most of them into the
# arrangement and the take lanes. See docs/als_notes.md, "Where a track's audio is".
#
# @param set_directory [String] the directory holding the set
# @param audio_clip [Nokogiri::XML::Element] an <AudioClip> element from an Ableton Live .als file
# @param place [String, nil] where the clip is: `session view`, `arrangement`, or the number
#   of the take lane it is in
class LiveAudioClip
  include Xml

  # The mark of a clip whose sample is not in the project.
  NOT_COLLECTED = '⚠ not in project'.freeze

  attr_reader :absolute_path, :color, :file_size, :last_modified, :name, :path, :place, :relative_path,
              :settings

  def initialize(set_directory, audio_clip, place: nil)
    @audio_clip         = audio_clip
    @place              = place
    @file_ref           = @audio_clip.at('SampleRef/FileRef')
    @last_modified      = last_modified_date

    # File size: Check both OriginalFileSize (newer Live) and FileSize (Live 8)
    size_node = @file_ref&.at('OriginalFileSize') || @file_ref&.at('FileSize')
    @file_size = xml_value(size_node).to_i

    # PATHS: Ableton stores the path in the Value attribute of a RelativePath or Path element.
    @relative_path = xml_value(@file_ref&.at('RelativePath'))
    absolute_path_xml = xml_value(@file_ref&.at('Path'))

    # The path Live wrote, which is where the file was when the set was saved. It is the
    # path that says which pack the file is in.
    @path = absolute_path_xml unless absolute_path_xml.nil? || absolute_path_xml.empty?

    @absolute_path = compute_absolute_path absolute_path_xml, @relative_path, set_directory
    @file_size = disk_size if @file_size.zero? && !@absolute_path.nil?
    @name = name_of audio_clip
    @color = audio_clip.at('Color')&.[]('Value')&.to_i
    @settings = LiveClipSettings.new audio_clip
  end

  # The name Live wrote for the clip.
  #
  # Live numbers the names of the tracks and clips that share a name, and the number is
  # not part of the name.
  #
  # @return [String] the name
  def name_of(audio_clip)
    name = audio_clip.at('Name')&.[]('Value')
    return '(unnamed)' if name.nil? || name.empty?

    name.sub(/\A\d+-/, '')
  end

  # The file the clip plays.
  #
  # The relative path is the one to use: the absolute path is a fallback for a clip that has
  # no relative path. Live 12 writes an empty relative path for a sample that is not in the
  # project, and keeps only the absolute path of it.
  #
  # @return [String, nil] the file, or nil when the clip plays no file
  def file
    return @relative_path unless @relative_path.nil? || @relative_path.empty?

    path = xml_value @file_ref&.at('Path')
    path.nil? || path.empty? ? nil : path
  end

  # The name the cross-reference names the clip by.
  #
  # A clip of the audio side of a track is named after the file it plays.
  #
  # @return [String] the name
  def label
    return name if file.nil?

    File.basename file, File.extname(file)
  end

  # What makes a clip the same clip as another.
  #
  # The copies of a clip that are alike are counted together, and the report writes them as
  # one line.
  #
  # @return [String] the key of the clip
  def key
    "#{name}:#{file}"
  end

  # What is said about the clip.
  #
  # @return [Array<String>] the marks
  def marks
    marks = []
    marks << NOT_COLLECTED unless collected?
    marks
  end

  # The size of the file on disk.
  #
  # The size in the XML is the size of the source file as Live saw it, and it is sometimes zero even
  # when the file exists and is not empty. See docs/als_notes.md, "Whether a sample has been collected".
  #
  # @return [Integer] the size in bytes, or zero if the file cannot be found
  def disk_size
    return 0 if @absolute_path.nil?

    File.size(@absolute_path)
  rescue SystemCallError
    0
  end

  # The time the sample was last modified.
  #
  # @return [DateTime, nil] the time, or nil if the clip has no LastModDate
  def last_modified_date
    seconds = xml_value(@audio_clip.at('SampleRef/LastModDate'))&.to_i
    return nil if seconds.nil? || seconds.zero?

    Time.at(seconds).utc.to_datetime
  end

  def compute_absolute_path(absolute_path_xml, relative_path, set_directory)
    # If relative_path exists and is not empty, construct the path
    if relative_path && !relative_path.empty? && set_directory
      constructed_path = Pathname.new(set_directory).join(relative_path)
      begin
        constructed_path.realpath.to_s
      rescue Errno::ENOENT, Errno::ELOOP => e
        Log.warn "Warning: File path does not exist (from source system): #{constructed_path}\n#{e}"
        constructed_path.to_s
      end
    elsif absolute_path_xml && !absolute_path_xml.empty?
      # Fallback to the absolute path stored in the XML if RelativePath is missing
      absolute_path_xml
    else # rubocop:disable Style/EmptyElse
      nil # No valid path found - return nil instead of the set directory
    end
  end

  # A clip is considered to be "collected" if its audio file was copied into the project's `Samples/Imported/`` folder.
  # If a clip doesn't have a relative path (meaning it's either a MIDI clip or linked via an absolute path), it is by
  # definition not collected into the project folder. Therefore, returning false is the correct behavior.
  def collected?
    @relative_path&.start_with?('Samples/Imported/') || false
  end
end
