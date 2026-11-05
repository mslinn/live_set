require_relative 'live_audio_clips_serializer'
require_relative 'live_devices_serializer'
require_relative 'live_markup'
require_relative 'live_midi_clip_groups'
require_relative 'live_take_lanes_serializer'

# Serializes a `LiveAudioTrack` model as markdown.
#
# It writes the line of the track, and then the devices, the clips and the take lanes under
# it. The clips of the audio side of the track are written by the serializer of that side,
# and each of them says the file it plays, the size of that file, and the place it is in.
#
# Sample usage:
# track = LiveAudioTrack.new(...)
# markdown = LiveAudioTrackSerializer.new(track, '1.1').to_markdown
class LiveAudioTrackSerializer
  # Creates a serializer for the given track.
  #
  # @param track [LiveAudioTrack] the track to be serialized
  # @param hierarchical_number [String] the number of the track in the report
  # @param indent [String] the indentation of the lines of the track
  def initialize(track, hierarchical_number, indent = '')
    @track = track
    @hierarchical_number = hierarchical_number
    @indent = indent
  end

  # Returns the track as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    parts = [track_detail, device_lines, clip_lines.join("\n"), take_lane_lines.join("\n")]
    parts.reject(&:empty?).join "\n"
  end

  private

  # The line of the track: its number, its icon, its kind, its name and its state.
  #
  # @return [String] the line
  def track_detail
    LiveMarkup.track_detail @track, @hierarchical_number
  end

  # The lines of the devices of the track.
  #
  # @return [String] the devices
  def device_lines
    LiveDevicesSerializer.new(@track.devices, @hierarchical_number, slot_label:   'Track Device',
                                                                    indent:       "#{@indent}  ",
                                                                    track_frozen: @track.frozen?).to_markdown
  end

  # The lines of the clips of the track.
  #
  # A track that plays audio can hold MIDI clips as well, and both are written.
  #
  # @return [Array<String>] the lines
  def clip_lines
    lines = LiveMidiClipGroups.new(@track.clips).to_markdown(@hierarchical_number)
    lines += audio_clip_lines
    lines.map { |line| "#{@indent}  #{line}" }
  end

  # The lines of the clips of the audio side of the track.
  #
  # @return [Array<String>] the lines
  def audio_clip_lines
    return [] if @track.audio_clips.empty?

    LiveAudioClipsSerializer.new(@track.audio_clips, @hierarchical_number).to_markdown.split("\n")
  end

  # The lines of the take lanes of the track.
  #
  # @return [Array<String>] the lines
  def take_lane_lines
    return [] if @track.take_lanes.empty?

    serializer = LiveTakeLanesSerializer.new @track.take_lanes, @hierarchical_number, "#{@indent}  "
    serializer.to_markdown.split("\n")
  end
end
