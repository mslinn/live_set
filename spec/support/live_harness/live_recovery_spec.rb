require 'spec_helper'
require 'support/live_harness/live_recovery'

RSpec.describe LiveRecovery do
  # A temporary folder to stand in for Live's Preferences folder.
  # The recovery reader.
  subject(:recovery) { described_class.new preferences }

  let(:preferences) { Dir.mktmpdir }

  after { FileUtils.remove_entry preferences }

  describe '#pending?' do
    it 'is false when there is no recovery file' do
      expect(recovery.pending?).to be false
    end

    it 'is true when there is a recovery file' do
      FileUtils.cp fixture, recovery.info_path

      expect(recovery.pending?).to be true
    end
  end

  describe '#set_path' do
    it 'is nil when there is no recovery file' do
      expect(recovery.set_path).to be_nil
    end

    context 'when there is a recovery file' do
      before { FileUtils.cp fixture, recovery.info_path }

      it 'names the set Live was working on' do
        expect(recovery.set_path).to eq(
          'C:/ProgramData/Ableton/Live 11 Suite/Resources/Core Library/Lessons/Demo Songs/' \
          'Ninajirachi - In The Rain (Live 11 Suite Demo).als'
        )
      end

      it 'does not name the recovery point in the Preferences folder' do
        expect(recovery.set_path).not_to include 'Preferences/BaseFiles'
      end
    end
  end

  describe '#utf16_strings' do
    it 'is empty when the file does not exist' do
      expect(recovery.utf16_strings('/no/such/file.cfg')).to be_empty
    end

    it 'finds the paths in a real recovery file' do
      strings = recovery.utf16_strings fixture

      expect(strings).to include(a_string_matching(%r{^C:/ProgramData/Ableton/Live 11 Suite/}))
    end
  end

  describe '#crash_folder' do
    it 'is the Crash folder in the Preferences folder' do
      expect(recovery.crash_folder).to eq(File.join(preferences, 'Crash'))
    end
  end

  # A real crash-recovery file, taken from Live 11's Preferences folder.
  def fixture
    File.expand_path '../fixtures/crash_recovery_info.cfg', __dir__
  end
end
