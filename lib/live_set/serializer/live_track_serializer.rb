# TODO: This is a placeholder to start off the changes described as TODO comments in lib/live_set/live_palette.rb
# TODO Write unit tests
#
# Serializes a LiveTrack model as markdown by serializing each member.
#
# Sample usage:
# track = LiveTrack.new(...)
# markdown = LiveTrackSerializer.new(track).to_markdown
class LiveTrackSerializer
  # Creates a serializer for the given track.
  #
  # @param track [LiveTrack] the track to serialize
  def initialize(track)
    @track = track
  end

  # Returns the track as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    # TODO: finish writing me.

    # Serialize clip references associated with a track. Similar code needs to be
    # written for take lanes and arrangement view:
    clips_markdown = @track.clip_references.map do |clip_reference|
      LiveClipReferenceSerializer.new(clip_reference).to_markdown
    end.join("\n")

    # Serialize devices associated with a track
    track_devices_markdown = @track.clip_references.map do |track|
      LiveDeviceSerializer.new(track.devices).to_markdown
    end.join("\n")

    # TODO: include header line, e.g.: Track 1.1 🎹 MIDI Kontakt 7
    <<~END_MARKDOWN
      #{group_track_devices_markdown}
      #{track_devices_markdown}
      #{clips_markdown}
    END_MARKDOWN
  end
end
