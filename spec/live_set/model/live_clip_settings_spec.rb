require 'spec_helper'
require 'live_set/model/live_clip_settings'
require 'support/live_sets'

# The settings of a clip: how it is launched, and how its sample is warped.
#
# The clips are the ones of the Live 11 reference set, which is checked in.
RSpec.describe LiveClipSettings do
  # The clips of the set with the given name.
  #
  # @param name [String] the name Live wrote
  # @return [Array<Nokogiri::XML::Element>] the clips
  def clips(name)
    LiveSets.nodes(LiveSets.fascination, '//MidiClip | //AudioClip').select do |element|
      element.at('Name')&.[]('Value') == name
    end
  end

  describe 'an audio clip' do
    subject(:settings) { described_class.new clips('Pink Noise - EDMtips.com').first }

    it 'is launched as a trigger' do
      expect(settings.launch_mode).to eq 'trigger'
    end

    it 'has a warp mode of Beats' do
      expect(settings.warp_mode).to eq 'Beats'
    end

    it 'is warped' do
      expect(settings).to be_warped
    end

    it 'is not disabled' do
      expect(settings).not_to be_disabled
    end
  end

  describe 'a MIDI clip' do
    subject(:settings) { described_class.new clips('3-Kontakt 7 1').first }

    it 'is launched as a trigger' do
      expect(settings.launch_mode).to eq 'trigger'
    end

    it 'has no warp mode, because it plays no sample' do
      expect(settings.warp_mode).to be_nil
    end
  end
end
