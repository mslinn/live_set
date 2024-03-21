class LiveAudioTrack
  attr_reader :frozen, :track_size

  # @param audio_track is an <AudioTrack/> element from an Ableton Live .als file as parsed by Nokogiri
  def initialize(audio_track)
    @audio_track = audio_track
    @id = @audio_track['Id']

    @frozen = @audio_track.Freeze['Value'].to_bool

    @clip_slots = @audio_track.DeviceChain.MainSequencer.ClipSlotList
    @audio_clips = @clip_slots.ClipSlot.map do |clip_slot|
      clip_slot_id = clip_slot['Id']
      need_refreeze = clip_slot.NeedRefreeze['Value'].to_bool
      inner_clip_slot = clip_slot.ClipSlot
      LiveAudioClip.new clip_slot_id, need_refreeze, inner_clip_slot if inner_clip_slot.respond_to?(:Value) && !inner_clip_slot.Value.children.empty?
    end
    @audio_clips.compact!
    @track_size = @audio_clips.sum(&:file_size) || 0
  end

  def clips_collected?
    @audio_clips.all?(&:collected?)
  end

  def show_track(all_frozen)
    name = @audio_track.Name.EffectiveName['Value']
    frozen = !all_frozen && @audio_track.frozen? ? ' **frozen**' : ''
    "Track '#{name}'#{frozen} (#{@audio_clips.length} clips, totaling #{human_file_size @track_size})\n" + show_clips
  end

  def show_clips
    return '' if @track_size.zero?

    result = @audio_clips.map(&:show_clip)
    result.columnize '  '
  end
end
