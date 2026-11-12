require 'spec_helper'
require 'live_set/model/hierarchical_number'
require 'live_set/serializer/hierarchical_number_serializer'

# The number a thing has in the report.
RSpec.describe HierarchicalNumberSerializer do
  subject(:serializer) { described_class.new number }

  # The number of a thing at the top of the set.
  #
  # @return [HierarchicalNumber] the number
  def number
    @number ||= HierarchicalNumber.new 'G'
  end

  describe '#to_markdown' do
    it 'writes the number with a list marker in front of it' do
      expect(serializer.to_markdown).to eq '- G1'
    end

    it 'indents the number by two spaces for each level' do
      number.indent

      expect(serializer.to_markdown).to eq '  - G1.1'
    end

    it 'indents the number by two spaces for each level of two levels' do
      number.indent.indent

      expect(serializer.to_markdown).to eq '    - G1.1.1'
    end
  end

  describe '#to_html' do
    it 'writes the number' do
      expect(serializer.to_html).to eq 'G1'
    end

    it 'indents the number by two spaces for each level' do
      number.indent

      expect(serializer.to_html).to eq '  G1.1'
    end
  end
end
