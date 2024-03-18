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
      total_size = @track_instances.sum(&:track_size)
      size_warning = total_size >= 2_000_000_000 ? "\nWarning: This set is too large to be frozen.".red : ''
      summary + @track_instances.map { |x| x.show_track(all_frozen) }.join("\n  ") +
        "\n\nTotal set size: #{human_file_size total_size}" + size_warning
    end
  end

  def summary
    all_frozen_msg = all_frozen ? ' (All are frozen)' : ''
    "#{@track_instances.count} tracks#{all_frozen_msg}:\n  "
  end
end
