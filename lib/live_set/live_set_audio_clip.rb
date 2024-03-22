require 'date'
require 'pathname'

class LiveAudioClip
  attr_reader :absolute_path, :file_ref, :file_size, :file_type, :id, :last_modified, :live_pack_name, :need_refreeze, :relative_path,
              :relative_path_type

  # @param audio_clip is an inner <ClipSlot/> element from an Ableton Live .als file as parsed by Nokogiri
  def initialize(set_directory, id, need_refreeze, clip_slot)
    @id                 = id
    @need_refreeze      = need_refreeze

    @audio_clip         = clip_slot.Value.AudioClip
    @file_ref           = @audio_clip.SampleRef.FileRef
    @last_modified      = Time.at(@audio_clip.SampleRef.LastModDate['Value'].to_i).utc.to_datetime

    @file_size          = @file_ref.OriginalFileSize['Value'].to_i
    @file_type          = @file_ref.Type['Value'] # What do these values mean?
    @live_pack_name     = @file_ref.LivePackName['Value']
    @relative_path      = @file_ref.RelativePath['Value']
    @relative_path_type = @file_ref.RelativePathType['Value'] # What do these values mean?

    @absolute_path      = Pathname.new(set_directory).join(@relative_path).realpath
  end

  def collected?
    @relative_path.start_with? 'Samples/Imported/'
  end

  def show_clip
    ["    #{@relative_path}", human_file_size(@file_size).rjust(8, ' '), @last_modified.strftime('%Y-%m-%d %H:%M:%S')]
  end
end
