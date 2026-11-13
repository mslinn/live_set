require_relative '../model/hierarchical_number'
require_relative 'live_audio_track_serializer'
require_relative 'live_collection_serializer'
require_relative 'live_groups_serializer'
require_relative 'live_midi_track_serializer'
require_relative 'live_return_track_serializer'

# Writes the tracks of a set.
#
# The tracks at the top of the set are written in the order they appear in the file, and they
# are numbered from one. The tracks of a group are written by the serializer of the group,
# under the group, and they are numbered after the group.
#
# The numbers of the tracks are made here, and they are the numbers the cross-references of
# the set use, so that a track has one number in the whole report.
#
# Sample usage:
# markdown = LiveTracksSerializer.new(tracks).to_markdown
class LiveTracksSerializer < LiveCollectionSerializer
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
    super()
    @tracks = tracks
  end

  # Returns the tracks at the top of the set of the given kind.
  #
  # The tracks keep the numbers they have in the whole of the report, so that a track has
  # one number in the whole report, whichever way the tracks are shown.
  #
  # @param kind [String] the kind of the tracks: 'Audio', 'MIDI', 'Return'
  # @param format [Symbol] the format the tracks are written in
  # @return [String] the tracks, written
  def tracks_of_kind(kind, format)
    numbered_tracks_of_kind(kind).map do |number, track|
      serializer_for(number, track).public_send(format)
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

  # The tracks at the top of the set of the given kind.
  #
  # @param kind [String] the kind of the tracks: 'Audio', 'MIDI', 'Return'
  # @return [Array<Array>] the number and the track
  def numbered_tracks_of_kind(kind)
    numbered_tracks_of_the_set.select { |_number, track| track.kind == kind }
  end

  # The tracks at the top of the set, with the numbers they have in the report.
  #
  # @return [Array<Array>] the number and the track
  def items
    numbered_tracks_of_the_set
  end

  # The serializer of a track.
  #
  # @param number [HierarchicalNumber] the number of the track
  # @param track [LiveMidiTrack, LiveAudioTrack, LiveReturnTrack] the track
  # @return [Object] the serializer of the track
  def serializer_for(number, track)
    TRACK_SERIALIZERS.fetch(track.kind).new track, number
  end
end
