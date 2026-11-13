require_relative 'live_track_serializer'

# Serializes a `LiveMidiTrack` model as markdown.
#
# It writes the line of the track, and then the devices, the clips and the take lanes under
# it.
#
# The devices, the clips and the take lanes of the track are numbered in one sequence among
# themselves, so that the number of a node says where it is in the outline.
#
# Sample usage:
# track = LiveMidiTrack.new(...)
# markdown = LiveMidiTrackSerializer.new(track, number).to_markdown
class LiveMidiTrackSerializer < LiveTrackSerializer
end
