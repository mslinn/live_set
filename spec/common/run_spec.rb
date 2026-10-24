require 'spec_helper'
require 'common/run'

RSpec.describe Run do
  subject(:runner) { Class.new { include Run }.new }

  # Captures the status that the runner exits with, or nil if it does not exit.
  def exit_status_for(command, success_statuses: [0])
    allow(Log).to receive(:error)
    runner.run_capture_stdout(command, success_statuses: success_statuses)
    nil
  rescue SystemExit => e
    e.status
  end

  describe '#run_capture_stdout' do
    let(:file_a) { File.join(Dir.tmpdir, 'run_spec_a.txt') }
    let(:file_b) { File.join(Dir.tmpdir, 'run_spec_b.txt') }

    before do
      File.write(file_a, "line1\nline2\n")
      File.write(file_b, "line1\nline2 changed\n")
    end

    after do
      FileUtils.rm_f(file_a)
      FileUtils.rm_f(file_b)
    end

    context 'when the command succeeds' do
      it 'returns the output lines' do
        output = runner.run_capture_stdout("cat #{file_a}")

        expect(output).to eq(%w[line1 line2])
      end
    end

    context 'when the command produces no output' do
      it 'returns an empty array' do
        output = runner.run_capture_stdout("diff #{file_a} #{file_a}", success_statuses: [0, 1])

        expect(output).to be_empty
      end
    end

    context 'when the exit status indicates the files differ' do
      it 'treats that status as success when it is listed' do
        output = runner.run_capture_stdout("diff #{file_a} #{file_b}", success_statuses: [0, 1])

        expect(output).to eq(['2c2', '< line2', '---', '> line2 changed'])
      end

      it 'exits when that status is not listed' do
        expect(exit_status_for("diff #{file_a} #{file_b}")).to eq(1)
      end
    end

    context 'when the command fails' do
      it 'does not exit when the status is a success status' do
        expect(exit_status_for("diff #{file_a} #{file_b}", success_statuses: [0, 1])).to be_nil
      end

      it 'exits when the status is not a success status' do
        expect(exit_status_for("diff #{file_a} /nonexistent/file", success_statuses: [0, 1])).to eq(2)
      end
    end

    context 'when the exit status is reported' do
      it 'reports the exit code rather than the raw wait status' do
        expect(exit_status_for("diff #{file_a} #{file_b}")).to eq(1)
      end
    end

    describe 'output formatting' do
      it 'preserves leading whitespace on each line' do
        File.write(file_b, "a\n  indented\n")

        output = runner.run_capture_stdout("diff #{file_a} #{file_b}", success_statuses: [0, 1])

        expect(output).to include('>   indented')
      end

      it 'preserves blank lines' do
        File.write(file_b, "a\n\nb\n")

        output = runner.run_capture_stdout("diff #{file_a} #{file_b}", success_statuses: [0, 1])

        expect(output).to include('> ')
      end

      it 'does not split a line on interior whitespace' do
        File.write(file_b, "a\nb c d\n")

        output = runner.run_capture_stdout("diff #{file_a} #{file_b}", success_statuses: [0, 1])

        expect(output).to include('> b c d')
      end
    end
  end
end
