require 'spec_helper'
require 'live_set/model/hierarchical_number'
require 'live_set/serializer/hierarchical_number_serializer'

# A thing of the outline, and the things under it.
RSpec.describe HierarchicalNumberSerializer do
  subject(:serializer) { described_class.new number, 'Group track 1' }

  # The number of a thing at the top of the set.
  #
  # @return [HierarchicalNumber] the number
  def number
    @number ||= HierarchicalNumber.new 'G'
  end

  describe '#to_markdown' do
    it 'writes the text of the thing as a list item' do
      expect(serializer.to_markdown).to eq '- Group track 1'
    end

    it 'writes the number of the thing when it has no text of its own' do
      expect(described_class.new(number).to_markdown).to eq '- G1'
    end

    it 'indents the thing by two spaces for a level below the top' do
      number.indent

      expect(serializer.to_markdown).to eq '  - Group track 1'
    end

    it 'writes the things under it after it' do
      expect(serializer.to_markdown(['  - a member'])).to eq "- Group track 1\n  - a member"
    end
  end

  describe '#to_html' do
    it 'writes a thing that has nothing under it as a plain item' do
      expect(serializer.to_html).to eq "  <li>Group track 1</li>\n"
    end

    it 'writes a thing that has things under it as a disclosure widget' do
      html = serializer.to_html(['      <li>a member</li>'])

      expect(html).to include '<li style="list-style: none;">'
      expect(html).to include '<details open>'
      expect(html).to include '<summary>Group track 1</summary>'
      expect(html).to include '<ul style="list-style: none;">'
    end

    it 'writes the things under it in the list that holds them' do
      expect(serializer.to_html(['      <li>a member</li>'])).to include "      <li>a member</li>\n"
    end

    it 'closes the disclosure widget before it closes the item' do
      expect(serializer.to_html(['      <li>a member</li>'])).to include "    </details>\n  </li>\n"
    end

    it 'indents the thing by six columns for a level below the top' do
      number.indent

      expect(serializer.to_html).to start_with "        <li>Group track 1</li>\n"
    end
  end
end
