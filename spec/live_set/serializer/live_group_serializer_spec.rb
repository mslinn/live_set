require 'spec_helper'
require 'live_set/serializer/live_group_serializer'
require 'support/live_sets'

# A group of a set.
#
# The expected values are the lines of the report of the desired Live reference set, which is
# checked in to [Live Reference Sets](https://github.com/mslinn/live_reference_sets).
RSpec.describe LiveGroupSerializer, '#to_markdown' do
  # The group with the given name.
  #
  # @param name [String] the name of the group
  # @return [LiveGroup] the group
  def group(name)
    elements = LiveSets.nodes(LiveSets.fascination, '//MidiTrack | //AudioTrack | //GroupTrack')
    element = elements.find do |candidate|
      candidate.name == 'GroupTrack' &&
        candidate.at('Name/EffectiveName')&.[]('Value')&.sub(/\A\d+[- ]/, '') == name
    end
    LiveGroup.new element, elements, LiveSets.directory(LiveSets.fascination)
  end

  it 'writes the line of the group: its number, its icon, its kind and its name' do
    markdown = described_class.new(group('Drums'), '1').to_markdown

    expect(markdown.lines.first.chomp).to eq(
      '- Group track 1  👥 Group  <code style="color: #FFFFFF; background-color: #212121; ' \
      'vertical-align: middle;"># Drums</code>'
    )
  end

  it 'writes the devices of the group under it' do
    markdown = described_class.new(group('Drums'), '1').to_markdown

    expect(markdown).to include(
      '    - Group Track Device 1a  <code style="color: #FFFFFF; background-color: #212121; ' \
      'vertical-align: middle;">Filter</code>  Max for Live  ⚠ not usable on Push 3'
    )
  end

  it 'writes the tracks in the group under it, numbered after the group' do
    markdown = described_class.new(group('Drums'), '1').to_markdown

    expect(markdown).to include('- Track 1.1  🎹 MIDI  ')
    expect(markdown).to include('- Track 1.2  🎵 Audio  ')
  end
end
