require 'spec_helper'
require 'support/live_harness/live_keys'

RSpec.describe LiveKeys do
  subject(:keys) { described_class.new }

  describe '#press?' do
    context 'when the process is not running' do
      it 'returns false' do
        expect(keys.press?(999_999, 'n')).to be false
      end
    end

    context 'when the process is running' do
      # The id of a process that is certainly running: this one.
      let(:process_id) { Process.pid }

      it 'returns false when the process cannot be activated' do
        # The WSL shell is not a Windows program, so AppActivate cannot find it.
        expect(keys.press?(process_id, 'n')).to be false
      end
    end
  end

  describe 'the script it writes' do
    it 'is a PowerShell script' do
      expect(described_class::SCRIPT).to include 'WScript.Shell'
    end

    it 'brings the program forward before sending the key' do
      expect(described_class::SCRIPT).to include 'AppActivate'
    end

    it 'sends the key' do
      expect(described_class::SCRIPT).to include 'SendKeys'
    end
  end
end
