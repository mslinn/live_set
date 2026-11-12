require 'spec_helper'
require 'live_set/model/hierarchical_number'
require 'live_set/model/live_outline_item'
require 'live_set/serializer/live_outline_item_html_serializer'

# A thing of the outline, written as HTML.
RSpec.describe LiveOutlineItemHtmlSerializer do
  # The number of a thing at the top of the set.
  #
  # @return [HierarchicalNumber] the number
  def number
    @number ||= HierarchicalNumber.new 'G'
  end

  describe '#to_html' do
    it 'writes an item that has nothing under it as a plain item' do
      item = LiveOutlineItem.new number, 'Group track 1'

      expect(described_class.new(item).to_html).to eq "<li>Group track 1</li>\n"
    end

    it 'writes an item that has things under it as a disclosure widget' do
      device = LiveOutlineItem.new number, 'Group Track Device 1'
      group = LiveOutlineItem.new number, 'Group track 1', [device]

      html = described_class.new(group).to_html

      expect(html).to include '<li style="list-style: none;">'
      expect(html).to include '<details open>'
      expect(html).to include '<summary>Group track 1</summary>'
      expect(html).to include '<li>Group Track Device 1</li>'
    end

    it 'indents the item by two spaces for each level' do
      number.indent
      item = LiveOutlineItem.new number, 'a device'

      expect(described_class.new(item).to_html).to start_with "  <li>a device</li>\n"
    end

    it 'writes the things under the item below it' do
      device = LiveOutlineItem.new number, 'a device'
      group = LiveOutlineItem.new number, 'a group', [device]

      html = described_class.new(group).to_html

      expect(html).to include "    <li>a device</li>\n"
    end
  end
end
