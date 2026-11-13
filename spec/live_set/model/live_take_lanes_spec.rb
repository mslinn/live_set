require 'spec_helper'
require 'live_set/model/live_take_lanes'
require 'support/live_sets'

# The take lanes of a track.
#
# The lanes are the ones of the Live 11 reference set, which is checked in.
RSpec.describe LiveTakeLanes do
  # The track with the given name.
  #
  # Live numbers the names of the tracks that share a name, and the number is not part of the
  # name.
  #
  # @param name [String] the name of the track
  # @return [Nokogiri::XML::Element] the track
  def track(name)
    LiveSets.nodes(LiveSets.fascination, '//MidiTrack | //AudioTrack | //GroupTrack').find do |element|
      element.at('Name/EffectiveName')&.[]('Value')&.sub(/\A\d+[- ]/, '') == name
    end
  end

  subject(:lanes) { described_class.new track('Kontakt 7') }

  it 'holds the lanes of the track, in the order they appear in the file' do
    expect(lanes.size).to eq 1
    expect(lanes.map(&:name)).to eq ['3-Kontakt 7 1']
  end

  it 'numbers the lanes from one' do
    expect(lanes[1].index).to eq 1
  end

  it 'holds the clips of each lane, one for each place the clip is in the lane' do
    expect(lanes[1].clips.map(&:name)).to eq ['Kontakt 7 1', 'Kontakt 7 1', 'Kontakt 7 1']
    expect(lanes[1].clips.map(&:place)).to eq ['take lane', 'take lane', 'take lane']
  end

  it 'is empty for a track without lanes' do
    expect(described_class.new(track('All')).size).to eq 0
  end
end
