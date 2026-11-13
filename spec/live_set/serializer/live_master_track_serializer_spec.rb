require 'spec_helper'
require 'live_set/model/live_master_track'
require 'live_set/serializer/live_master_track_serializer'
require 'support/live_sets'
require 'support/numbers'

# The master track of a set.
#
# The expected values are the lines of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe LiveMasterTrackSerializer, '#to_markdown' do
  # The master track of the set.
  #
  # @return [LiveMasterTrack] the track
  def track
    @track ||= begin
      element = LiveSets.node(LiveSets.fascination, '//MasterTrack | //MainTrack')
      LiveMasterTrack.new LiveSets.directory(LiveSets.fascination), element
    end
  end

  it 'writes the line of the track: its number' do
    markdown = described_class.new(track, ReportNumbers.number('T', 7)).to_markdown

    # The word "Master" is in the heading of the section, and it is not repeated here.
    expect(markdown.lines.first.chomp).to eq('- Track T7')
  end
end
