require 'spec_helper'
require 'live_set/model/live_track'
require 'support/live_sets'

# A track of a set.
#
# The tracks are the ones of the Live 11 reference set, which is checked in.
RSpec.describe LiveTrack do
  # The track with the given name.
  #
  # Live numbers the names of the tracks that share a name, and the number is not part of the
  # name.
  #
  # @param name [String] the name of the track
  # @return [LiveTrack] the track
  def track_named(name)
    element = LiveSets.nodes(LiveSets.fascination, '//MidiTrack | //AudioTrack | //GroupTrack').find do |candidate|
      candidate.at('Name/EffectiveName')&.[]('Value')&.sub(/\A\d+[- ]/, '') == name
    end
    described_class.new LiveSets.directory(LiveSets.fascination), element
  end

  describe 'a MIDI track' do
    subject(:track) { track_named('Kontakt 7') }

    it 'is a MIDI track' do
      expect(track.kind).to eq 'MIDI'
      expect(track).not_to be_group
    end

    it 'holds the color Live wrote for it' do
      expect(track.color).to eq 21
    end

    it 'holds the clips of the track, and the place each of them is in' do
      expect(track.clips.map(&:name)).to include 'Kontakt 7 1'
      expect(track.clips.map(&:place).uniq).to include 'session view', 'arrangement'
    end

    it 'holds the take lanes of the track' do
      expect(track.take_lanes.size).to eq 1
      expect(track.take_lanes.map(&:name)).to eq ['3-Kontakt 7 1']
    end

    it 'is not frozen, and is a problem, because it has a device Push 3 cannot run' do
      expect(track).not_to be_frozen
      expect(track).to be_problem
    end
  end

  describe 'a group track' do
    subject(:track) { track_named('Drums') }

    it 'is a group track' do
      expect(track.kind).to eq 'Group'
      expect(track).to be_group
    end

    it 'holds no clips of its own' do
      expect(track.clips).to be_empty
    end

    it 'is never frozen' do
      expect(track).not_to be_frozen
    end
  end

  describe 'the master track of the set' do
    subject(:track) { track_named('Out') }

    it 'is an audio track' do
      expect(track.kind).to eq 'Audio'
    end
  end
end
