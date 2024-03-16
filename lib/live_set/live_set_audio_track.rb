class LiveAudioTrack
  # audio_track is an <AudioTrack/> element from an Ableton Live .als file as parsed by Nokogiri
  def initialize(audio_track)
    @audio_track = audio_track
  end

  def show_track(all_frozen)
    name = @audio_track.Name.EffectiveName['Value']
    frozen = !all_frozen && @audio_track.frozen? ? ' **frozen**' : ''
    "#{name}#{frozen}" + show_clips
  end

  def show_clips
    # @audio_track.DeviceChain.FreezeSequencer.ClipSlotList.ClipSlot
    # @audio_track.DeviceChain.Mixer.ClipSlotList.ClipSlot
    # @audio_track.xpath('//Path').map{|x| x['Value']}.uniq # Gives results like:
    #   "E:/media/Ableton/Projects/fu Project/Samples/Processed/Freeze/Freeze Guitar [2024-03-12 133812].wav"
    #   "E:/media/Ableton/Projects/fu Project/Samples/Imported/smooth_operator_horns.mp3"
    #   "/Reverb Default.adv"
    #   "/Users/nsh/Library/Application Support/Ableton/Live 11 Core Library/Devices/Audio Effects/Simple Delay/Dotted Eighth Note.adv"
    #   "E:/media/Ableton/Projects/fu Project/Audio Effects/Color Limiter/Ableton Folder Info/Color Limiter.amxd"
    @audio_track.DeviceChain.MainSequencer.ClipSlotList.ClipSlot.map do |clip_slot|
      clip_paths_sizes = clip_slot.ClipSlot.Value.map do |clip|
        clip.AudioClip.map do |audio_clip|
          audio_clip_path = audio_clip.SampleRef.FileRef.Path['Value']
          audio_clip_size = File.size audio_clip_path
          [audio_clip_path, audio_clip_size]
        end
      end
      track_size = clip_paths_sizes.sum { |_path, size| size }
      return '' if track_size.zero?

      clip_paths = clip_paths_sizes.map { |path, size| "#{path}  #{human_file_size size}" }.join("\n      ")
      human_file_size(track_size) + clip_paths
    end
  end

  def frozen?
    @audio_track.Freeze['Value'].to_bool
  end
end
