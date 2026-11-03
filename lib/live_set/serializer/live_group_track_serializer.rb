# TODO: This is a placeholder to start off the changes described as TODO comments in lib/live_set/live_palette.rb
# TODO Write unit tests
#
# Serializes a `LiveGroupTrack` model as markdown by serializing each member track.
#
# Assuming a `LiveGroupTrack` exposes member tracks through `tracks`, the group serializer can delegate each track to
# LiveTrackSerializer.
#
# Sample usage:
# group_track = LiveGroupTrack.new(...)
# markdown = LiveGroupTrackSerializer.new(group_track).to_markdown
class LiveGroupTrackSerializer
  # Creates a serializer for the given group track.
  #
  # @param group_track [LiveGroupTrack] the group track to serialize
  def initialize(group_track)
    @group_track = group_track
  end

  # Returns the group and its member tracks as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    tracks_markdown = @group_track.tracks.map do |track|
      LiveTrackSerializer.new(track).to_markdown
    end.join("\n")

    group_track_devices_markdown = @group_track.devices.map do |device|
      LiveDeviceSerializer.new(device).to_markdown
    end.join("\n")

    # TODO: include header line, e.g.: Group track 1 👥 Group # Drums
    <<~END_MARKDOWN
      #{group_track_devices_markdown}
      #{tracks_markdown}
    END_MARKDOWN
  end
end
