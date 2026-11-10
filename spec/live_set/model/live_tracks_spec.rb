require 'spec_helper'
require 'live_set/model/live_tracks'
require 'support/live_sets'

# The tracks of a set, and the facts about them that the verdict for a transfer to P3S
# Standalone is made of.
RSpec.describe LiveTracks do
  # The tracks of a set.
  #
  # @param path [String] the path of the set
  # @return [LiveTracks] the tracks
  def tracks_of(path)
    document = LiveSets.document path
    LiveTracks.new LiveSets.directory(path),
                   document.xpath('//MidiTrack | //AudioTrack | //GroupTrack | //Tracks/ReturnTrack')
  end

  describe 'the tracks that cannot be transferred' do
    it 'names the MIDI track that uses a third-party device' do
      # A MIDI track has the same devices as an audio track, and the same problems.
      tracks = tracks_of LiveSets.fascination

      expect(tracks.blocking_tracks.map { |track, _| track.name }).to include('3-Kontakt 7')
    end

    it 'names the devices of the track' do
      tracks = tracks_of LiveSets.fascination

      expect(tracks.blocking_tracks.first.last.map(&:label)).to eq(['Kontakt 7'])
    end
  end

  describe 'the clips of the session view' do
    it 'has the clips of the session view of the set' do
      tracks = tracks_of LiveSets.fascination

      expect(tracks.session_view_clips).not_to be_empty
    end

    it 'has none when the set has no clip at all' do
      tracks = tracks_of LiveSets.factory_default11

      expect(tracks.session_view_clips).to be_empty
    end
  end
end
