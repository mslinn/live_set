require 'spec_helper'
require 'als_report/als_report_options'

RSpec.describe AlsReport, '.parse_options' do
  it 'returns the default log level when no options are given' do
    options, = described_class.parse_options(['/music/set.als'])

    expect(options[:loglevel]).to eq('WARN')
  end

  it 'leaves the remaining arguments in order' do
    _, remaining = described_class.parse_options(['/music/set.als'])

    expect(remaining).to eq(['/music/set.als'])
  end

  it 'parses the version option' do
    options, = described_class.parse_options(['-v'])

    expect(options[:version]).to be true
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
