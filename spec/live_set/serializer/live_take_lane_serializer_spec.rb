require 'spec_helper'
require 'live_set/model/live_take_lanes'
require 'live_set/serializer/live_take_lane_serializer'
require 'support/live_sets'

# A take lane of a track.
#
# The expected values are the lines of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe LiveTakeLaneSerializer, '#to_markdown' do
  # The take lane of the track with the given name.
  #
  # @param name [String] the name of the track
  # @return [LiveTakeLane] the lane
  def take_lane(name)
    element = LiveSets.nodes(LiveSets.fascination, '//MidiTrack | //AudioTrack').find do |candidate|
      candidate.at('Name/EffectiveName')&.[]('Value')&.sub(/\A\d+[- ]/, '') == name
    end
    LiveTakeLanes.new(element)[1]
  end

  it 'writes the line of the lane: its number and its name' do
    markdown = described_class.new(take_lane('Pink Noise - EDMtips.com'), '1.1').to_markdown

    expect(markdown.lines.first.chomp).to eq '- Take lane 1.1  Pink Noise - EDMtips.com'
  end

  it 'writes the MIDI clips of the lane under it' do
    markdown = described_class.new(take_lane('Kontakt 7'), '1.1').to_markdown

    expect(markdown).to include('* Clip 1.1.1 (×3) ')
  end
end
