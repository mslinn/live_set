require_relative 'live_track_serializer'

# Serializes a `LiveReturnTrack` model as markdown.
#
# It writes the line of the track, and then the devices under it. A return track holds no
# clips.
#
# Sample usage:
# track = LiveReturnTrack.new(...)
# markdown = LiveReturnTrackSerializer.new(track, number).to_markdown
class LiveReturnTrackSerializer < LiveTrackSerializer
end
