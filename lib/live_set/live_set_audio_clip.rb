require 'colorator'
require 'date'
require 'pathname'
require_relative '../common/xml'

class LiveAudioClip
  include Xml

  attr_reader :absolute_path, :file_size, :last_modified, :relative_path

  # Every value in an .als file is stored in a Value attribute, e.g.
  # <RelativePath Value="Samples/Imported/song1.mp3" />. This holds for every Live version from
  # 8.2 to 12.4. See docs/als_format.md section 3.
  #
  # The file size tag is <OriginalFileSize> in newer versions of Live, and <FileSize> in older
  # ones (like Live 8).
  #
  # Ableton stores the absolute path in a <Path> element and the path relative to the set's
  # directory in a <RelativePath> element. Either may be empty, meaning the file is not in the
  # project folder. See docs/als_format.md section 7.
  #
  # @param audio_clip is an inner <ClipSlot/> element from an Ableton Live .als file as parsed by Nokogiri
  # @return the absolute path to a referenced clip, or nil if the clip is not stored in a file.
  # Not all clips contain audio samples:
  # - MIDI clips do not have audio files.
  # - Empty clip slots have no associated files.
  # - Internal devices and resampled clips reference internal Ableton data rather than external files.
  #
  # An <AudioClip> is not always inside a <ClipSlot>. Live 12 moved most of them into the
  # arrangement and the take lanes. See docs/als_format.md section 6.
  #
  # @param set_directory [String] the directory holding the set
  # @param audio_clip [Nokogiri::XML::Element] an <AudioClip> element from an Ableton Live .als file
  def initialize(set_directory, audio_clip)
    @audio_clip         = audio_clip
    @file_ref           = @audio_clip.SampleRef.FileRef
    @last_modified      = last_modified_date

    # File size: Check both OriginalFileSize (newer Live) and FileSize (Live 8)
    size_node = @file_ref.at('OriginalFileSize') || @file_ref.at('FileSize')
    @file_size = xml_value(size_node).to_i

    # PATHS: Ableton stores the path in the Value attribute of a RelativePath or Path element.
    @relative_path = xml_value(@file_ref.at('RelativePath'))
    absolute_path_xml = xml_value(@file_ref.at('Path'))

    @absolute_path = compute_absolute_path absolute_path_xml, @relative_path, set_directory
    @file_size = disk_size if @file_size.zero? && !@absolute_path.nil?
  end

  # The size of the file on disk.
  #
  # The size in the XML is the size of the source file as Live saw it, and it is sometimes zero even
  # when the file exists and is not empty. See docs/als_format.md section 7.1.
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
        puts "Warning: File path does not exist (from source system): #{constructed_path}\n#{e}".yellow
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

  def show_clip
    modified = @last_modified&.strftime('%Y-%m-%d %H:%M:%S') || ''
    ["    #{@relative_path}", human_file_size(@file_size).rjust(8, ' '), modified]
  end
end
