class LiveAudioTrack
  # @param audio_track is an <AudioTrack/> element from an Ableton Live .als file as parsed by Nokogiri
  def initialize(audio_track)
    @audio_track = audio_track
    @id = @audio_track['Id']

    @frozen = @audio_track.Freeze['Value'].to_bool

    @audio_clips = @audio_track.DeviceChain.MainSequencer.ClipSlotList.ClipSlot.map do |clip_slot|
      clip_slot.map(&:LiveAudioClip.new)
    end
    @track_size = @audio_clips.sum(&:file_size) || 0
  end

  def show_track(all_frozen)
    name = @audio_track.Name.EffectiveName['Value']
    frozen = !all_frozen && @audio_track.frozen ? ' **frozen**' : ''
    "#{name}#{frozen}" + show_clips
  end

  def show_clips
    return '' if @track_size.zero?

    @audio_clips.map(&:show_clip).join("\n      ")
  end
end
