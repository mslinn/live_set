require 'spec_helper'
require 'common/command_options'

RSpec.describe CommandOptions, '.loglevel_error' do
  context 'when the loglevel is valid' do
    it 'returns no error' do
      options = { loglevel: 'WARN' }

      expect(described_class.loglevel_error(options)).to be_nil
    end

    it 'normalizes the loglevel to uppercase' do
      options = { loglevel: 'debug' }

      described_class.loglevel_error(options)

      expect(options[:loglevel]).to eq('DEBUG')
    end
  end

  context 'when the loglevel is not valid' do
    it 'returns an error message' do
      options = { loglevel: 'BOGUS' }

      expect(described_class.loglevel_error(options)).to include('BOGUS')
    end

    it 'lists the valid levels' do
      options = { loglevel: 'BOGUS' }

      expect(described_class.loglevel_error(options)).to include('DEBUG')
    end
  end

  context 'when there is no loglevel' do
    it 'returns no error' do
      expect(described_class.loglevel_error({})).to be_nil
    end
  end
end
