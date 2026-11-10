require 'spec_helper'
require 'live_set/model/header_block'
require 'support/live_sets'

# The facts about the file of a set.
#
# The version of Live that wrote the set is in the creator of the file: `Ableton Live
# 11.3d1`.
RSpec.describe HeaderBlock do
  # The header block of a set.
  #
  # @param path [String] the path of the set
  # @return [HeaderBlock] the header block
  def header_of(path)
    described_class.new path, LiveSets.document(path)
  end

  it 'reads the version of Live that wrote the set' do
    expect(header_of(LiveSets.fascination).live_version).to eq([11, 3])
  end

  it 'reads the version of an old set' do
    expect(header_of(LiveSets.live_9_demo).live_version).to eq([9, 5])
  end

  it 'has no version when the creator names none' do
    header = header_of LiveSets.fascination
    allow(header).to receive(:creator).and_return('Ableton Live')

    expect(header.live_version).to be_nil
  end
end
