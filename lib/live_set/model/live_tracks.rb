require_relative 'live_group'
require_relative 'live_track'

class LiveTracks
  def initialize(set_directory, tracks, groups = [])
    @tracks = tracks
    @track_instances = tracks.map { |track| LiveTrack.new set_directory, track }
    @group_instances = groups.map { |group| LiveGroup.new group, tracks }
  end

  # The verdict for a transfer to Push 3 Standalone, in markdown.
  #
  # Two kinds of message are reported. An error stops a set from being transferred: a clip that
  # is not collected, and a third-party device on an unfrozen track or in a group's chain. Advice
  # is not an error and does not change the verdict: an unfrozen track that uses only native
  # devices.
  #
  # The clips that are not collected are counted and not named: a demo set holds dozens of them,
  # and the list of them says nothing that the count does not.
  #
  # @return [String] the report
  def verdict_markdown
    errors = p3s_errors
    uncollected, others = errors.partition { |error| error.include? 'has not been collected' }

    lines = ['## Push 3 Standalone', '']
    lines << if errors.empty?
               '✅ Ready for transfer to Push 3 Standalone'
             else
               '❌ Warning: This set should not be transferred to Push 3 Standalone.'
             end
    unless uncollected.empty?
      lines << "- [#{uncollected.length} #{uncollected.length == 1 ? 'clip has' : 'clips have'} " \
               'not been collected.](#missing-samples)'
    end
    others.each { |error| lines << "- #{error.sub(/\A\s*-\s*/, '')}" }
    p3s_advice.each { |advice| lines << "- #{advice.sub(/\A\s*-\s*/, '')}" }
    lines.join("\n")
  end

  private

  # The errors that stop a set from being transferred.
  #
  # @return [Array<String>] the errors
  def p3s_errors
    errors = []
    @track_instances.each { |track| errors += track_errors(track) }
    errors + group_errors
  end

  # The advice about a set that can be transferred.
  #
  # @return [Array<String>] the advice
  def p3s_advice
    advice = []
    @track_instances.each do |track|
      next if track.frozen? || track.distinct_clips.empty? || track.device_summary.empty?

      advice << "Track '#{track.name}' is unfrozen; devices: #{track.device_summary}"
    end
    advice
  end

  # The errors caused by one track.
  #
  # @param track [LiveTrack] the track
  # @return [Array<String>] the errors
  def track_errors(track)
    errors = []

    # Name each uncollected file once, however many clips refer to it.
    uncollected = track.distinct_clips.reject(&:collected?).filter_map(&:absolute_path).uniq
    errors += uncollected.map { |path| " - Clip '#{path}' has not been collected." }

    track.blocking_devices.each do |device|
      errors << " - Track '#{track.name}' is unfrozen and uses #{device.label}, " \
                'which Push 3 Standalone cannot run. Freeze or render this track.'
    end

    errors
  end

  # This method is not used at present, but it should be because it is a neat test that is easier to write unit tests
  # for than the verdict above.
  # The only requirement for transfer to a P3S is that all audio files are collected and no missing raw devices are referenced.
  # Freezing is recommended for tracks with 3rd party plugins, but are not required for native devices.
  def ready_for_p3s?
    @track_instances.all?(&:clips_collected?) &&
      @track_instances.none? { |track| track.blocking_devices.any? } &&
      @group_instances.none? { |group| group.blocking_devices.any? }
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
    @group_instances.flat_map do |group|
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
