class AllTracks
  def initialize(tracks)
    @tracks = tracks
    @track_instances = tracks.map { |track| LiveAudioTrack.new track }
  end

  def all_frozen
    @track_instances.all?(&:frozen)
  end

  def message
    if @tracks.empty?
      'No tracks'
    else
      summary + '  ' + @track_instances.map { |x| x.show_track(all_frozen) }.join("\n  ") # rubocop:disable Style/StringConcatenation
    end
  end

  def summary
    all_frozen_msg = all_frozen ? ' (All are frozen)'.yellow : ''
    push_warning = all_frozen ? '' : "\nWarning: some tracks are not frozen, so this set should not be transferred to Push 3 Standalone.".red
    total_size = @track_instances.sum(&:track_size)
    size_warning = if total_size >= 2_000_000_000
                     "\nWarning: This set is too large to be frozen and too large too large to transfer to Push 3 Standalone.".red
                   else
                     ''
                   end
    total_set_size = "Total set size: #{human_file_size total_size}".yellow
    <<~END_MSG
      #{total_set_size}#{size_warning}#{push_warning}
      #{@track_instances.count} tracks#{all_frozen_msg}:
    END_MSG
  end
end
