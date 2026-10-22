require 'spec_helper'
require 'common/xml'

RSpec.describe Xml do
  subject(:reader) { Class.new { include Xml }.new }

  # Parses an XML fragment and returns its root element.
  def element(xml)
    Nokogiri::XML(xml).root
  end

  describe '#xml_value' do
    context 'when the value is in a Value attribute' do
      it 'returns the attribute value' do
        el = element('<EffectiveName Value="My Track"/>')

        expect(reader.xml_value(el)).to eq('My Track')
      end

      it 'ignores the element text when the attribute is present' do
        el = element('<EffectiveName Value="My Track">ignored</EffectiveName>')

        expect(reader.xml_value(el)).to eq('My Track')
      end
    end

    context 'when the value is the element text' do
      it 'returns the text' do
        el = element('<EffectiveName>My Track</EffectiveName>')

        expect(reader.xml_value(el)).to eq('My Track')
      end

      it 'strips surrounding whitespace' do
        el = element("<EffectiveName>\n  My Track\n</EffectiveName>")

        expect(reader.xml_value(el)).to eq('My Track')
      end
    end

    context 'when the value is nested text' do
      # Nokogiri's Node#text recurses into child elements, so a single read covers this shape.
      it 'returns the innermost text' do
        el = element('<Path><Path>E:/media/song.mp3</Path></Path>')

        expect(reader.xml_value(el)).to eq('E:/media/song.mp3')
      end
    end

    context 'when there is no value' do
      it 'returns nil for a nil element' do
        expect(reader.xml_value(nil)).to be_nil
      end

      it 'returns nil for an empty element' do
        el = element('<EffectiveName/>')

        expect(reader.xml_value(el)).to be_nil
      end

      it 'returns nil for an element with only whitespace' do
        el = element("<EffectiveName>  \n </EffectiveName>")

        expect(reader.xml_value(el)).to be_nil
      end

      it 'returns nil for an element with an empty Value attribute' do
        el = element('<EffectiveName Value=""/>')

        expect(reader.xml_value(el)).to be_nil
      end

      it 'returns nil for an element with an empty Value attribute but some text' do
        # An empty Value attribute is treated as absent, so the text is used instead.
        el = element('<EffectiveName Value="">My Track</EffectiveName>')

        expect(reader.xml_value(el)).to eq('My Track')
      end
    end
  end

  describe '#xml_first_value' do
    it 'returns the value of the first element that has one' do
      first = element('<EffectiveName/>')
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
      it 'returns true for element text' do
        el = element('<IsTempoEnabled>true</IsTempoEnabled>')

        expect(reader.xml_bool?(el)).to be true
      end

      it 'returns true for a Value attribute' do
        el = element('<IsTempoEnabled Value="true"/>')

        expect(reader.xml_bool?(el)).to be true
      end

      it 'is case insensitive' do
        el = element('<IsTempoEnabled>True</IsTempoEnabled>')

        expect(reader.xml_bool?(el)).to be true
      end
    end

    context 'when the value is false' do
      it 'returns false for element text' do
        el = element('<IsTempoEnabled>false</IsTempoEnabled>')

        expect(reader.xml_bool?(el)).to be false
      end

      it 'returns false for a Value attribute' do
        el = element('<IsTempoEnabled Value="false"/>')

        expect(reader.xml_bool?(el)).to be false
      end
    end

    context 'when the element is missing' do
      it 'returns false rather than nil' do
        expect(reader.xml_bool?(nil)).to be false
      end

      it 'returns false for an empty element' do
        el = element('<IsTempoEnabled/>')

        expect(reader.xml_bool?(el)).to be false
      end
    end

    context 'when the value is not a boolean' do
      it 'returns false' do
        el = element('<IsTempoEnabled>maybe</IsTempoEnabled>')

        expect(reader.xml_bool?(el)).to be false
      end

      it 'warns about the unrecognized value' do
        el = element('<IsTempoEnabled>maybe</IsTempoEnabled>')
        allow(Log).to receive(:warn)

        reader.xml_bool?(el, description: 'Scene 1 IsTempoEnabled')

        expect(Log).to have_received(:warn).with(/maybe/)
      end
    end
  end

  # CAVEAT: the shapes exercised above are the ones this project has evidence for:
  #
  #   * The `Value` attribute shape comes from `als_notes.md`, which shows Live 8 writing
  #     `<RelativePath Value="Samples/Imported/song1.mp3" />`.
  #   * The text shape comes from `after_real_pain.xsd`, the schema this project generated from a
  #     real Live 12 set, in which `EffectiveName`, `UserName` and `Annotation` are `xs:string`
  #     elements (text, not attributes).
  #
  # Two things have NOT been confirmed against a real Live 12 set:
  #
  #   1. Whether every value in a Live 12 set uses the text shape. A Live 12 set may mix shapes
  #      within one file, or use a shape not represented here.
  #   2. Whether `UserName` should be preferred over `EffectiveName` for a track's display name,
  #      and whether `Annotation` ever serves that purpose. Ableton's `EffectiveName` is the
  #      "resolved" name (it accounts for renames and duplicate-track numbering), so it is
  #      preferred; the fallback order beyond that is an assumption.
  #
  # If a real set turns out to use a shape these tests do not cover, add the shape here first.
  # The helper is deliberately shape-agnostic: it prefers a `Value` attribute and falls back to
  # text, so most new shapes need no code change, only a test.
end
