require_relative 'live_audio_clips_serializer'
require_relative 'live_track_serializer'

# Serializes a `LiveAudioTrack` model as markdown.
#
# It writes the line of the track, and then the devices, the clips and the take lanes under
# it. The clips of the audio side of the track are written by the serializer of that side,
# and each of them says the file it plays, the size of that file, and the place it is in.
#
# Sample usage:
# track = LiveAudioTrack.new(...)
# markdown = LiveAudioTrackSerializer.new(track, number).to_markdown
class LiveAudioTrackSerializer < LiveTrackSerializer
  private

  # The collections of the nodes under the track that are neither its devices, nor its MIDI
  # clips, nor its take lanes.
  #
  # The clips of the audio side of the track come after the MIDI clips of the track.
  #
  # @return [Array<Object>] the collections
  def extra_children
    [audio_clips]
  end

  # The serializer of the clips of the audio side of the track.
  #
  # @return [LiveAudioClipsSerializer] the audio clips
  def audio_clips
    @audio_clips ||= LiveAudioClipsSerializer.new @track.audio_clips, first_audio_clip_number
  end

  # The number of the first clip of the audio side of the track.
  #
  # @return [HierarchicalNumber] the number
  def first_audio_clip_number
    first_clip_number.dup.increment @track.different_clip_count
  end
end
