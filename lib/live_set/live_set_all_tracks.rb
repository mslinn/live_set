class AllTracks
  def initialize(tracks)
    @tracks = tracks
    @track_instances = tracks.map { |track| LiveAudioTrack.new track }
  end

  def all_frozen
    @track_instances.all?(&:frozen?)
  end

  def message
    if @tracks.empty?
      'No tracks'
    else
      summary + @track_instances.map { |x| x.show_track(all_frozen) }.join("\n  ")
    end
  end

  def summary
    all_frozen_msg = all_frozen ? ' (All are frozen)' : ''
    "#{@tracks.count} tracks#{all_frozen_msg}:\n  "
  end
end
