require_relative '../model/hierarchical_number'
require_relative 'live_audio_track_serializer'
require_relative 'live_groups_serializer'
require_relative 'live_midi_track_serializer'
require_relative 'live_return_track_serializer'

# Writes the tracks of a set.
#
# The tracks at the top of the set are written in the order Live wrote them, and they are
# numbered from one. The tracks of a group are written by the serializer of the group, under
# the group, and they are numbered after the group.
#
# The numbers of the tracks are made here, and they are the numbers the cross-references of
# the set use, so that a track has one number in the whole report.
#
# Sample usage:
# markdown = LiveTracksSerializer.new(tracks).to_markdown
class LiveTracksSerializer
  # The prefix of the numbers of the tracks.
  PREFIX = 'T'.freeze

  # The serializer of each kind of track.
  TRACK_SERIALIZERS = {
    'Audio'  => LiveAudioTrackSerializer,
    'MIDI'   => LiveMidiTrackSerializer,
    'Return' => LiveReturnTrackSerializer,
  }.freeze

  # Creates a serializer for the tracks of a set.
  #
  # @param tracks [LiveTracks] the tracks of the set
  def initialize(tracks)
    @tracks = tracks
  end

  # Returns the tracks of the set as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    numbered_tracks_of_the_set.map do |number, track|
      serializer_for(track).new(track, number).to_markdown
    end.join("\n")
  end

  # The tracks at the top of the set, with the numbers they have in the report.
  #
  # @return [Array<Array>] the number and the track
  def numbered_tracks_of_the_set
    @numbered_tracks_of_the_set ||= begin
      number = HierarchicalNumber.new PREFIX
      @tracks.top_level_tracks.map do |track|
        [number.dup, track].tap { number.increment }
      end
    end
  end

  # Every track of the set, with the numbers they have in the report.
  #
  # The tracks at the top of the set are numbered from one, and the members of the groups
  # are numbered after the group they are in.
  #
  # @return [Array<Array>] the number and the track
  def numbered_tracks
    @numbered_tracks ||= numbered_tracks_of_the_set + numbered_members
  end

  # The members of the groups of the set, with the numbers they have in the report.
  #
  # @return [Array<Array>] the number and the track
  def numbered_members
    LiveGroupsSerializer.new(@tracks.groups_of_the_set).numbered_members
  end

  private

  # The serializer of a track.
  #
  # @param track [LiveMidiTrack, LiveAudioTrack, LiveReturnTrack] the track
  # @return [Class] the serializer of the kind of the track
  def serializer_for(track)
    TRACK_SERIALIZERS.fetch track.kind
  end
end
