require 'colorator'
require 'date'
require 'pathname'

class LiveAudioClip
  attr_reader :absolute_path, :file_ref, :file_size, :file_type, :id, :last_modified, :live_pack_name, :need_refreeze, :relative_path,
              :relative_path_type

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

    @file_size          = @file_ref.at('OriginalFileSize')&.[]('Value')&.to_i
    @file_type          = @file_ref.at('Type')&.[]('Value')
    @live_pack_name     = @file_ref.at('LivePackName')&.[]('Value')

    # Check for RelativePath first, then fall back to an absolute Path node
    @relative_path      = @file_ref.at('RelativePath')&.[]('Value')
    @absolute_path_xml  = @file_ref.at('Path')&.[]('Value')
    @relative_path_type = @file_ref.at('RelativePathType')&.[]('Value')

    @absolute_path = compute_absolute_path @absolute_path_xml, @relative_path, set_directory
  end

  def compute_absolute_path(absolute_path_xml, relative_path, set_directory)
    if relative_path && set_directory
      constructed_path = Pathname.new(set_directory).join(relative_path)
      begin
        constructed_path.realpath.to_s
      rescue Errno::ENOENT, Errno::ELOOP => e
        puts "Warning: File path does not exist (from source system): #{constructed_path}\n#{e}".yellow
        constructed_path.to_s
      end
    elsif @absolute_path_xml
      # Fallback to the absolute path stored in the XML if RelativePath is missing
      absolute_path_xml
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
