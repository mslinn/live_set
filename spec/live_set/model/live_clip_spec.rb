require 'spec_helper'
require 'live_set/model/live_clip'
require 'support/live_sets'

# One clip in a set.
#
# The clips are the ones of the Live 11 reference set, which is checked in.
RSpec.describe LiveClip do
  # The clips of the set with the given name.
  #
  # @param name [String] the name Live wrote
  # @return [Array<Nokogiri::XML::Element>] the clips
  def clips(name)
    LiveSets.nodes(LiveSets.fascination, '//MidiClip | //AudioClip').select do |element|
      element.at('Name')&.[]('Value') == name
    end
  end

  describe 'a MIDI clip' do
    subject(:clip) { described_class.new clips('3-Kontakt 7 1').first }

    it 'holds the name of the clip, without the number Live gives the duplicates' do
      expect(clip.name).to eq 'Kontakt 7 1'
    end

    it 'holds no file, because it plays no file' do
      expect(clip.file).to be_nil
      expect(clip).to be_midi
    end

    it 'holds the color Live wrote for it' do
      expect(clip.color).to eq 1
    end

    it 'holds the place it is in' do
      expect(described_class.new(clips('3-Kontakt 7 1').first, place: 'session view').place).to eq 'session view'
    end

    it 'holds the notes of the clip' do
      expect(clip.notes.length).to eq 47
      expect(clip.notes.first).to include(pitch: 36, time: 0.0, velocity: 120)
    end
  end

  describe 'an audio clip' do
    subject(:clip) { described_class.new clips('Pink Noise - EDMtips.com').first }

    it 'holds the name of the clip' do
      expect(clip.name).to eq 'Pink Noise - EDMtips.com'
    end

    it 'holds the file it plays' do
      expect(clip.file).to eq 'Samples/Pink Noise - EDMtips.com.wav'
      expect(clip).not_to be_midi
    end

    it 'holds no notes' do
      expect(clip.notes).to be_empty
    end

    it 'is not collected, because its file is not in the project folder' do
      expect(clip).not_to be_collected
      expect(clip.marks).to eq ['⚠ not in project']
    end
  end

  describe 'the copies of a clip' do
    it 'are written out in full at every place the clip is in' do
      copies = clips '3-Kontakt 7 1'

      expect(copies.length).to eq 9
      counts = copies.map { |element| described_class.new(element).notes.length }.tally
      expect(counts).to eq(19 => 1, 47 => 8)
    end
  end
end
