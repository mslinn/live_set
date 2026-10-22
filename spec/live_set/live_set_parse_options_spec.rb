require 'spec_helper'
require 'live_set/live_set_options'

RSpec.describe LiveSet, '.parse_options' do
  it 'returns the default log level when no options are given' do
    options, = described_class.parse_options(['/music/set.als'])

    expect(options[:loglevel]).to eq('WARN')
  end

  it 'leaves the remaining arguments in order' do
    _, remaining = described_class.parse_options(['/music/set.als'])

    expect(remaining).to eq(['/music/set.als'])
  end

  it 'parses the convert11 option' do
    options, = described_class.parse_options(['-11', '/music/set.als'])

    expect(options[:convert11]).not_to be_nil
  end

  it 'parses the force option' do
    options, = described_class.parse_options(['-f', '/music/set.als'])

    expect(options[:force]).to be true
  end

  it 'normalizes the log level to uppercase' do
    options, = described_class.parse_options(['-l', 'debug', '/music/set.als'])

    expect(options[:loglevel]).to eq('DEBUG')
  end

  it 'keeps a path with spaces intact' do
    _, remaining = described_class.parse_options(['/music/my set.als'])

    expect(remaining).to eq(['/music/my set.als'])
  end
end
