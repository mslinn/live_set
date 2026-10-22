require 'spec_helper'
require 'conversions'
require 'demo_sets'
require 'live_set/live_set_class'

# The -11 conversion rewrites the version strings, removes the elements that Live 11 does not
# have, and copies everything else through unchanged.
#
# These examples use the official Ableton demo sets, which are complete, real sets in a known
# Live version. A fragment written to look like a set is not the same thing: it can be missing
# the elements the conversion depends on, and it proves nothing about what the conversion does to
# a set that Live actually wrote.
#
# Every set is converted once and the result is shared by the examples that look at it. See
# spec/conversions.rb.
#
# See docs/als_format.md sections 2.2 and 2.3.
RSpec.describe LiveSet, '#modify_als' do
  # The Live 12 demo set that Ableton ships.
  def live12_path
    DemoSets.path '12'
  end

  # The Live 11 demo set that the round trip uses.
  #
  # It is the "Suite" edition, which has the most tracks, a group track, and the most
  # Oversampling elements. See TODO.md N39.
  def suite_path
    DemoSets.edition '11', 'Suite'
  end

  # The Live 12 version of the Live 11 demo set, made by opening it in Live 12 and saving it.
  #
  # It is the same song as the Live 11 demo set, written by Live 12.
  def suite_in_live12_path
    DemoSets.converted '11', 'Suite'
  end

  # The number of tracks in a set.
  def track_count(doc)
    doc.xpath('//AudioTrack|//MidiTrack|//GroupTrack').length
  end

  # The ids of the tracks that belong to a group, sorted.
  def group_members(doc)
    members = doc.xpath('//GroupTrack').flat_map do |group|
      id = group['Id']
      doc.xpath("//AudioTrack[TrackGroupId/@Value='#{id}'] | //MidiTrack[TrackGroupId/@Value='#{id}']")
    end
    members.map { |track| track['Id'] }.sort
  end

  describe 'the Live 11 version strings' do
    # The Live 12 demo set, converted to the Live 11 format.
    def converted
      Conversions.in_process live12_path
    end

    before { skip 'the Live 12 demo set is not installed' if live12_path.nil? }

    it 'writes the Live 11 creator' do
      expect(converted.at('//Ableton')['Creator']).to eq('Ableton Live 11.3.21')
    end

    it 'writes the Live 11 minor version' do
      expect(converted.at('//Ableton')['MinorVersion']).to eq('11.0_11300')
    end
  end

  describe 'a complete Live 12 set' do
    # The Live 12 demo set, converted to the Live 11 format.
    def converted
      Conversions.in_process live12_path
    end

    # The set before it was converted.
    def original
      Conversions.read_set live12_path
    end

    before { skip 'the Live 12 demo set is not installed' if live12_path.nil? }

    it 'keeps every track' do
      expect(converted.xpath('//AudioTrack').length).to eq(original.xpath('//AudioTrack').length)
    end

    it 'keeps the group tracks' do
      expect(converted.xpath('//GroupTrack').length).to eq(original.xpath('//GroupTrack').length)
    end

    it 'keeps the clips' do
      expect(converted.xpath('//AudioClip').length).to eq(original.xpath('//AudioClip').length)
    end

    it 'keeps the devices' do
      expect(converted.xpath('//Saturator').length).to eq(original.xpath('//Saturator').length)
    end

    it 'keeps the group membership' do
      expect(group_members(converted)).to eq(group_members(original))
    end

    it 'keeps the ContentLanes element' do
      expect(converted.xpath('//ContentLanes')).not_to be_empty
    end

    it 'keeps the ExpressionLanes element' do
      expect(converted.xpath('//ExpressionLanes')).not_to be_empty
    end

    it 'keeps the Oversampling elements' do
      expect(converted.xpath('//Oversampling')).not_to be_empty
    end

    it 'removes the elements that Live 11 does not have' do
      # Live 12 writes these; Live 11 has no equivalent for them, so they are removed. See
      # docs/als_format.md section 2.2.
      expect(converted.xpath('//InstrumentMeld|//Roar|//MxPatchRef')).to be_empty
    end

    it 'renames the lanes to the name Live 11 uses' do
      expect(converted.xpath('//ContentLanes/ExpressionLane')).not_to be_empty
    end

    it 'leaves no lane named the way Live 12 names it' do
      expect(converted.xpath('//ContentLanes/MidiEditorLaneModel')).to be_empty
    end

    it 'rewrites the Oversampling values to the form Live 11 uses' do
      values = converted.xpath('//Saturator/Oversampling').map { |node| node['Value'] }.uniq.sort

      expect(values).to eq(%w[0 1])
    end
  end

  describe 'a complete Live 11 set' do
    before { skip 'the Live 11 demo set is not installed' if suite_path.nil? }

    it 'is not converted, because it is already in the Live 11 format' do
      set = Conversions.set_path suite_path, 'live11'
      live_set = described_class.new set

      expect { live_set.modify_als }.to raise_error SystemExit
    end
  end

  describe 'a round trip' do
    # The round trip is the test for the N39 question: convert a Live 12 set to Live 11, and
    # compare the result with the set that Live 11 itself wrote.
    #
    # The Live 12 file is the Live 11 demo set opened in Live 12 and saved. It is the same
    # material, so a difference between the two is a difference between the Live versions, and
    # not a difference between two songs. The Live 12 demo set Ableton ships cannot be used for
    # this, because it is a different song.
    #
    # See TODO.md N39.

    # The set as Live 11 wrote it.
    def as_live11
      Conversions.read_set suite_path
    end

    # The set as Live 12 wrote it.
    def as_live12
      Conversions.read_set suite_in_live12_path
    end

    # The Live 12 set, converted to Live 11.
    def converted
      Conversions.in_process suite_in_live12_path
    end

    before do
      skip 'the Live 11 demo set is not installed' if suite_path.nil?
      skip 'the Live 12 version of the Live 11 demo set has not been made yet' if suite_in_live12_path.nil?
    end

    it 'has the same number of tracks as the Live 11 set' do
      expect(track_count(converted)).to eq(track_count(as_live11))
    end

    it 'has the same number of clips as the Live 11 set' do
      expect(converted.xpath('//AudioClip').length).to eq(as_live11.xpath('//AudioClip').length)
    end

    it 'has the same group membership as the Live 11 set' do
      expect(group_members(converted)).to eq(group_members(as_live11))
    end

    it 'names the lanes the way Live 11 does' do
      expect(converted.xpath('//ContentLanes/ExpressionLane')).not_to be_empty
    end

    it 'leaves no lane named the way Live 12 does' do
      expect(converted.xpath('//ContentLanes/MidiEditorLaneModel')).to be_empty
    end

    it 'writes the Oversampling values the way Live 11 does' do
      values = converted.xpath('//Oversampling').map { |node| node['Value'] }.uniq.sort

      expect(values).to eq(%w[0 1])
    end

    it 'gives the same Oversampling values as the Live 11 set' do
      values = ->(doc) { doc.xpath('//Oversampling').map { |node| node['Value'] }.tally }

      expect(values.call(converted)).to eq(values.call(as_live11))
    end

    it 'keeps the lane types it was given' do
      types = ->(doc) { doc.xpath('//ContentLanes/*/Type').map { |node| node['Value'] }.tally }

      expect(types.call(converted)).to eq(types.call(as_live12))
    end

    it 'keeps the lanes themselves' do
      # Live 11 crashes on a set with no ContentLanes and no ExpressionLanes, so the conversion
      # has to translate the lanes rather than remove them. See docs/als_format.md section 2.4.
      expect(converted.xpath('//ContentLanes').length).to eq(1)
    end

    it 'keeps the ExpressionLanes themselves' do
      expect(converted.xpath('//ExpressionLanes').length).to eq(1)
    end

    it 'keeps the Oversampling elements themselves' do
      expect(converted.xpath('//Oversampling').length).to eq(as_live12.xpath('//Oversampling').length)
    end

    it 'leaves the lanes Live 11 has no equivalent for alone' do
      # Live 11 numbers its lanes differently within the same family, so there is no mapping
      # from a Live 12 lane to a Live 11 one. The conversion renames the element and leaves the
      # lane as it is. See TODO.md N42 and docs/als_format.md section 2.4.
      types = converted.xpath('//ContentLanes/*/Type').map { |node| node['Value'] }.uniq.sort

      expect(types).to eq(%w[2 3 4])
    end

    it 'writes the Live 11 version strings' do
      ableton = converted.at('//Ableton')

      expect(ableton['Creator']).to eq('Ableton Live 11.3.21')
    end

    it 'writes the Live 11 minor version' do
      ableton = converted.at('//Ableton')

      expect(ableton['MinorVersion']).to eq('11.0_11300')
    end
  end
end
