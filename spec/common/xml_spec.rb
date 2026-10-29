require 'spec_helper'
require 'common/xml'

RSpec.describe Xml do
  subject(:reader) { Class.new { include Xml }.new }

  # Parses an XML fragment and returns its root element.
  def element(xml)
    Nokogiri::XML(xml).root
  end

  describe '#xml_value' do
    context 'when the element has a Value attribute' do
      it 'returns the attribute value' do
        el = element('<EffectiveName Value="My Track"/>')

        expect(reader.xml_value(el)).to eq('My Track')
      end

      it 'returns a value that looks like a number' do
        el = element('<OriginalFileSize Value="3626186"/>')

        expect(reader.xml_value(el)).to eq('3626186')
      end

      it 'ignores the element text' do
        el = element('<EffectiveName Value="My Track">ignored</EffectiveName>')

        expect(reader.xml_value(el)).to eq('My Track')
      end
    end

    context 'when the element has an empty Value attribute' do
      # <RelativePath Value="" /> means the sample is not in the project folder.
      it 'returns nil' do
        el = element('<RelativePath Value=""/>')

        expect(reader.xml_value(el)).to be_nil
      end

      it 'returns nil even when the element has text' do
        el = element('<RelativePath Value="">ignored</RelativePath>')

        expect(reader.xml_value(el)).to be_nil
      end
    end

    context 'when the element has no Value attribute' do
      it 'returns nil' do
        el = element('<EffectiveName/>')

        expect(reader.xml_value(el)).to be_nil
      end

      it 'returns nil even when the element has text' do
        el = element('<EffectiveName>My Track</EffectiveName>')

        expect(reader.xml_value(el)).to be_nil
      end
    end

    context 'when there is no element' do
      it 'returns nil' do
        expect(reader.xml_value(nil)).to be_nil
      end
    end
  end

  describe '#xml_first_value' do
    it 'returns the value of the first element that has one' do
      first = element('<EffectiveName/>')
      second = element('<UserName Value="My Track"/>')

      expect(reader.xml_first_value(first, second)).to eq('My Track')
    end

    it 'skips an element with an empty value' do
      first = element('<EffectiveName Value=""/>')
      second = element('<UserName Value="My Track"/>')

      expect(reader.xml_first_value(first, second)).to eq('My Track')
    end

    it 'returns nil when no element has a value' do
      first = element('<EffectiveName/>')
      second = element('<UserName/>')

      expect(reader.xml_first_value(first, second)).to be_nil
    end

    it 'returns nil when given no elements' do
      expect(reader.xml_first_value).to be_nil
    end

    it 'skips a nil element' do
      element_with_value = element('<EffectiveName Value="My Track"/>')

      expect(reader.xml_first_value(nil, element_with_value)).to eq('My Track')
    end
  end

  describe '#xml_bool?' do
    context 'when the value is true' do
      it 'returns true' do
        el = element('<IsTempoEnabled Value="true"/>')

        expect(reader.xml_bool?(el)).to be true
      end

      it 'is case insensitive' do
        el = element('<IsTempoEnabled Value="True"/>')

        expect(reader.xml_bool?(el)).to be true
      end
    end

    context 'when the value is false' do
      it 'returns false' do
        el = element('<IsTempoEnabled Value="false"/>')

        expect(reader.xml_bool?(el)).to be false
      end
    end

    context 'when the element is missing' do
      it 'returns false rather than nil' do
        expect(reader.xml_bool?(nil)).to be false
      end

      it 'returns false for an element with no value' do
        el = element('<IsTempoEnabled/>')

        expect(reader.xml_bool?(el)).to be false
      end
    end

    context 'when the value is not a boolean' do
      it 'returns false' do
        el = element('<IsTempoEnabled Value="maybe"/>')

        expect(reader.xml_bool?(el)).to be false
      end
    end
  end
end
