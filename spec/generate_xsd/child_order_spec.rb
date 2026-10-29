require 'spec_helper'
require 'generate_xsd/child_order'

RSpec.describe ChildOrder do
  # The child names of the instances of an element.
  #
  # @param sequences [Array<Array<String>>] the child names of each instance
  # @return [ChildOrder] the order of the children
  def order_for(sequences)
    described_class.new(sequences)
  end

  describe '#conflict?' do
    context 'when every instance has the same children in the same order' do
      it 'is false' do
        order = order_for([%w[A B], %w[A B]])

        expect(order.conflict?).to be false
      end
    end

    context 'when an instance has a child element the others lack' do
      it 'is false' do
        order = order_for([%w[A B], %w[A]])

        expect(order.conflict?).to be false
      end
    end

    context 'when the instances order the children differently' do
      it 'is true' do
        order = order_for([%w[A B], %w[B A]])

        expect(order.conflict?).to be true
      end
    end

    context 'when a child element comes back after a different child element' do
      it 'is true' do
        order = order_for([%w[A B A]])

        expect(order.conflict?).to be true
      end
    end

    context 'when a child element repeats without interruption' do
      it 'is false' do
        order = order_for([%w[A A B B]])

        expect(order.conflict?).to be false
      end
    end
  end
end
