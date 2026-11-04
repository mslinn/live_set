require 'spec_helper'
require 'live_set/serializer/live_clip_groups'
require 'support/live_sets'

# The copies of a clip that are alike, written as one line.
#
# The expected values are the lines of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe LiveClipGroups, '#to_markdown' do
  # The clips of the track with the given name.
  #
  # @param name [String] the name Live wrote
  # @return [Array<LiveClip>] the clips
  def clips(name)
    element = LiveSets.nodes(LiveSets.fascination, '//MidiTrack | //AudioTrack | //GroupTrack').find do |candidate|
      candidate.at('Name/EffectiveName')&.[]('Value')&.sub(/\A\d+[- ]/, '') == name
    end
    LiveTrack.new(LiveSets.directory(LiveSets.fascination), element).clips
  end

  it 'writes the copies of a clip that are alike as one line, with the number of them' do
    groups = described_class.new clips('Pink Noise - EDMtips.com')

    expect(groups.to_markdown('1')).to include(a_string_matching(/^\* Clip 1\.1 \(×7\) /))
  end

  it 'writes the settings the copies differ in, under the line' do
    groups = described_class.new clips('Pink Noise - EDMtips.com')

    expect(groups.to_markdown('1')).to include('  * References (×7): launch: trigger, warp: Beats')
  end

  it 'numbers the clips of the track they are on' do
    groups = described_class.new clips('Kontakt 7')

    expect(groups.to_markdown('1.1').first).to start_with '* Clip 1.1.1 (×5) '
  end
end
