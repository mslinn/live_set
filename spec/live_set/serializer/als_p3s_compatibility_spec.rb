require 'spec_helper'
require 'live_set/serializer/p3s_compatibility'
require 'support/live_sets'

# The verdict for a transfer of a set to Push 3 Standalone.
#
# The expected value is the section of the report of the set as it is written now:
#
#   sets/live_11/reports/Fascination.md
#
# The section is a document, so the whole of it is expected, in a heredoc, and it can be
# read.
RSpec.describe P3SCompatibility, '#to_markdown' do
  # The set, as the model of it.
  #
  # @param path [String] the path of the set
  # @return [LiveTracks] the set
  def set(path)
    document = LiveSets.document path
    LiveTracks.new LiveSets.directory(path), document.xpath('//MidiTrack | //AudioTrack | //GroupTrack')
  end

  it 'says that a set that cannot be transferred is not ready, and what stops it' do
    expect(described_class.new(set(LiveSets.fascination)).to_markdown).to eq(<<~END_MARKDOWN.chomp)
      ## Push 3 Standalone

      ❌ Warning: This set should not be transferred to Push 3 Standalone.
      - [2 clips have not been collected.](#missing-samples)
      - Group '2 Drums' uses Filter, which Push 3 Standalone cannot run. Remove it from the group's device chain, or bounce the group. It affects 3-Kontakt 7, 4-Tambo and Timbales Loop 90bpm.
      - Group '5 Main' uses Filter, which Push 3 Standalone cannot run. Remove it from the group's device chain, or bounce the group. It affects 6-DBM_TC2_124_Erhu_Loop_A_Heroes_Tale_C#min, 7-Beat That Bass, 8-Clav Mellow, 9-Reggae Chords Guitar, 10-Intrepid Roads.
    END_MARKDOWN
  end
end
