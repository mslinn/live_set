require_relative '../common/log'
require_relative '../common/xml'

class LiveTrack
  include Xml

  attr_reader :audio_clips, :clip_slots, :id

  def initialize(set_directory, audio_track)
    @audio_track = audio_track
    @id          = @audio_track['Id']
    @frozen      = xml_bool?(@audio_track.at('Freeze'), description: "AudioTrack '#{@id}' Freeze")

    Log.debug "Track #{@id}:"
    Log.debug "  DeviceChain exists: #{!@audio_track.DeviceChain.nil?}"
    Log.debug "  MainSequencer exists: #{!@audio_track.DeviceChain.MainSequencer.nil?}" if @audio_track.DeviceChain
    Log.debug "  ClipSlotList exists: #{!@audio_track.DeviceChain.MainSequencer.ClipSlotList.nil?}" if @audio_track.DeviceChain&.MainSequencer

    # Audit the whole chain, including devices nested inside racks.
    # TODO.md N16: this matches no real set. A survey of 40 sets in $songs found zero <Device/>
    # elements; plugins live in <PluginDevice/> elements instead.
    @devices = @audio_track.search('.//Device').map { |node| LiveDevice.new(node) }

    @clip_slots = @audio_track.DeviceChain.MainSequencer.ClipSlotList
    @audio_clips = define_audio_clips @clip_slots, set_directory
  end

  # The clips in this track, grouped by where they come from.
  #
  # A track's audio can be in the session view, in the arrangement, and in the take lanes. They are
  # separate clips with separate ids, and the same file can be referenced from more than one of
  # them. See docs/als_format.md section 6.
  def define_audio_clips(clip_slots, set_directory)
    {
      'Session view' => session_view_clips(clip_slots, set_directory),
      'Arrangement'  => arrangement_clips(set_directory),
      'Take lanes'   => take_lane_clips(set_directory),
    }
  end

  # The clips in the track's row of session-view slots.
  def session_view_clips(clip_slots, set_directory)
    return [] if clip_slots.nil?

    clip_slots.xpath('./ClipSlot/ClipSlot/Value/AudioClip')
              .map { |node| LiveAudioClip.new(set_directory, node) }
  end

  # The clips on the arrangement timeline.
  def arrangement_clips(set_directory)
    @audio_track.xpath('./DeviceChain/MainSequencer/Sample/ArrangerAutomation/Events/AudioClip')
                .map { |node| LiveAudioClip.new(set_directory, node) }
  end

  # The clips recorded onto the take lanes.
  def take_lane_clips(set_directory)
    @audio_track.xpath('./TakeLanes/TakeLanes/TakeLane/ClipAutomation/Events/AudioClip')
                .map { |node| LiveAudioClip.new(set_directory, node) }
  end

  # The name to display for this track.
  #
  # EffectiveName is the name Ableton resolved, which accounts for renames and for the numbering
  # it adds to duplicate tracks. UserName is the raw name the user typed, and is the only one
  # present in Live 8. Annotation and MemorizedFirstClipName are not names of the track.
  def name
    xml_first_value(
      @audio_track.at('Name/EffectiveName'),
      @audio_track.at('Name/UserName')
    ) || "##{@id}"
  end

  def frozen?
    @frozen
  end

  # Only unfrozen tracks can be blocked by their devices.
  def blocking_devices
    frozen? ? [] : @devices.select(&:blocking?)
  end

  def device_summary
    @devices.map(&:label).uniq.join(', ')
  end

  def clips_collected?
    distinct_clips.all?(&:collected?)
  end

  def show_track(all_frozen)
    name = self.name
    clips = distinct_clips
    frozen = frozen? ? ' frozen'.green : ' **not frozen**'.yellow unless all_frozen || clips.empty?
    size = ", totaling #{human_file_size track_size}" unless clips.empty?
    count = " (#{clips.length} clips, #{distinct_file_count} files#{size})"

    track_line = "Track '#{name}'#{frozen}#{count}"

    return track_line if clips.empty?

    "#{track_line}\n#{show_clips}"
  end

  # The clips in the track, grouped by where they come from.
  #
  # @return [String] a multiline report of the track's clips
  def show_clips
    @audio_clips.filter_map do |source, clips|
      next if clips.empty?

      heading = "  #{source}: #{clips.length} clips, #{clips.uniq(&:absolute_path).length} files"
      [heading, clips.map(&:show_clip).columnize('  ')]
    end.join("\n")
  end

  # The number of distinct files the track's clips refer to.
  #
  # @return [Integer] the number of distinct files
  def distinct_file_count
    distinct_clips.length
  end

  # The size of the track's audio, counting each file once.
  #
  # The same file can be referenced from the session view, the arrangement and the take lanes at the same time. It
  # occupies space once, so it is counted once. See docs/ section 6.4.
  #
  # @return [Integer] the size in bytes
  def track_size
    distinct_clips.sum(&:file_size)
  end

  # The track's clips, with each file counted once.
  #
  # @return [Array<LiveAudioClip>] the distinct clips
  def distinct_clips
    @audio_clips.values.flatten.uniq(&:absolute_path)
  end
end
