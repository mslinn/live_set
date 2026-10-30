require 'spec_helper'
require 'support/gui_harness'
require 'demo_sets'
require 'live_installations'

RSpec.describe GuiHarness::Live::Launcher do
  let(:ableton_home) { '/mnt/c/ProgramData/Ableton' }

  let(:ableton_8_home) { "#{ableton_home}/Live 8" }
  let(:ableton_8_program) { "#{ableton_8_home}/Program/Ableton Live 8.exe" }
  # let(:ableton_8_demo_home) { "#{ableton_8_home}" }
  # let(:ableton_8_demo_set) { "#{ableton_8_demo_home}" }

  let(:ableton_9_home) { "#{ableton_home}/Live 9 Standard" }
  let(:ableton_9_program) { "#{ableton_9_home}/Program/Ableton Live 9 Standard.exe" }
  let(:ableton_9_demo_home) { "#{ableton_9_home}/Resources/Core Library/Lessons/Sets" }
  let(:ableton_9_demo_set) { "#{ableton_9_demo_home}/Amp-Drum Examples.als" }

  let(:ableton_10_home) { "#{ableton_home}/Live 10 Standard" }
  let(:ableton_10_program) { "#{ableton_10_home}/Program/Ableton Live 10 Standard.exe" }
  let(:ableton_10_demo_home) { "#{ableton_10_home}/Resources/Core Library/Lessons/Demo Songs/" }
  let(:ableton_10_demo_set) { "#{ableton_10_demo_home}/Live 10 Intro Demo Song.als" }

  let(:ableton_11_home) { "#{ableton_home}/Live 11 Suite" }
  let(:ableton_11_program) { "#{ableton_11_home}/Program/Ableton Live 11 Suite.exe" }
  let(:ableton_11_demo_home) { "#{ableton_11_home}/Resources/Core Library/Lessons/Demo Songs" }
  let(:ableton_11_demo_set) { "#{ableton_11_demo_home}/Ninajirachi - In The Rain (Live 11 Intro Demo).als" }

  let(:ableton_12_home) { "#{ableton_home}/Live 12 Suite" }
  let(:ableton_12_program) { "#{ableton_12_home}/Program/Ableton Live 12 Suite.exe" }
  let(:ableton_12_demo_home) { "#{ableton_12_home}/Resources/Core Library/Lessons/Demo Songs" }
  let(:ableton_12_demo_set) { "#{ableton_12_demo_home}/Chuck Sutton - Patience (Live 12 Intro Demo).als" }

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
      require_wsl

      @installation = LiveInstallations.version('11')
      require_fixture 'the Live 11 executable', @installation&.executable

      @demo_set = DemoSets.edition('11', 'Suite')
      require_fixture 'the Live 11 Suite demo set', @demo_set

      @log_path = LiveInstallations.preferences('11')
      require_fixture 'the Live 11 preferences directory', @log_path
      @log_path = File.join(@log_path, 'Log.txt')
    end

    %i[normal minimized hidden].each do |visibility|
      it "succeeds when the launcher is #{visibility}" do
        result = described_class.launch(@installation.executable, @demo_set, log: @log_path, timeout: 13, visibility: visibility)

        expect(result).to be_a(described_class::Result)
        expect(result.success?).to be(true)
        expect(result.outcome).to eq(:loaded)
      end

      it "fails cleanly when the launcher is #{visibility}" do
        missing_set = File.join(Dir.pwd, 'spec', 'support', 'live_harness', 'missing_live_set.als')
        result = described_class.launch(@installation.executable, missing_set, log: @log_path, timeout: 13, visibility: visibility)

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
        Loading command-line document: done.
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

    it 'reports a document that could not be loaded as not loaded' do
      output = <<~TEXT
        DIALOG: The document "C:/missing.als" is corrupt and cannot be loaded.
        DIALOG_TYPE: unknown
        DISMISS_ACTION: none
        CRASHED: no
        --- LOG ---
        Begin ExchangeDocument
        End ExchangeDocument
        error: Failed to load command-line document: The document "C:/missing.als" is corrupt and cannot be loaded.
        Loading command-line document: done.
      TEXT

      status = Struct.new(:exitstatus, keyword_init: true).new(exitstatus: 0)
      result = described_class.send(:parse, output, status)

      expect(result.loaded).to be false
      expect(result.outcome).to eq(:unknown)
      expect(result.dialog).to include('cannot be loaded')
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
      require_wsl

      @installation = LiveInstallations.version('11')
      require_fixture 'the Live 11 executable', @installation&.executable

      @demo_set = DemoSets.edition('11', 'Suite')
      require_fixture 'the Live 11 Suite demo set', @demo_set

      @log_path = LiveInstallations.preferences('11')
      require_fixture 'the Live 11 preferences directory', @log_path
      @log_path = File.join(@log_path, 'Log.txt')
    end

    it 'launches the real app and reports the actual launcher outcome' do
      result = described_class.launch(@installation.executable, @demo_set, log: @log_path, timeout: 13)

      expect(result).to be_a(described_class::Result)
      expect(result.exit_code).to be_a(Integer)
      expect(result.dialog).to be_nil
      expect(result.crashed).to be(false)
      expect(result.loaded).to be(true)
      expect(result.outcome).to eq(:loaded)
    end
  end
end
