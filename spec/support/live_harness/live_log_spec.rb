require 'spec_helper'
require 'support/live_harness/live_log'

RSpec.describe LiveLog do
  # The path of a fixture.
  def fixture(name)
    File.expand_path "../fixtures/#{name}", __dir__
  end

  # A log reader over a fixture.
  def log(name)
    described_class.new fixture(name)
  end

  describe '#read' do
    context 'when Live loaded a set and quit normally' do
      subject(:outcome) { log('live_log_clean.txt').read }

      it 'reports that the set loaded' do
        expect(outcome.loaded).to be true
      end

      it 'reports that Live did not crash' do
        expect(outcome.crashed).to be false
      end

      it 'reports that Live exited cleanly' do
        expect(outcome.exited_cleanly).to be true
      end

      it 'reports the set that was opened' do
        expect(outcome.documents).to eq(
          ['C:\\ProgramData\\Ableton\\Live 11 Suite\\Resources\\Core Library\\Lessons\\Demo Songs\\' \
           'Ninajirachi - In The Rain (Live 11 Suite Demo).als']
        )
      end

      it 'reports that no document was offered for restore' do
        expect(outcome.restore_offered).to be false
      end

      it 'reports the run as successful' do
        expect(outcome.success?).to be true
      end
    end

    context 'when Live crashed' do
      subject(:outcome) { log('live_log_crash.txt').read }

      it 'reports that Live crashed' do
        expect(outcome.crashed).to be true
      end

      it 'does not report a clean exit' do
        expect(outcome.exited_cleanly).to be false
      end

      it 'reports the set that was being opened' do
        expect(outcome.documents.first).to end_with('converted to Live 12_11.als')
      end

      it 'does not report the set as loaded' do
        expect(outcome.loaded).to be false
      end

      it 'does not report the run as successful' do
        expect(outcome.success?).to be false
      end
    end

    context 'when Live offered to restore a document' do
      subject(:outcome) { log('live_log_restore.txt').read }

      it 'reports that the offer was made' do
        expect(outcome.restore_offered).to be true
      end

      it 'reports that the offer was answered' do
        expect(outcome.restore_answered).to be true
      end

      it 'reports the set that was opened afterwards' do
        expect(outcome.documents).to eq(
          ['C:\ProgramData\Ableton\Live 11 Suite\Resources\Builtin\Templates\DefaultLiveSet.als']
        )
      end
    end

    context 'when the log does not exist' do
      subject(:outcome) { described_class.new('/no/such/log.txt').read }

      it 'reports nothing loaded' do
        expect(outcome.loaded).to be false
      end

      it 'reports no crash' do
        expect(outcome.crashed).to be false
      end

      it 'reports no documents' do
        expect(outcome.documents).to be_empty
      end
    end
  end

  describe '#read_lines' do
    it 'reads from the beginning by default' do
      expect(log('live_log_crash.txt').read_lines.length).to eq(6)
    end

    it 'reads only what was written after an offset' do
      path = fixture 'live_log_crash.txt'
      offset = File.size(path) / 2

      lines = described_class.new(path).read_lines(offset)

      expect(lines.length).to be < 6
    end

    it 'reads the part of the log after the offset' do
      path = fixture 'live_log_crash.txt'
      offset = File.size(path) / 2

      lines = described_class.new(path).read_lines(offset)

      expect(lines.join("\n")).to include 'Fatal Error'
    end

    it 'reads nothing when the offset is past the end' do
      path = fixture 'live_log_crash.txt'

      expect(described_class.new(path).read_lines(File.size(path))).to be_empty
    end
  end

  describe '#size' do
    it 'is the size of the log' do
      expect(log('live_log_crash.txt').size).to eq(File.size(fixture('live_log_crash.txt')))
    end

    it 'is zero when the log does not exist' do
      expect(described_class.new('/no/such/log.txt').size).to eq(0)
    end
  end
end
