class LiveAudioTrack
  attr_reader :audio_clips, :clip_slots, :frozen, :id, :track_size

  def initialize(set_directory, audio_track)
    @audio_track = audio_track
    @id          = @audio_track['Id']
    @frozen      = @audio_track.at('Freeze')&.[]('Value')&.to_bool

    Log.debug "Track #{@id}:"
    Log.debug "  DeviceChain exists: #{!!@audio_track.DeviceChain}"
    Log.debug "  MainSequencer exists: #{!!@audio_track.DeviceChain.MainSequencer}" if @audio_track.DeviceChain
    Log.debug "  ClipSlotList exists: #{!!@audio_track.DeviceChain.MainSequencer.ClipSlotList}" if @audio_track.DeviceChain&.MainSequencer

    # Audit the whole chain, including devices nested inside racks.
    @devices = @audio_track.search('.//Device').map { |node| LiveDevice.new(node) }

    @clip_slots = @audio_track.DeviceChain.MainSequencer.ClipSlotList
    @audio_clips = define_audio_clips @clip_slots, set_directory
    @track_size = @audio_clips.sum { |clip| clip.file_size.to_i }
  end

  def define_audio_clips(clip_slots, set_directory)
    clip_slots.ClipSlot.filter_map do |clip_slot|
      inner = clip_slot.ClipSlot
      next unless inner.respond_to?(:Value) && !inner.Value.children.empty?

      LiveAudioClip.new(set_directory, clip_slot['Id'],
                        clip_slot.NeedRefreeze['Value'].to_bool, inner)
    end
  end

  def name
    @audio_track.at('Name/EffectiveName')&.[]('Value') ||
      @audio_track.at('Name')&.text ||
      "##{@id}"
  end

  def frozen?
    @frozen
  end

  # Only unfrozen tracks can be blocked by their devices.
  def blocking_devices
    @frozen ? [] : @devices.select(&:blocking?)
  end

  def device_summary
    @devices.map(&:label).uniq.join(', ')
  end

  def clips_collected?
    @audio_clips.all?(&:collected?)
  end

  def show_track(all_frozen)
    name = @audio_track.Name.EffectiveName['Value']
    frozen = @audio_track.frozen? ? ' frozen'.green : ' **not frozen**'.yellow unless all_frozen || @audio_clips.empty?
    size = ", totaling #{human_file_size @track_size}" unless @audio_clips.empty?

    track_line = "Track '#{name}'#{frozen} (#{@audio_clips.length} clips#{size})"

    # Only add clips if there are any
    if @audio_clips.empty?
      track_line
    else
      "#{track_line}\n#{show_clips}"
    end
  end

  def show_clips
    return '' if @track_size.zero?

    @audio_clips.map(&:show_clip).columnize '  '
  end
end
