require 'spec_helper'
require 'live_set/serializer/report_header_serializer'
require 'support/live_sets'

# The facts about a set, at the top of the report.
#
# The expected values are the table of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe LiveHeaderSerializer, '#to_markdown' do
  # The facts about the Live 11 reference set.
  #
  # @return [HeaderBlock] the facts
  def header
    HeaderBlock.new LiveSets.fascination, LiveSets.document(LiveSets.fascination)
  end

  it 'writes the version of Live that wrote the set' do
    expect(described_class.new(header).to_markdown).to include('|Written by|Ableton Live 11.3.13|')
  end

  it 'writes the format of the set' do
    expect(described_class.new(header).to_markdown).to include('|Format|11.0_11300|')
  end

  it 'writes the revision of the set' do
    expect(described_class.new(header).to_markdown).to include('|Revision|b376a4ffe2734bb43bb06f3a36871bb868ae2231|')
  end

  it 'writes the computer the set is on' do
    expect(described_class.new(header).to_markdown).to include('|On computer|')
  end

  it 'writes the directory the set is in, with breaks where it has to be' do
    expect(described_class.new(header).to_markdown).to include('<wbr/>ableton/<wbr/>live_reference_sets/<wbr/>')
  end

  it 'writes the rows in alphabetical order' do
    labels = described_class.new(header).to_markdown.lines.filter_map { |line| line.split('|')[1] }

    expect(labels).to eq labels.sort_by(&:downcase)
  end
end
