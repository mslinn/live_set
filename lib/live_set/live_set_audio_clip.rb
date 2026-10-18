require 'colorator'
require 'date'
require 'pathname'

class LiveAudioClip
  attr_reader :absolute_path, :file_ref, :file_size, :file_type, :id, :last_modified, :live_pack_name, :need_refreeze, :relative_path,
              :relative_path_type

  # Ableton Live 8.2.6's XML structure has a quirk depending on the data type:
  # - Integers/Booleans use attributes: <HasRelativePath Value="true" /> (['Value'] code works for these).
  # - Strings/Paths use nested text nodes: <Path><Path>C:\Music\sample.wav</Path></Path>
  # Because paths are stored as text inside nested tags, calling ['Value'] on them returns nil.
  # We must use .text to extract the actual path string.
  # Additionally, in older versions of Live (like Live 8), the file size tag is often <FileSize> instead of <OriginalFileSize>.
  #
  # Sometimes Ableton stores the absolute path in a <Path> node instead of <RelativePath>.
  # @param audio_clip is an inner <ClipSlot/> element from an Ableton Live .als file as parsed by Nokogiri
  # @return the absolute path to a referenced clip, or nil if the clip is not stored in a file.
  # Not all clips contain audio samples:
  # - MIDI clips do not have audio files.
  # - Empty clip slots have no associated files.
  # - Internal devices and resampled clips reference internal Ableton data rather than external files.
  def initialize(set_directory, id, need_refreeze, clip_slot)
    @id                 = id
    @need_refreeze      = need_refreeze

    @audio_clip         = clip_slot.Value.AudioClip
    @file_ref           = @audio_clip.SampleRef.FileRef
    @last_modified      = Time.at(@audio_clip.SampleRef.LastModDate['Value'].to_i).utc.to_datetime

    # File size: Check both OriginalFileSize (newer Live) and FileSize (Live 8)
    size_node = @file_ref.at('OriginalFileSize') || @file_ref.at('FileSize')
    @file_size = size_node ? (size_node['Value'] || size_node.text).to_i : 0

    @file_type          = @file_ref.at('Type')&.[]('Value')
    @live_pack_name     = @file_ref.at('LivePackName')&.[]('Value')

    # PATHS: Ableton stores paths as text inside nested tags (e.g., <Path><Path>actual/path</Path></Path>).
    # We must use `.text` instead of `['Value']` to extract them.
    rel_path_node = @file_ref.at('RelativePath/RelativePath/Path') || @file_ref.at('RelativePath')
    @relative_path = rel_path_node&.text

    abs_path_node = @file_ref.at('Path/Path') || @file_ref.at('Path')
    @absolute_path_xml = abs_path_node&.text

    @relative_path_type = @file_ref.at('RelativePathType')&.[]('Value')

    @absolute_path = compute_absolute_path @absolute_path_xml, @relative_path, set_directory
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
    ["    #{@relative_path}", human_file_size(@file_size).rjust(8, ' '), @last_modified.strftime('%Y-%m-%d %H:%M:%S')]
  end
end
