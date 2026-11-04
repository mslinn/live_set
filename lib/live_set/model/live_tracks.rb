require_relative 'live_group'
require_relative 'live_track'

class LiveTracks
  # The tracks of the set.
  #
  # @param set_directory [String] the directory of the set
  # @param elements [Array<Nokogiri::XML::Element>] the elements of the tracks of the set, in
  #   the order Live wrote them
  def initialize(set_directory, elements)
    @instances = elements.map do |element|
      if element.name == 'GroupTrack'
        LiveGroup.new element, elements, set_directory
      else
        LiveTrack.new set_directory, element
      end
    end
  end

  # The tracks at the top of the set, in the order Live wrote them.
  #
  # @return [Array<LiveTrack, LiveGroup>] the groups, and the tracks that are in no group
  def top_level
    @instances.select { |track| track.group_id.nil? }
  end

  # The tracks at the top of the set, with the number each of them has in the report.
  #
  # The groups are numbered from one among themselves, and the tracks are numbered from one
  # among themselves: a group and a track are numbered in their own company.
  #
  # @return [Array<Array>] the number of the track, and the track
  def top_level_numbered
    groups = 0
    others = 0

    top_level.map do |track|
      if track.group?
        groups += 1
        [groups.to_s, track]
      else
        others += 1
        [others.to_s, track]
      end
    end
  end

  # Every track of the set, with the number it has in the report.
  #
  # The groups at the top of the set are numbered from one, and the tracks at the top of the
  # set are numbered from one as well: a group and a track are numbered in their own company.
  # The tracks of a group are numbered after the group, as 1.1.
  #
  # The XML has no notion of a track number, so the number is made here, and it is not held
  # by the model.
  #
  # @yieldparam number [String] the number of the track
  # @yieldparam track [LiveTrack, LiveGroup] the track
  # @return [void]
  def each_numbered_track
    groups = 0
    others = 0

    top_level.each do |track|
      if track.group?
        groups += 1
        yield groups.to_s, track
        track.tracks.each_with_index { |member, index| yield "#{groups}.#{index + 1}", member }
      else
        others += 1
        yield others.to_s, track
      end
    end
  end

  # The audio tracks of the set.
  #
  # The verdict for a transfer to Push 3 Standalone is about the audio of the set: a MIDI
  # clip has no file, and nothing of it is transferred.
  #
  # @return [Array<LiveTrack>] the audio tracks
  def audio_tracks
    @instances.select { |track| track.kind == 'Audio' }
  end

  # The groups of the set.
  #
  # @return [Array<LiveGroup>] the groups
  def groups
    @instances.select(&:group?)
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

  # The errors caused by one track.
  #
  # @param track [LiveTrack] the track
  # @return [Array<String>] the errors
  def track_errors(track)
    track.blocking_devices.map do |device|
      " - Track '#{track.name}' is unfrozen and uses #{device.label}, " \
        'which Push 3 Standalone cannot run. Freeze or render this track.'
    end
  end

  # This method is not used at present, but it should be because it is a neat test that is easier to write unit tests
  # for than the verdict above.
  # The only requirement for transfer to a P3S is that all audio files are collected and no missing raw devices are referenced.
  # Freezing is recommended for tracks with 3rd party plugins, but are not required for native devices.
  def ready_for_p3s?
    audio_tracks.all?(&:clips_collected?) &&
      audio_tracks.none? { |track| track.blocking_devices.any? } &&
      groups.none? { |group| group.blocking_devices.any? }
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
