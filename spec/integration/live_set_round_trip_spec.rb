require 'spec_helper'
require 'stringio'
require 'zlib'
require 'conversions'
require 'demo_sets'
require 'live_installations'
require 'support/gui_harness'

# The conversion and the launch of Live are done once, and every example of the spec below
# looks at the same results.
#
# The conversion has to happen before Live is launched: Live is launched with the converted set,
# so the set has to be there when Live starts. The launch takes about half a minute, and the
# examples ask the same questions about the same launch, so Live is launched once as well.
module RoundTrip
  class << self
    # The Live 12 version of the Live 11 Suite demo set.
    #
    # @return [String] the path of the set
    def source
      DemoSets.converted '11', 'Suite'
    end

    # The copy of the set that is converted.
    #
    # @return [String] the path of the copy
    def set
      Conversions.set_path source, 'round-trip'
    end

    # The converted set.
    #
    # @return [String] the path of the converted set
    def converted
      Conversions.output_path set
    end

    # What the conversion did.
    #
    # The conversion writes the set next to the copy it converts, so it is done once: a second
    # conversion would find the set that is already there.
    #
    # @return [LiveSetConverter::Result] what the conversion did
    def conversion
      @conversion ||= silence_output { LiveSet.new(set).modify_als }
    end

    # The converted set, read back as XML.
    #
    # @return [Nokogiri::XML::Document] the converted set
    def document
      @document ||= Nokogiri::XML Zlib::GzipReader.open(converted, &:read)
    end

    # What happened when Live was launched with the converted set.
    #
    # @return [Object] the result of the launch
    def launch
      @launch ||= begin
        conversion
        installation = LiveInstallations.version '11'
        preferences = LiveInstallations.preferences '11'
        log_path = preferences && File.join(preferences, 'Log.txt')
        GuiHarness::LiveLauncher.launch installation.executable, converted, log: log_path, timeout: 13
      end
    end
  end
end

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
# See TODO.md N42 and docs/live_11_12_diff.md, "The lane types Live 11 does not have".
RSpec.describe LiveSet, 'the round trip through Live 11' do # rubocop:disable RSpec/DescribeMethod
  # The official Live 11 demo set supplied with Live 11. This is the source of truth for the
  # round trip.
  let(:live11_path) { DemoSets.edition '11', 'Suite' }

  # The Live 12 version of the same set, made by opening the Live 11 demo set in Live 12 and
  # saving it.
  let(:live12_path) { DemoSets.converted '11', 'Suite' }

  # The set, converted to the Live 11 format.
  let(:converted_path) { RoundTrip.converted }

  # The converted set, read back as XML.
  let(:converted_document) { RoundTrip.document }

  # The Live 11 installation.
  let(:installation) { LiveInstallations.version '11' }

  # The log that Live writes while opening a set.
  let(:preferences) { LiveInstallations.preferences '11' }
  let(:log_path) { preferences && File.join(preferences, 'Log.txt') }

  # What happened when Live was launched with the converted set.
  let(:result) { RoundTrip.launch }

  around do |example|
    example.run
  ensure
    if example.exception
      FileUtils.rm_f(converted_path)
      FileUtils.rm_rf(File.dirname(converted_path))
    end
  end

  before do
    require_fixture 'the Live 11 Suite demo set', live11_path
    require_fixture 'the Live 12 conversion of the Live 11 Suite demo set', live12_path
    require_fixture 'the Live 11 executable', installation&.executable
    require_fixture 'the Live 11 preferences log', log_path
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
      conversion = RoundTrip.conversion

      expect(conversion.status).to eq(:converted)
      expect(conversion.path).to eq(converted_path)
      expect(File.exist?(converted_path)).to be true
    end
  end
end
