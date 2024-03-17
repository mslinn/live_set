require 'date'

class LiveAudioClip
  # @param audio_clip is an outer <ClipSlot/> element from an Ableton Live .als file as parsed by Nokogiri
  def initialize(clip_slot)
    @need_refreeze      = clip_slot.NeedRefreeze['Value']
    @audio_clip         = clip_slot.ClipSlot['Value']

    @id                 = @audio_clip['Id']

    @file_ref           = @audio_clip.SampleRef.FileRef

    @last_modified      = Time.at(@audio_clip.SampleRef.LastModDate['Value']).utc.to_datetime

    @absolute_path      = @file_ref.Path['Value']
    @file_size          = @file_ref.OriginalFileSize['Value']
    @file_type          = @file_ref.Type['Value'] # What do these values mean?
    @live_pack_name     = @file_ref.LivePackName['Value']
    @relative_path      = @file_ref.RelativePath['Value']
    @relative_path_type = @file_ref.RelativePathType['Value'] # What do these values mean?
  end

  def show_clip
    "#{@relative_path}  | #{human_file_size @file_size} | #{@last_modified.strftime '%Y%m/%d %H:%M:%S'}"
  end
end
