require 'spec_helper'
require 'live_set/tx/live_versions'
require 'support/live_versions'

# The registry of the bridges, and the conversions the bridges make.
#
# The registry is keyed by the version a bridge leads to, and an entry is a function of a
# document: it takes a document and returns the converted document. A conversion from one
# version to another is the composition of the bridges between them.
RSpec.describe LiveVersions do
  describe '.bridge_for' do
    it 'is the bridge that converts a set of Live 12' do
      expect(described_class.bridge_for(LIVE_12)).to eq(Live11And12)
    end

    it 'is the bridge that converts a set of Live 11' do
      expect(described_class.bridge_for(LIVE_11)).to eq(Live11And12)
    end

    it 'raises for a set of a version it has no bridge for' do
      expect { described_class.bridge_for('10.0_10000') }
        .to raise_error(ArgumentError, /no bridge converts a set of version/)
    end
  end

  describe '.bridges_between' do
    it 'is the bridge that stands between Live 11 and Live 12' do
      bridges = described_class.bridges_between(from: 11, to: 12)

      expect(bridges.size).to eq(1)
      expect(bridges.first.call(live_document(LIVE_11)).root['MinorVersion']).to eq(LIVE_12)
    end

    it 'is the same bridge going the other way' do
      bridges = described_class.bridges_between(from: 12, to: 11)

      expect(bridges.size).to eq(1)
      expect(bridges.first.call(live_document(LIVE_12)).root['MinorVersion']).to eq(LIVE_11)
    end

    it 'raises for a version it has no bridge for' do
      expect { described_class.bridges_between(from: 8, to: 12) }
        .to raise_error(ArgumentError, /no bridge leads to Live 9/)
    end
  end

  describe '.convert' do
    it 'converts a set of Live 12 into a set of Live 11' do
      document = live_document(LIVE_12, '<LiveSet><MainTrack/></LiveSet>')

      expect(described_class.convert(document, from: 12, to: 11).root['MinorVersion']).to eq(LIVE_11)
    end

    it 'converts a set of Live 11 into a set of Live 12' do
      document = live_document(LIVE_11, '<LiveSet><MasterTrack/></LiveSet>')

      expect(described_class.convert(document, from: 11, to: 12).root['MinorVersion']).to eq(LIVE_12)
    end
  end
end
