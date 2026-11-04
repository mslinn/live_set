require 'spec_helper'
require 'live_set/serializer/live_take_lanes_serializer'
require 'support/live_sets'

# The take lanes of a track.
#
# The expected values are the lines of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe LiveTakeLanesSerializer, '#to_markdown' do
  # The take lanes of the track with the given name.
  #
  # @param name [String] the name of the track
  # @return [LiveTakeLanes] the lanes
  def take_lanes(name)
    element = LiveSets.nodes(LiveSets.fascination, '//MidiTrack | //AudioTrack | //GroupTrack').find do |candidate|
      candidate.at('Name/EffectiveName')&.[]('Value')&.sub(/\A\d+[- ]/, '') == name
    end
    LiveTakeLanes.new element
  end

  it 'writes the lanes of the track, numbered after the track' do
    markdown = described_class.new(take_lanes('Pink Noise - EDMtips.com'), '1').to_markdown

    expect(markdown.lines.first.chomp).to eq '- Take lane 1.1  Pink Noise - EDMtips.com'
  end

  it 'writes the clips of the lane under it' do
    markdown = described_class.new(take_lanes('Pink Noise - EDMtips.com'), '1').to_markdown

    expect(markdown).to include('* Clip 1.1.1 (×4) ')
  end

  it 'writes nothing for a track without lanes' do
    markdown = described_class.new(take_lanes('Drums'), '1').to_markdown

    expect(markdown).to be_empty
  end
end
