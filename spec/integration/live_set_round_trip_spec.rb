require 'spec_helper'
require 'conversions'
require 'demo_sets'
require 'live_installations'
require 'live_launcher'

# The round trip: a Live 12 set is converted to the Live 11 format, and Live 11 is asked to
# open the result.
#
# The conversion can be checked against the XML, and that is what the other specs do. But the
# XML being well formed is not the same as Live being able to read it, and only Live can say.
# So this spec launches Live 11 with the converted set and watches what happens.
#
# Live is a GUI program, so it is launched on the Windows side of the machine, and it takes
# about half a minute to start and load a set. The spec is therefore opt-in: it is skipped
# unless LIVE_SET_ROUND_TRIP is set, so that the rest of the suite stays quick.
#
# See TODO.md N42 and docs/als_format.md section 2.5.
RSpec.describe LiveSet, 'the round trip through Live 11' do
  # The Live 12 version of the Live 11 demo set, made by opening it in Live 12 and saving it.
  let(:live12_path) { DemoSets.converted '11', 'Suite' }

  # The Live 11 installation.
  let(:installation) { LiveInstallations.version '11' }

  # The set, converted to the Live 11 format.
  let(:converted_path) { Conversions.output_path Conversions.set_path live12_path, 'round-trip' }

  # What happened when Live was launched with the converted set.
  let(:result) do
    @result ||= LiveLauncher.launch installation.executable, converted_path,
                                    log: LiveInstallations.log_path('11'), timeout: 120
  end

  before do
    skip 'LIVE_SET_ROUND_TRIP is not set' unless ENV['LIVE_SET_ROUND_TRIP']
    skip 'the Live 12 version of the Live 11 demo set has not been made yet' if live12_path.nil?
    skip 'Live 11 is not installed' if installation.nil?
  end

  describe 'converting the set' do
    it 'writes a set' do
      Conversions.in_process live12_path

      expect(File.exist?(converted_path)).to be true
    end
  end

  describe 'opening the converted set in Live 11' do
    it 'does not put up an error' do
      expect(result.dialog).to be_nil
    end

    it 'finishes loading the set' do
      expect(result.log).to include 'End ExchangeDocument'
    end
  end
end
