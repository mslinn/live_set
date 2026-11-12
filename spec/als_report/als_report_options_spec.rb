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

  describe 'the time zone' do
    around do |example|
      original = ENV.to_hash
      example.run
      ENV.replace(original)
    end

    it 'is America/Toronto when the TZ environment variable is not set' do
      ENV.delete('TZ')

      options, = described_class.parse_options(['/music/set.als'])

      expect(options[:time_zone]).to eq('America/Toronto')
    end

    it 'is the TZ environment variable when it is set' do
      ENV['TZ'] = 'America/Chicago'

      options, = described_class.parse_options(['/music/set.als'])

      expect(options[:time_zone]).to eq('America/Chicago')
    end

    it 'is America/Toronto when the TZ environment variable is empty' do
      ENV['TZ'] = ''

      options, = described_class.parse_options(['/music/set.als'])

      expect(options[:time_zone]).to eq('America/Toronto')
    end

    it 'is the time zone of the option when the option is given' do
      ENV['TZ'] = 'America/Chicago'

      options, = described_class.parse_options(['-z', 'UTC', '/music/set.als'])

      expect(options[:time_zone]).to eq('UTC')
    end
  end

  it 'reports no machine when the option is not given' do
    options, = described_class.parse_options(['/music/set.als'])

    expect(options[:report_machine]).to be false
  end

  it 'reports the machine when the option is given' do
    options, = described_class.parse_options(['--report_machine', '/music/set.als'])

    expect(options[:report_machine]).to be true
  end

  it 'names no set of a project when no name is given' do
    options, = described_class.parse_options(['/music/project'])

    expect(options[:als]).to eq []
  end

  it 'collects the names of the sets of a project' do
    options, = described_class.parse_options(['--als', 'a.als', '--als', 'b.als', '/music/project'])

    expect(options[:als]).to eq ['a.als', 'b.als']
  end
end
