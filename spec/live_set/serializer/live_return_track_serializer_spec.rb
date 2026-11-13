require 'spec_helper'
require 'live_set/model/live_return_track'
require 'live_set/serializer/live_return_track_serializer'
require 'support/live_sets'
require 'support/numbers'

# A return track of a set.
#
# The expected values are the lines of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe LiveReturnTrackSerializer, '#to_markdown' do
  # The return track with the given name.
  #
  # @param name [String] the name of the track
  # @return [LiveReturnTrack] the track
  def track(name)
    element = LiveSets.nodes(LiveSets.fascination, '//Tracks/ReturnTrack').find do |candidate|
      candidate.at('Name/EffectiveName')&.[]('Value')&.sub(/\A\d+[- ]/, '') == name
    end
    LiveReturnTrack.new LiveSets.directory(LiveSets.fascination), element
  end

  it 'writes the line of the track: its number, its icon, its kind and its name' do
    markdown = described_class.new(track('B-Echo | EQ Eight'), ReportNumbers.number('T', 2)).to_markdown

    expect(markdown.lines.first.chomp).to eq(
      '- Track T2  ↩️ Return  <code style="color: #000000; background-color: #FF94A6; ' \
      'vertical-align: middle;" title="Live color #0">B-Echo &#124; EQ Eight</code>'
    )
  end

  it 'writes the name of a track with a character that would break a table, escaped' do
    markdown = described_class.new(track('A-Fresh Room | EQ Eight'), ReportNumbers.number('T', 1)).to_markdown

    expect(markdown.lines.first.chomp).to include('A-Fresh Room &#124; EQ Eight</code>')
  end
end
