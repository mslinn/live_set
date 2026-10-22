class LiveTracks
  def initialize(set_directory, tracks)
    @tracks = tracks
    @track_instances = tracks.map { |track| LiveTrack.new set_directory, track }
  end

  # @return true if all tracks are frozen
  def all_frozen?
    @track_instances.all?(&:frozen?)
  end

  # @return message summarizing the state of all tracks
  def message
    if @tracks.empty?
      'No tracks'
    else
      all_frozen = all_frozen?
      msg = @track_instances.map { |x| x.show_track(all_frozen) }.join("\n  ")
      "#{summary}  #{msg}"
    end
  end

  private

  # @return message regarding the Live session compatibility with Push 3 Standalone
  def p3s_tx_msg
    lines = []
    has_errors = false

    @track_instances.each do |track|
      # Name each uncollected file once, however many clips refer to it.
      uncollected = track.distinct_clips.reject(&:collected?).filter_map(&:absolute_path).uniq
      uncollected.each do |path|
        lines << " - Clip '#{path}' has not been collected.".red
        has_errors = true
      end

      track.blocking_devices.each do |device|
        lines << " - Track '#{track.name}' is unfrozen and uses #{device.label}, " \
                 'which Push 3 Standalone cannot run. Freeze or render this track.'.red
        has_errors = true
      end

      next if track.frozen? || track.distinct_clips.empty? || track.device_summary.empty?

      lines << " - Track '#{track.name}' is unfrozen; devices: #{track.device_summary}".yellow
    end

    verdict = if has_errors
                'Warning: This set should not be transferred to Push 3 Standalone.'.red
              else
                'Ready for transfer to Push 3 Standalone'.green
              end

    ([verdict] + lines).join("\n")
  end

  # This method is not used at present, but it should be because it is a neat test that is easier to write unit tests
  # for than p3s_tx_msg.
  # The only requirement for transfer to a P3S is that all audio files are collected and no missing raw devices are referenced.
  # Freezing is recommended for tracks with 3rd party plugins, but are not required for native devices.
  def ready_for_p3s?
    @track_instances.all?(&:clips_collected?) &&
      @track_instances.none? { |track| track.blocking_devices.any? }
  end

  # @return multiline message showing the status of all tracks in the Live session
  def summary
    all_frozen_msg = all_frozen? ? ' (All are frozen)'.yellow : ''
    total_size = @track_instances.sum(&:track_size)
    size_warning = if total_size >= 2_000_000_000
                     "\nWarning: This set is too large to be frozen and too large to transfer to Push 3 Standalone.".red
                   else
                     ''
                   end
    total_set_size = "Total set size: #{human_file_size total_size}".yellow
    <<~END_MSG
      #{p3s_tx_msg}
      #{total_set_size}#{size_warning}
      #{@track_instances.count} tracks#{all_frozen_msg}:
    END_MSG
  end
end
