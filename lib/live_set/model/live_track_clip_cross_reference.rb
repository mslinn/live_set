require_relative '../serializer/live_markup'

# The tracks of a set and the clips they hold, and the clips of the set and the tracks that
# hold them.
#
# The clips are the clips of the outline: the MIDI clips and the clips of the audio side of
# the tracks. A clip is the same clip when it has the same name, the same file, the same
# colour and the same state. A clip that is on more than one track is a clip the set shares,
# and it is marked as one.
class LiveTrackClipCrossReference
  attr_reader :tracks

  # @param tracks [LiveTracks] the tracks of the set
  def initialize(tracks)
    @tracks = tracks
  end

  # The places the clips of a track are in, and how many of them there are in each.
  #
  # The clips of the take lanes of the track are the clips of the track as well, and are
  # marked with the lane they are in.
  #
  # @param track [LiveTrack] the track
  # @param number [String] the number of the track
  # @return [Hash] each clip, the places it is in, and the number of them in each
  def places_of(track, number)
    return {} if track.group?

    places = Hash.new { |hash, key| hash[key] = Hash.new(0) }

    track.clips.each { |clip| places[label_of(clip)][clip.place] += 1 }
    track.audio_clips.each { |clip| places[label_of(clip)][place_of(clip, number)] += 1 }
    track.take_lanes.each_with_index do |lane, index|
      lane_number = "#{number}.#{index + 1}"
      lane.clips.each { |clip| places[label_of(clip)]["take lane #{lane_number}"] += 1 }
    end

    places
  end

  # The tracks that hold each clip of the set.
  #
  # A track that holds a clip in its take lanes as well as in itself is one entry, and the
  # lanes it holds the clip in are named with it.
  #
  # @return [Hash] each clip, and the tracks that hold it
  def tracks_of_clips
    uses = Hash.new { |hash, key| hash[key] = {} }

    tracks.each_numbered_track do |number, track|
      next if track.group?

      name = LiveMarkup.display_name track
      track.clips.each { |clip| holds_of uses, label_of(clip), number, name }
      track.audio_clips.each { |clip| holds_of uses, label_of(clip), number, name, lane_of(clip, number) }
      holds_of_lanes uses, track, number, name
    end

    uses.transform_values do |holds|
      holds.map do |number, hold|
        lanes = hold[:lanes].empty? ? '' : " (take lane #{hold[:lanes].join(', ')})"
        "#{number} #{hold[:name]}#{lanes}"
      end
    end
  end

  # The name of a clip, as the cross-reference names it.
  #
  # @param clip [LiveMidiClip, LiveAudioClip] the clip
  # @return [String] the name
  def label_of(clip)
    clip.label
  end

  # The place a clip is in, as the cross-reference names it.
  #
  # The clip of the audio side of a track says which lane of the track it is in, and the
  # number of the track is added to it here.
  #
  # @param clip [LiveMidiClip, LiveAudioClip] the clip
  # @param number [String] the number of the track
  # @return [String] the place
  def place_of(clip, number)
    place = clip.place
    return place unless place&.start_with? 'take lane '

    "take lane #{number}.#{place.split.last}"
  end

  # The number of the lane a clip is in, as the cross-reference names it.
  #
  # @param clip [LiveMidiClip, LiveAudioClip] the clip
  # @param number [String] the number of the track
  # @return [String, nil] the number of the lane, or nil when the clip is in no lane
  def lane_of(clip, number)
    place = clip.place
    return nil unless place&.start_with? 'take lane '

    "#{number}.#{place.split.last}"
  end

  private

  # The record of a track that holds a clip.
  #
  # @param uses [Hash] the clips and the tracks that hold them
  # @param label [String] the name of the clip
  # @param number [String] the number of the track
  # @param name [String] the name of the track
  # @param lane [String, nil] the number of the lane the clip is in, or nil
  # @return [Hash] the record of the track
  def holds_of(uses, label, number, name, lane = nil)
    hold = uses[label][number] ||= { name: name, lanes: [] }
    hold[:lanes] << lane unless lane.nil? || hold[:lanes].include?(lane)
    hold
  end

  # The take lanes of a track, and the clips of them.
  #
  # @param uses [Hash] the clips and the tracks that hold them
  # @param track [LiveTrack] the track
  # @param number [String] the number of the track
  # @param name [String] the name of the track
  # @return [void]
  def holds_of_lanes(uses, track, number, name)
    track.take_lanes.each_with_index do |lane, index|
      lane_number = "#{number}.#{index + 1}"
      lane.clips.each do |clip|
        hold = holds_of uses, label_of(clip), number, name
        hold[:lanes] << lane_number unless hold[:lanes].include? lane_number
      end
    end
  end
end
