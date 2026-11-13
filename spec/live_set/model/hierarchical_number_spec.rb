require 'spec_helper'
require 'live_set/model/hierarchical_number'

# The number a thing has in the report.
RSpec.describe HierarchicalNumber do
  subject(:number) { described_class.new 'G' }

  it 'starts at one' do
    expect(number.to_s).to eq 'G1'
  end

  it 'says what kind of thing it is' do
    expect(described_class.new('T').to_s).to eq 'T1'
  end

  describe '#indent' do
    it 'makes the number a level deeper' do
      number.indent

      expect(number.to_s).to eq 'G1.1'
    end

    it 'makes the number two levels deeper' do
      number.indent.indent

      expect(number.to_s).to eq 'G1.1.1'
    end
  end

  describe '#outdent' do
    it 'takes the number a level up' do
      number.indent.indent.outdent

      expect(number.to_s).to eq 'G1.1'
    end

    it 'leaves the number alone when it is at the top' do
      number.outdent

      expect(number.to_s).to eq 'G1'
    end
  end

  describe '#increment' do
    it 'counts on at this level' do
      number.increment

      expect(number.to_s).to eq 'G2'
    end

    it 'counts on at the level it is at' do
      number.indent.increment

      expect(number.to_s).to eq 'G1.2'
    end
  end

  describe '#reset' do
    it 'counts the first thing at the top again' do
      number.increment.increment.reset

      expect(number.to_s).to eq 'G1'
    end
  end

  describe '#level' do
    it 'is one at the top' do
      expect(number.level).to eq 1
    end

    it 'is the number of dots in the number, plus one' do
      number.indent.indent

      expect(number.level).to eq 3
    end
  end

  describe '#indent_for' do
    it 'is nothing at the top' do
      expect(number.indent_for('  ')).to eq ''
    end

    it 'is one level of indentation for a level below the top' do
      number.indent

      expect(number.indent_for('  ')).to eq '  '
    end

    it 'is two levels of indentation for two levels below the top' do
      number.indent.indent

      expect(number.indent_for('  ')).to eq '    '
    end

    it 'takes the indentation of a level' do
      number.indent

      expect(number.indent_for('.')).to eq '.'
    end
  end
end
