require 'date'

class LiveAudioClip
  # @param audio_clip is an <AudioClip/> element from an Ableton Live .als file as parsed by Nokogiri
  def initialize(audio_clip)
    @audio_clip = audio_clip
    @file_ref = SampleRef.FileRef
    @path = @file_ref.Path['Value']
    @file_size = @file_ref.OriginalFileSize['Value']
    @last_modified = Time.at(SampleRef.LastModDate['Value']).utc.to_datetime
  end

  def show_clip
    "#{@path}  | #{human_file_size @file_size} | #{@last_modified.strftime '%Y%m/%d %H:%M:%S'}"
  end
end
