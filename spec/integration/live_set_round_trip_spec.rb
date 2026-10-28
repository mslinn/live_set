require 'spec_helper'
require 'stringio'
require 'conversions'
require 'demo_sets'
require 'support/live_harness/live_installations'
require 'support/gui_harness'

# The round trip: an original Live 11 set is saved in Live 12, converted back to the Live 11
# format, read back as XML, and then opened in Live 11. The point is to prove that the
# conversion preserves the meaningful structure and that Live 11 accepts the converted result.
#
# The structural gate happens before Live 11 is launched. A file that is malformed or missing
# required elements should fail in Ruby before the GUI is involved. The GUI check is only the
# behavioural proof that Live 11 accepts the result.
#
# Live is a GUI program, so it is launched on the Windows side of the machine, and it takes
# about half a minute to start and load a set. The Live 11 launch is part of the round trip,
# so the spec runs it when the installation is present and the live log is available.
#
# See TODO.md N42 and docs/als_format.md section 2.5.
RSpec.describe LiveSet, 'the round trip through Live 11' do # rubocop:disable RSpec/DescribeMethod
  # The official Live 11 demo set supplied with Live 11. This is the source of truth for the
  # round trip.
  let(:live11_path) { DemoSets.edition '11', 'Suite' }

  # The Live 12 version of the same set, made by opening the Live 11 demo set in Live 12 and
  # saving it.
  let(:live12_path) { DemoSets.converted '11', 'Suite' }

  # The set, converted to the Live 11 format.
  let(:converted_path) { Conversions.output_path Conversions.set_path live12_path, 'round-trip' }

  # The converted set, read back as XML.
  # The test set refers to samples that are not copied into the temporary conversion directory.
  # Loading it prints one warning for every missing sample; those warnings are expected here and
  # would otherwise bury the RSpec output.
  let(:converted_document) do
    original_stdout = $stdout
    $stdout = StringIO.new
    Conversions.in_process live12_path
  ensure
    $stdout = original_stdout
  end

  # The Live 11 installation.
  let(:installation) { LiveInstallations.version '11' }

  # The log that Live writes while opening a set.
  let(:preferences) { LiveInstallations.preferences '11' }
  let(:log_path) { preferences && File.join(preferences, 'Log.txt') }

  # What happened when Live was launched with the converted set.
  let(:result) do
    @result ||= GuiHarness::LiveLauncher.launch installation.executable,
                                                converted_path,
                                                log:     log_path,
                                                timeout: 30
  end

  around do |example|
    example.run
  ensure
    if example.exception
      FileUtils.rm_f(converted_path)
      FileUtils.rm_rf(File.dirname(converted_path))
    end
  end

  before do
    skip 'the Live 11 demo set is not installed' if live11_path.nil? || !File.exist?(live11_path)
    skip 'the Live 12 version of the Live 11 demo set has not been made yet' if live12_path.nil? || !File.exist?(live12_path)
    skip 'Live 11 is not installed' if installation.nil? || installation.executable.nil?
    skip 'Live 11 preferences are not available' if preferences.nil? || log_path.nil?
  end

  describe 'opening the converted set in Live 11' do
    it 'does not put up an error' do
      expect(result.dialog).to be_nil
    end

    it 'finishes loading the set' do
      expect(result.log).to include 'End ExchangeDocument'
    end
  end

  describe 'the XML preflight gate' do
    it 'keeps the converted file structurally valid before Live 11 is launched' do
      expect(converted_document.at('//Ableton')['Creator']).to eq('Ableton Live 11.3.21')
      expect(converted_document.at('//Ableton')['MinorVersion']).to eq('11.0_11300')
      expect(converted_document.xpath('//ContentLanes').length).to eq(1)
      expect(converted_document.xpath('//ExpressionLanes').length).to eq(1)
      expect(converted_document.xpath('//ContentLanes/MidiEditorLaneModel')).to be_empty
      expect(converted_document.xpath('//ContentLanes/ExpressionLane')).not_to be_empty
      expect(converted_document.xpath('//InstrumentMeld|//Roar|//MxPatchRef')).to be_empty
      expect(converted_document.xpath('//Oversampling')).not_to be_empty
    end
  end

  describe 'converting the set' do
    it 'writes a set' do
      set = Conversions.set_path live12_path, 'round-trip'

      expect { described_class.new(set).modify_als }
        .to output.to_stdout

      expect(File.exist?(converted_path)).to be true
    end
  end
end
