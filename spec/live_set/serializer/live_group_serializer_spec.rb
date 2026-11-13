require 'spec_helper'
require 'live_set/serializer/live_group_serializer'
require 'support/live_sets'
require 'support/numbers'

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
    markdown = described_class.new(group('Drums'), ReportNumbers.number('G', 1)).to_markdown

    # The group is not a problem: its only device is a Max for Live device, which the P3S
    # Standalone runs. It keeps the colour Live gave it.
    expect(markdown.lines.first.chomp).to eq(
      '- Group track G1  👥 Group  <code style="color: #000000; background-color: #18E9FE; ' \
      'vertical-align: middle;" title="Live color #21"># Drums</code>'
    )
  end

  it 'writes the devices of the group under it' do
    markdown = described_class.new(group('Drums'), ReportNumbers.number('G', 1)).to_markdown

    # A Max for Live device is supported by the P3S Standalone, so it carries no warning.

    expect(markdown).to include('  - Group Track Device G1.1  <code>Filter</code>  M4L')
  end

  it 'writes the tracks in the group under it, numbered after the group' do
    markdown = described_class.new(group('Drums'), ReportNumbers.number('G', 1)).to_markdown

    expect(markdown).to include('  - Track G1.3  🎹 MIDI  ')
    expect(markdown).to include('  - Track G1.4  🎵 Audio  ')
  end

  describe '#to_html' do
    it 'writes the group as a thing that can be folded' do
      html = described_class.new(group('Drums'), ReportNumbers.number('G', 1)).to_html

      expect(html).to include '<li style="list-style: none;">'
      expect(html).to include '<details open>'
      expect(html).to include '<summary>Group track G1  👥 Group  '
    end

    it 'writes the devices and the members of the group in one list' do
      html = described_class.new(group('Drums'), ReportNumbers.number('G', 1)).to_html
      devices_and_members = html[/<li>Group Track Device G1\.1.*?<summary>Track G1\.3/m]

      expect(devices_and_members).not_to include '</ul>'
    end
  end
end
