require 'spec_helper'
require 'live_launcher'
require_relative '../../demo_sets'
require_relative 'live_installations'

def running_in_wsl?
  ENV['WSL_DISTRO_NAME'] || ENV['WSL_INTEROP'] ||
    (File.exist?('/proc/version') && File.read('/proc/version').downcase.include?('microsoft'))
end

RSpec.describe LiveLauncher do
  let(:ableton_home) { '/mnt/c/ProgramData/Ableton' }
  let(:ableton_11_home) { "#{ableton_home}/Live 11 Suite" }
  let(:ableton_11_program) { "#{ableton_11_home}/Program/Ableton Live 11 Suite.exe" }
  let(:ableton_11_demo_home) { "#{ableton_11_home}/Resources/Core Library/Lessons/Demo Songs/" }
  let(:ableton_11_demo_set) { "#{ableton_11_demo_home}/Ninajirachi - In The Rain (Live 11 Suite Demo).als" }

  describe '.windows_path' do
    it 'converts a WSL path to a Windows path' do
      result = described_class.windows_path ableton_11_program

      expect(result).to match(/\AC:\\ProgramData\\Ableton\\Live 11 Suite\\Program\\Ableton Live 11 Suite.exe\z/)
    end
  end

  # This tests that messages are properly categorized. This does not verify that the messages can be extracted from Live
  # when it is running under Windows.
  describe '.classify_dialog' do
    # TODO: replace these matching text messages with DIALOG_RULES[]{}.pattern,.type,.action} values
    it 'recognizes each supported dialog family and the required dismissal action' do
      expect(described_class.classify_dialog('A serious program error has occurred.')).to eq(
        { type: :fatal, action: { type: 'button', value: 'OK' } }
      )
      msg = "Live unexpectedly quit while you were working on the Live Set 'Untitled'. Would you like to recover your work?"
      expect(described_class.classify_dialog(msg)).to eq(
        { type: :recovery, action: { type: 'button', value: 'No' } }
      )
      expect(described_class.classify_dialog('Save changes?')).to eq(
        { type: :save_changes, action: { type: 'button', value: 'No' } }
      )
      expect(described_class.classify_dialog('Some unexpected Live window')).to eq(
        { type: :unknown, action: nil }
      )
    end
  end

  describe 'GUI visibility matrix', :live_integration do
    before do
      skip 'this is a WSL + Windows Ableton Live integration test' unless running_in_wsl?

      @installation = LiveInstallations.version('11')
      skip 'Live 11 is not installed on this machine' if @installation.nil? || @installation.executable.nil?

      @demo_set = DemoSets.edition('11', 'Suite')
      skip 'the Live 11 demo set is not installed on this machine' if @demo_set.nil? || !File.exist?(@demo_set)

      @log_path = LiveInstallations.preferences('11')
      skip 'Live 11 has no writable Preferences directory configured' if @log_path.nil?
      @log_path = File.join(@log_path, 'Log.txt')
    end

    %i[normal minimized hidden].each do |visibility|
      it "succeeds when the launcher is #{visibility}" do
        result = described_class.launch(@installation.executable, @demo_set, log: @log_path, timeout: 30, visibility: visibility)

        expect(result).to be_a(described_class::Result)
        expect(result.success?).to be(true)
        expect(result.outcome).to eq(:loaded)
      end

      it "fails cleanly when the launcher is #{visibility}" do
        missing_set = File.join(Dir.pwd, 'spec', 'support', 'live_harness', 'missing_live_set.als')
        result = described_class.launch(@installation.executable, missing_set, log: @log_path, timeout: 20, visibility: visibility)

        expect(result).to be_a(described_class::Result)
        expect(result.outcome).to(satisfy { |outcome| %i[blocked unknown crashed].include?(outcome) })
      end
    end
  end

  # Examine the top-level Ableton Live window and look for problems
  describe '.parse' do
    it 'reads the launch result from the launcher output' do
      winpath = described_class.windows_path ableton_11_demo_set
      output = <<~TEXT
        DIALOG: none
        CRASHED: no
        --- LOG ---
        Loading document "#{winpath}"
        Begin ExchangeDocument
        End ExchangeDocument
      TEXT

      status = Struct.new(:exitstatus, keyword_init: true).new(exitstatus: 0)
      result = described_class.send(:parse, output, status)

      expect(result.exit_code).to eq(0)
      expect(result.dialog).to be_nil
      expect(result.dialog_type).to be_nil
      expect(result.dismiss_action).to be_nil
      expect(result.outcome).to eq(:loaded)
      expect(result.crashed).to be false
      expect(result.loaded).to be true
      expect(result.log).to include('End ExchangeDocument')
    end

    it 'detects a fatal crash from the launcher output' do
      output = <<~TEXT
        DIALOG: A serious program error has occurred.
        DIALOG_TYPE: fatal
        DISMISS_ACTION: button=OK
        CRASHED: yes
        --- LOG ---
        Begin ExchangeDocument
        Exception: Fatal Error
      TEXT
      status = Struct.new(:exitstatus, keyword_init: true).new(exitstatus: 1)
      result = described_class.send(:parse, output, status)

      expect(result.exit_code).to eq(1)
      expect(result.dialog).to eq('A serious program error has occurred.')
      expect(result.dialog_type).to eq(:fatal)
      expect(result.dismiss_action).to eq({ type: 'button', value: 'OK' })
      expect(result.outcome).to eq(:crashed)
      expect(result.crashed).to be true
      expect(result.loaded).to be false
    end

    it 'recognizes the restore document prompt and the button that dismisses it' do
      output = <<~TEXT
        DIALOG: Live unexpectedly quit while you were working on the Live Set 'Untitled'. Would you like to recover your work?
        DIALOG_TYPE: recovery
        DISMISS_ACTION: button=No
        CRASHED: no
        --- LOG ---
        Default App: Checking whether to restore the document...
        Message Box: Live unexpectedly quit while you were working on the Live Set 'Untitled'. Would you like to recover your work?
      TEXT

      status = Struct.new(:exitstatus, keyword_init: true).new(exitstatus: 0)
      result = described_class.send(:parse, output, status)

      expect(result.dialog_type).to eq(:recovery)
      expect(result.dismiss_action).to eq({ type: 'button', value: 'No' })
      expect(result.outcome).to eq(:blocked)
      expect(result.loaded).to be false
    end

    it 'recognises a save changes prompt and the button that dismisses it' do
      output = <<~TEXT
        DIALOG: Save changes?
        DIALOG_TYPE: save_changes
        DISMISS_ACTION: button=No
        CRASHED: no
        --- LOG ---
        Save changes?
      TEXT

      status = Struct.new(:exitstatus, keyword_init: true).new(exitstatus: 0)
      result = described_class.send(:parse, output, status)

      expect(result.dialog_type).to eq(:save_changes)
      expect(result.dismiss_action).to eq({ type: 'button', value: 'No' })
      expect(result.outcome).to eq(:blocked)
    end

    it 'marks an unrecognised top-level modal as unknown rather than silently ignoring it' do
      output = <<~TEXT
        DIALOG: Some unexpected Live window
        CRASHED: no
        --- LOG ---
        Some unexpected Live window
      TEXT

      status = Struct.new(:exitstatus, keyword_init: true).new(exitstatus: 0)
      result = described_class.send(:parse, output, status)

      expect(result.dialog_type).to eq(:unknown)
      expect(result.dismiss_action).to be_nil
      expect(result.outcome).to eq(:unknown)
      expect(result.dialog).to eq('Some unexpected Live window')
    end
  end

  describe 'real Live integration', :live_integration do
    before do
      skip 'this is a WSL + Windows Ableton Live integration test' unless running_in_wsl?

      @installation = LiveInstallations.version('11')
      skip 'Live 11 is not installed on this machine' if @installation.nil? || @installation.executable.nil?

      @demo_set = DemoSets.edition('11', 'Suite')
      skip 'the Live 11 demo set is not installed on this machine' if @demo_set.nil? || !File.exist?(@demo_set)

      @log_path = LiveInstallations.preferences('11')
      skip 'Live 11 has no writable Preferences directory configured' if @log_path.nil?
      @log_path = File.join(@log_path, 'Log.txt')
    end

    it 'launches the real app and reports the actual launcher outcome' do
      result = described_class.launch(@installation.executable, @demo_set, log: @log_path, timeout: 60)

      expect(result).to be_a(described_class::Result)
      expect(result.exit_code).to be_a(Integer)
      expect(%i[loaded blocked crashed unknown]).to include(result.outcome)
    end
  end
end
