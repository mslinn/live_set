require 'spec_helper'
require 'live_launcher'

RSpec.describe LiveLauncher do
  describe '.windows_path' do
    it 'converts a WSL path to a Windows path' do
      result = described_class.windows_path('/mnt/c/Program Files/Ableton/Live 11 Suite/Program/Ableton Live 11 Suite.exe')

      expect(result).to match(/\AC:\\Program Files\\Ableton\\Live 11 Suite\\Program\\Ableton Live 11 Suite.exe\z/)
    end
  end

  describe '.parse' do
    it 'reads the launch result from the launcher output' do
      output = <<~TEXT
        DIALOG: none
        CRASHED: no
        --- LOG ---
        Loading document "C:/ProgramData/Ableton/Live 11 Suite/Resources/Core Library/Lessons/Demo Songs/demo.als"
        Begin ExchangeDocument
        End ExchangeDocument
      TEXT
      status = OpenStruct.new(exitstatus: 0)

      result = described_class.send(:parse, output, status)

      expect(result.exit_code).to eq(0)
      expect(result.dialog).to be_nil
      expect(result.crashed).to be false
      expect(result.loaded).to be true
      expect(result.log).to include('End ExchangeDocument')
    end

    it 'detects a fatal crash from the launcher output' do
      output = <<~TEXT
        DIALOG: A serious program error has occurred.
        CRASHED: yes
        --- LOG ---
        Begin ExchangeDocument
        Exception: Fatal Error
      TEXT
      status = OpenStruct.new(exitstatus: 1)

      result = described_class.send(:parse, output, status)

      expect(result.exit_code).to eq(1)
      expect(result.dialog).to eq('A serious program error has occurred.')
      expect(result.crashed).to be true
      expect(result.loaded).to be false
    end
  end
end
