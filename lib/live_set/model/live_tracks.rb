require_relative 'live_audio_tracks'
require_relative 'live_group'
require_relative 'live_groups'
require_relative 'live_midi_tracks'
require_relative 'live_return_tracks'

# The tracks of a set, defined in the `<Tracks>` element of ALS XML.
#
# The element holds the MIDI tracks, the audio tracks, the return tracks and the group tracks of the set, and each of
# them is a collection of its own.  This class also holds the ids of the tracks, in the order Live wrote them, so that
# the tracks can be serialized in the same order by the associated serializer class.
#
# This class deviates from the usual pattern in that it has three kinds of children, each of which is a collection:
#
# 1. MIDI tracks
# 2. Audio tracks
# 3. Group tracks and nested group tracks
#
# The master track of the set is a special entity and is not considered to be one of the tracks of the set because it is
# a child of the set. The master track is therefore not part of this class.
#
# In an ALS XML structure, the <GroupTrack/> element represents is a submixer that contains a collection of child tracks
# (such as Audio, MIDI, and nested Group Tracks). Its functionality includes:
#
# - Submixer Routing Hub: It houses its own mixer section (volume, pan, sends, track activator/mutes) that aggregates
#   the audio or MIDI output of all member tracks nested beneath or assigned to it before passing the signal down to the
#   Master or a parent group.
# - Hierarchical Container: It maintains the structural hierarchy of the Live Set, holding a collection of member tracks
#   and determining how tracks are visually collapsed or expanded in the user interface.
# - Device Chain Hosting: Like standard audio or MIDI tracks, a GroupTrack contains a DeviceChain element, allowing
#   users to load native or VST/Audio Unit effect plugins (like compressors, EQs, or saturation) to process the entire
#   grouped bus collectively.
# - Automation Target: It stores global envelope and automation data (AutomationTarget, clip envelopes, etc.) that
#   affect parameters belonging to the group container as a whole, such as group-level volume fades or device
#   parameters.
class LiveTracks
  attr_reader :audio_tracks, :groups, :midi_tracks, :return_tracks, :track_ids

  # @param set_directory [String] the directory of the set
  # @param elements [Array<Nokogiri::XML::Element>] the track elements of the set, in the
  #   order Live wrote them
  def initialize(set_directory, elements)
    @elements = elements
    @track_ids = elements.map { |element| element['Id'] }
    @midi_tracks = LiveMidiTracks.new elements_of(elements, 'MidiTrack')
    @audio_tracks = LiveAudioTracks.new set_directory, elements_of(elements, 'AudioTrack')
    @return_tracks = LiveReturnTracks.new set_directory, elements_of(elements, 'ReturnTrack')
    @groups = LiveGroups.new(
      elements_of(elements, 'GroupTrack').map { |element| LiveGroup.new element, elements, set_directory }
    )
  end

  # Every track of the set, by its id.
  #
  # @return [Hash] the id of the track, and the track
  def tracks_by_id
    @tracks_by_id ||= (midi_tracks.to_a + audio_tracks.to_a + return_tracks.to_a)
                      .to_h { |track| [track.id, track] }
  end

  # The groups of the set: the groups that are at the top of it.
  #
  # @return [LiveGroups] the groups
  def groups_of_the_set
    LiveGroups.new(groups.to_a.select { |group| group.group_id.nil? })
  end

  # The tracks at the top of the set, in the order Live wrote them.
  #
  # The tracks of a group are written under their group, and not here.
  #
  # @return [Array<LiveMidiTrack, LiveAudioTrack, LiveReturnTrack>] the tracks
  def top_level_tracks
    @top_level_tracks ||= track_ids.filter_map { |id| tracks_by_id[id] }
                                   .select { |track| track.group_id.nil? }
  end

  # The groups and the tracks at the top of the set.
  #
  # @return [Array<LiveGroup, LiveMidiTrack, LiveAudioTrack, LiveReturnTrack>] the tracks
  def top_level
    groups_of_the_set.to_a + top_level_tracks
  end

  # The audio clips of the set.
  #
  # The audio of the set is in these clips, and the files they play are the samples of the
  # set.
  #
  # @return [Array<LiveAudioClip>] the clips
  def audio_clips
    audio_tracks.audio_clips
  end

  # The clips of the set that have not been collected.
  #
  # The clips that are not collected are counted and not named: a demo set holds dozens of
  # them, and the list of them says nothing that the count does not.
  #
  # @return [Array<String>] the paths of the clips
  def uncollected_clips
    audio_tracks.flat_map do |track|
      track.distinct_clips.reject(&:collected?).filter_map(&:absolute_path).uniq
    end
  end

  # The tracks of the set that cannot be transferred to P3S Standalone.
  #
  # A third-party device on a track that is not frozen. A MIDI track has the same devices as
  # an audio track, and the same problems: the P3S Standalone cannot run a plug-in on a MIDI
  # track either, and freezing the track renders it away.
  #
  # The clips that have not been collected are counted, and are not among these.
  #
  # @return [Array<Array>] the track, and the devices that stop it
  def blocking_tracks
    all_tracks.filter_map do |track|
      devices = track.blocking_devices
      next if devices.empty?

      [track, devices]
    end
  end

  # The groups of the set that cannot be transferred to P3S Standalone.
  #
  # The output of a group track's members are routed to the group, so the group's devices
  # process the members' audio. If a group's device chain contains a non-native device (like
  # VST2 or VST3), the set is incompatible with the P3S Standalone.
  #
  # Normally, only tracks capable of holding clips can frozen, so normally a group track
  # cannot be frozen. This means a non-native device on a group track cannot be rendered away
  # by freezing the group. However, an Ableton Live option permits the creation of frozen
  # group tracks. See [Options.txt](docs/als_work.md).
  #
  # See docs/als_notes.md, "Group Device Chain".
  #
  # @return [Array<Array>] the group, the devices that stop it, and the names of the tracks
  #   whose audio they affect
  def blocking_groups
    groups.filter_map do |group|
      devices = group.blocking_devices
      next if devices.empty?

      [group, devices, group.affected_track_names]
    end
  end

  # The tracks of the set that use a Max for Live device.
  #
  # A Max for Live device is supported by the P3S Standalone, but with less CPU headroom,
  # so it is advice and not an error. A frozen track has its devices rendered away, so it is
  # not among these.
  #
  # @return [Array<Array>] the track, and the devices
  def max_for_live_tracks
    all_tracks.filter_map do |track|
      next if track.frozen?

      devices = track.max_for_live_devices
      next if devices.empty?

      [track, devices]
    end
  end

  # The groups of the set that use a Max for Live device.
  #
  # A Max for Live device is supported by the P3S Standalone, but with less CPU headroom,
  # so it is advice and not an error. A group cannot be frozen, so its devices cannot be
  # rendered away.
  #
  # @return [Array<Array>] the group, and the devices
  def max_for_live_groups
    groups.filter_map do |group|
      devices = group.max_for_live_devices
      next if devices.empty?

      [group, devices]
    end
  end

  # The clips of the session view.
  #
  # The P3S Standalone is made for the Session View: a set that has no clip in the session
  # view has nothing for it to launch. A set loads and plays in Standalone Mode, but the
  # Arrangement View cannot be edited there.
  #
  # @return [Array<LiveClip>] the clips
  def session_view_clips
    all_tracks.flat_map do |track|
      track.clips.select { |clip| clip.place == 'session view' } +
        track.audio_clips.select { |clip| clip.place == 'session view' }
    end
  end

  private

  # Every track of the set: the MIDI tracks, the audio tracks and the return tracks.
  #
  # @return [Array<LiveTrack>] the tracks
  def all_tracks
    @all_tracks ||= midi_tracks.to_a + audio_tracks.to_a + return_tracks.to_a
  end

  # The elements of one kind of track.
  #
  # @param elements [Array<Nokogiri::XML::Element>] the track elements of the set
  # @param name [String] the name of the element
  # @return [Array<Nokogiri::XML::Element>] the elements
  def elements_of(elements, name)
    elements.select { |element| element.name == name }
  end
end
