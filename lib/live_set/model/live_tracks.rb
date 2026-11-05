require_relative 'live_audio_tracks'
require_relative 'live_group'
require_relative 'live_groups'
require_relative 'live_midi_tracks'
require_relative 'live_return_tracks'

# The tracks of a set: the `<Tracks>` element of the XML.
#
# The element holds the MIDI tracks, the audio tracks, the return tracks and the group
# tracks of the set, and each of them is a collection of its own.
#
# The class deviates from the usual pattern in that it has two kinds of child: the MIDI
# tracks and the audio tracks. It also holds the ids of the tracks, in the order Live wrote
# them, so that the tracks can be written in that order.
#
# The master track of the set is a child of the set and not of the tracks of the set, so it
# is not here.
class LiveTracks
  attr_reader :audio_tracks, :groups, :midi_tracks, :return_tracks, :track_ids

  # @param set_directory [String] the directory of the set
  # @param elements [Array<Nokogiri::XML::Element>] the track elements of the set, in the
  #   order Live wrote them
  def initialize(set_directory, elements)
    @elements = elements
    @track_ids = elements.map { |element| element['Id'] }
    @midi_tracks = LiveMidiTracks.new set_directory, elements_of(elements, 'MidiTrack')
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

  # The tracks at the top of the set, with the number each of them has in the report.
  #
  # The tracks are numbered in the order Live wrote them, so that the numbers of the tracks
  # of the set are unique in the report. The groups are numbered among themselves, and a
  # group and a track are numbered in their own company.
  #
  # @return [Array<Array>] the number of the track, and the track
  def numbered_tracks_of_the_set
    @numbered_tracks_of_the_set ||= top_level_tracks.each_with_index.map do |track, index|
      [(index + 1).to_s, track]
    end
  end

  # The markdown of the tracks of the set.
  #
  # The tracks are written in the order Live wrote them. When they are to be shown
  # separately, the audio tracks and the MIDI tracks are written in their own lists, and
  # the caller writes the heading of each.
  #
  # @param separately [Boolean] whether the two kinds of track are written in their own
  #   lists
  # @param indent [String] the indentation of the lines
  # @return [String] the markdown
  def to_markdown(separately: false, indent: '')
    return separate_markdown(indent) if separately

    ordered_markdown(indent)
  end

  # Every track of the set, with the number it has in the report.
  #
  # The tracks at the top of the set are numbered from one, and the tracks of a group are
  # numbered after the group, as 1.1.
  #
  # The XML has no notion of a track number, so the number is made here, and it is not held
  # by the model.
  #
  # @yieldparam number [String] the number of the track
  # @yieldparam track [LiveMidiTrack, LiveAudioTrack] the track
  # @return [void]
  def each_numbered_track(&)
    numbered_tracks_of_the_set.each(&)

    groups.each_with_index do |group, index|
      group.tracks.each_with_index do |member, position|
        yield "#{index + 1}.#{position + 1}", member
      end
    end
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

  # The errors that stop a set from being transferred.
  #
  # A third-party device on an unfrozen track or in a group's chain. The clips that have not
  # been collected are counted, and are not errors here.
  #
  # @return [Array<String>] the errors
  def p3s_errors
    audio_tracks.flat_map { |track| track_errors(track) } + group_errors
  end

  # The advice about a set that can be transferred.
  #
  # Advice is not an error and does not change the verdict: an unfrozen track that uses only
  # native devices.
  #
  # @return [Array<String>] the advice
  def p3s_advice
    advice = []
    audio_tracks.each do |track|
      next if track.frozen? || track.distinct_clips.empty? || track.device_summary.empty?

      advice << "Track '#{track.name}' is unfrozen; devices: #{track.device_summary}"
    end
    advice
  end

  private

  # The tracks of the set, in the order Live wrote them.
  #
  # @param indent [String] the indentation of the lines
  # @return [String] the markdown
  def ordered_markdown(indent)
    numbered_tracks_of_the_set.map do |number, track|
      track.to_markdown number, indent
    end.join("\n")
  end

  # The audio tracks and the MIDI tracks of the set, in their own lists.
  #
  # @param indent [String] the indentation of the lines
  # @return [String] the markdown
  def separate_markdown(indent)
    [audio_tracks.to_markdown(nil, 1, indent), midi_tracks.to_markdown(nil, 1, indent)]
      .reject(&:empty?).join("\n")
  end

  # The elements of one kind of track.
  #
  # @param elements [Array<Nokogiri::XML::Element>] the track elements of the set
  # @param name [String] the name of the element
  # @return [Array<Nokogiri::XML::Element>] the elements
  def elements_of(elements, name)
    elements.select { |element| element.name == name }
  end

  # The errors caused by one track.
  #
  # @param track [LiveAudioTrack] the track
  # @return [Array<String>] the errors
  def track_errors(track)
    track.blocking_devices.map do |device|
      " - Track '#{track.name}' is unfrozen and uses #{device.label}, " \
        'which Push 3 Standalone cannot run. Freeze or render this track.'
    end
  end

  # The errors caused by the devices in the groups' chains.
  #
  # A group track's members are routed to the group, so the group's devices process the members'
  # audio. A plug-in in a group's chain therefore blocks a transfer to Push 3 Standalone just as
  # much as one on a track.
  #
  # A group track cannot be frozen — only tracks that hold clips can be — so the device cannot be
  # rendered away by freezing the group. Freezing a member does not help either: a frozen member
  # stays routed into its group, so the group's device is still in the signal path. The remedy is
  # to remove the device from the group's chain.
  #
  # The error names the tracks whose audio the device affects, so the user knows which ones are
  # involved.
  #
  # See docs/als_notes.md, "The device chain of a group".
  #
  # @return [Array<String>] the errors
  def group_errors
    groups.flat_map do |group|
      affected = affected_track_names group
      group.blocking_devices.map do |device|
        message = " - Group '#{group.name}' uses #{device.label}, which Push 3 Standalone cannot run. " \
                  "Remove it from the group's device chain, or bounce the group."
        message += " It affects #{affected}." unless affected.empty?
        message
      end
    end
  end

  # The names of the tracks whose audio passes through a group.
  #
  # A member track's output is routed to the group, so the group's devices process its audio. A
  # member that has been routed somewhere else — to an external output, say — is not affected.
  #
  # The names are de-duplicated, because the tracks in a group often share a name. Ableton numbers
  # a track's name when it is duplicated, but a group of clips recorded from the same source can
  # end up with the same name on every track.
  #
  # @param group [LiveGroup] the group
  # @return [String] a comma-separated list of track names
  def affected_track_names(group)
    group.members
         .select { |track| track.at('DeviceChain/AudioOutputRouting/Target')&.[]('Value') == 'AudioOut/GroupTrack' }
         .filter_map { |track| group.track_name track }
         .uniq
         .join(', ')
  end
end
