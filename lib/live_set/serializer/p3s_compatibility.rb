require_relative 'live_markup'

# Writes the "P3S Standalone" section of the markdown report for a `LiveSet` model.
#
# A Live Set may fail to open, open with missing content, or open but behave differently on
# Push 3 Standalone for several reasons:
#
# - **Plug-ins.** Push Standalone does not support VST, VST3, or AU plug-ins. A track that
#   uses one has to be frozen before the set is transferred.
# - **Missing samples or media.** Transferring just the .als leaves the files it refers to
#   behind. The whole project has to be transferred, or the set has to be saved with Collect
#   All and Save.
# - **Packs.** A set that plays a file of a pack refers to the pack, and the pack has to be
#   installed for the file to be found. Samples from packs require those packs to be
#   installed on the Push as well. A set whose pack is not installed loads and plays, but the
#   content of the pack does not play. The P3S Standalone cannot be asked what it has
#   installed, so a set that refers to a pack can only be classified as *probably* ready.
# - **Demanding Max for Live devices.** The Push Standalone supports Max for Live, but it has
#   less CPU headroom than a desktop computer, so a device that is demanding may overload it.
# - **Live version mismatch.** The oldest version of Live the Push Standalone can load a set
#   of is 11.3. The Push Standalone runs a version of Live of its own, and it loads a set only
#   when the set was made with that version of Live or with a later one: a Push Standalone
#   that has Live 12.3 in it cannot load a set that was made with Live 12.4. The version of
#   Live the Push Standalone has is not known here, so the oldest version it supports is the
#   one that is checked.
# - **The arrangement.** Sets can load and play, but Arrangement View editing is not
#   supported in Standalone Mode; the Push is optimized for the Session View. A set that has
#   no clip in the session view is an empty set as far as the Push Standalone is concerned.
# - **Capacity.** A set may exceed the available CPU, memory, or track capacity for the Live
#   edition running on the Push. A set of more than 2 GB is incompatible with the Push
#   Standalone.
# - **The licence.** Whether the sound or the device of a set is available under the Live
#   licence that the P3S Standalone is authorized with cannot be checked here, and it is not
#   reported. A set that uses content the licence does not cover loads and plays, but the
#   content does not play.
#
# Two kinds of message are reported. An error stops a set from being transferred: a clip that
# is not collected, a third-party device on an unfrozen track or in a group's chain, a set of
# an old version of Live, and a set that is too large. Advice is not an error and does not
# change the verdict: a Max for Live device, and a set that has no clip in the session view.
#
# What cannot be checked is reported as well: the packs the set refers to. The P3S Standalone
# cannot be probed, so what it has installed is not known here.
#
# The clips that are not collected are counted and not named: a demo set holds dozens of
# them, and the list of them says nothing that the count does not.
#
# Sample usage:
# markdown = P3SCompatibility.new(model).to_markdown
class P3SCompatibility
  # The oldest version of Live the P3S Standalone can load a set of.
  #
  # The version of Live the P3S Standalone has is not known here, so the oldest version it
  # supports is the one that is checked.
  MINIMUM_LIVE_VERSION = [11, 3].freeze

  # The largest set the P3S Standalone can load.
  #
  # A set that is larger than this exceeds the memory, the CPU, or the capacity of the Live
  # edition that runs on the P3S.
  MAXIMUM_SET_SIZE = 2 * 1024 * 1024 * 1024

  # Create a serializer for the "P3S Standalone" report section for the given set.
  #
  # @param model [AlsModel] the model of the set
  def initialize(model)
    @model = model
  end

  # Return the "P3S Standalone" report section as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = ['## P3S Standalone', '']
    lines.concat verdict_lines
    lines.concat unknown_lines
    lines.concat advice_lines
    lines.join("\n")
  end

  private

  # The verdict, and the reasons for it.
  #
  # A set that has no reason against it is ready for the transfer, unless something about it
  # cannot be checked: a set that refers to a pack is only probably ready, because the P3S
  # Standalone has to have the pack installed for the content of it to play.
  #
  # @return [Array<String>] the lines
  def verdict_lines
    reasons = reason_lines
    return ready_lines if reasons.empty?

    ['❌ Warning: This set should not be transferred to P3S Standalone.', '',
     '### Reasons Why', ''] + reasons
  end

  # The reasons the set cannot be transferred.
  #
  # @return [Array<String>] the lines
  def reason_lines
    uncollected = @model.live_set.uncollected_clips.length
    lines = []
    unless uncollected.zero?
      lines << "- [#{uncollected} #{uncollected == 1 ? 'clip has' : 'clips have'} " \
               'not been collected.](#missing-samples)'
    end
    errors.each { |error| lines << "- #{error}" }
    lines
  end

  # The verdict of a set that has no reason against it.
  #
  # @return [Array<String>] the lines
  def ready_lines
    return ['✅ Ready for transfer to P3S Standalone'] if unknown_facts.empty?

    ['⚠️ This set is probably ready for transfer to P3S Standalone.']
  end

  # The facts that could not be checked.
  #
  # The P3S Standalone cannot be probed, so what it has installed is not known here. A set
  # that refers to a pack needs the pack installed on the P3S Standalone for the content of
  # it to play, and the set loads and plays without it.
  #
  # @return [Array<String>] the lines
  def unknown_lines
    facts = unknown_facts
    return [] if facts.empty?

    lines = ['', '### What Could Not Be Checked', '']
    facts.each { |fact| lines << "- #{fact}" }
    lines
  end

  # The facts that could not be checked.
  #
  # @return [Array<String>] the facts
  def unknown_facts
    @unknown_facts ||= @model.packs.map do |pack|
      "The set refers to the pack '#{pack.name}'. The pack has to be installed on the P3S " \
        'Standalone for the content of it to play, and there is no way to check what is ' \
        'installed on it.'
    end
  end

  # The advice: the set can be transferred, but a device of it may overload the P3S, or the
  # set may have nothing for the P3S to play.
  #
  # @return [Array<String>] the lines
  def advice_lines
    return [] if advice.empty?

    lines = ['', '### Advice', '']
    advice.each { |item| lines << "- #{item}" }
    lines
  end

  # The errors that stop a set from being transferred.
  #
  # @return [Array<String>] the errors
  def errors
    @errors ||= track_errors + group_errors + version_errors + size_errors
  end

  # The errors of the tracks that are not frozen.
  #
  # @return [Array<String>] the errors
  def track_errors
    @model.live_set.blocking_tracks.flat_map do |track, devices|
      devices.map { |device| track_error track, device }
    end
  end

  # The error of a device on a track.
  #
  # @param track [LiveTrack] the track
  # @param device [LiveDevice] the device
  # @return [String] the error
  def track_error(track, device)
    if track.kind == 'Return'
      return "Track #{track_name track} uses device #{device.label}, which P3S Standalone cannot run. " \
             'A return track cannot be frozen, so remove the device from its chain, or bounce it.'
    end

    "Track #{track_name track} is not frozen and uses device #{device.label}, " \
      'which P3S Standalone cannot run. Freeze or render this track.'
  end

  # The errors of the devices in the chains of the groups.
  #
  # @return [Array<String>] the errors
  def group_errors
    @model.live_set.blocking_groups.flat_map do |group, devices, affected|
      devices.map do |device|
        message = "Group '#{group.name}' uses #{device.label}, which P3S Standalone cannot run. " \
                  "Remove it from the group's device chain, or bounce the group."
        message += " It affects #{affected.join ', '}." unless affected.empty?
        message
      end
    end
  end

  # The error of a set that an old version of Live wrote.
  #
  # @return [Array<String>] the errors
  def version_errors
    version = @model.header_block.live_version
    return [] if version.nil?
    return [] if (version <=> MINIMUM_LIVE_VERSION) >= 0

    ["This set was written by Live #{version.join '.'}, and the oldest version of Live the " \
     'P3S Standalone can load a set of is Live ' \
     "#{MINIMUM_LIVE_VERSION.join '.'}."]
  end

  # The error of a set that is too large for the P3S Standalone.
  #
  # The size that is compared is the size of the project: the set file, and every sample the
  # set refers to that is in the project. The samples that come from a pack are not counted:
  # they travel with the pack.
  #
  # @return [Array<String>] the errors
  def size_errors
    size = @model.sizes.expected_project_size
    return [] if size.nil? || size <= MAXIMUM_SET_SIZE

    ["The project of this set is #{gigabytes size}, and the P3S Standalone cannot load a set " \
     'of more than 2 GB.']
  end

  # The advice: the set can be transferred, but a device of it may overload the P3S, or the
  # set may have nothing for the P3S to play.
  #
  # @return [Array<String>] the advice
  def advice
    max_for_live_advice + session_view_advice
  end

  # The advice of the tracks and the groups that use a Max for Live device.
  #
  # @return [Array<String>] the advice
  def max_for_live_advice
    track_advice + group_advice
  end

  # The advice of the tracks that use a Max for Live device.
  #
  # @return [Array<String>] the advice
  def track_advice
    @model.live_set.max_for_live_tracks.flat_map do |track, devices|
      devices.map do |device|
        "Track #{track_name track} uses Max for Live device #{device.label}, which the P3S Standalone " \
          "runs with less headroom. #{remedy_for track}"
      end
    end
  end

  # The advice of the groups that use a Max for Live device.
  #
  # @return [Array<String>] the advice
  def group_advice
    @model.live_set.max_for_live_groups.flat_map do |group, devices|
      devices.map do |device|
        "Group '#{group.name}' uses Max for Live device #{device.label}, which the P3S Standalone " \
          'runs with less headroom. A group cannot be frozen, so bounce the group if it overloads.'
      end
    end
  end

  # The advice of a set that has no clip in the session view.
  #
  # A set loads and plays in Standalone Mode, but the Arrangement View cannot be edited
  # there, and the Push is optimized for the Session View. A set that has no clip in the
  # session view is an empty set as far as the P3S Standalone is concerned.
  #
  # @return [Array<String>] the advice
  def session_view_advice
    return [] unless @model.live_set.session_view_clips.empty?

    ['This set has no clip in the session view, so the P3S Standalone has nothing to play. ' \
     'A set loads and plays in Standalone Mode, but the Arrangement View cannot be edited there.']
  end

  # What to do about a device the P3S Standalone cannot run.
  #
  # A track that holds clips can be frozen, and freezing renders its devices away. A return
  # track holds no clips, and a return track cannot be frozen.
  #
  # @param track [LiveTrack] the track
  # @return [String] the remedy
  def remedy_for(track)
    return 'A return track cannot be frozen, so remove the device from its chain, or bounce it.' if
      track.kind == 'Return'

    'Freeze or render this track.'
  end

  # The size, in gigabytes.
  #
  # @param size [Integer] the size in bytes
  # @return [String] the size
  def gigabytes(size)
    format '%.2f GB', size / (1024.0**3)
  end

  # The name of a track, on the colour Live gave it.
  #
  # @param track [LiveTrack] the track
  # @return [String] the name of the track
  def track_name(track)
    LiveMarkup.track_name_markdown track, track.display_name, in_a_cell: true
  end
end
