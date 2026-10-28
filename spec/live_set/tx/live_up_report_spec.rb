require 'spec_helper'
require 'tmpdir'
require 'live_set/als_file'
require 'live_set/tx/live_11_and_12'
require 'demo_sets'

# A report of the elements where the Live 11 set and the set Live 12 wrote differ.
#
# The comparison spec says what differs; this says what the elements look like in each version,
# so that the rules of the conversion can be written from the evidence rather than from a guess.
# The report is written to the temporary directory, and the findings belong in
# spec/live_set/tx/live_up_ground_truth_spec.rb.
RSpec.describe 'the elements the Live 11 set and the set Live 12 wrote differ in' do
  let(:live11_path) { DemoSets.require_edition!('11', 'Suite') }
  let(:live12_path) { DemoSets.require_converted!('11', 'Suite') }

  let(:live11) { AlsFile.read(live11_path) }
  let(:live12) { AlsFile.read(live12_path) }

  # The XML of an element of a set.
  #
  # @param document [Nokogiri::XML::Document] the set
  # @param xpath [String] the path of the element
  # @return [Array<String>] the XML of the elements the path finds
  def xml(document, xpath)
    options = Nokogiri::XML::Node::SaveOptions::AS_XML
    document.xpath(xpath).map { |element| element.to_xml(save_with: options) }
  end

  # The names of the children of an element of a set.
  #
  # @param document [Nokogiri::XML::Document] the set
  # @param xpath [String] the path of the element
  # @return [Array<String>] the names of the children
  def children(document, xpath)
    document.xpath(xpath).map { |element| element.element_children.map(&:name) }
  end

  it 'writes a report' do
    report = []

    [
      '//LiveSet/ScaleInformation', '//LiveSet/InKey', '//LiveSet/ExpressionLanes',
      '//LiveSet/ContentLanes', '//MainTrack/Name', '//PreHearTrack/Name',
      '//LiveSet/Scenes/Scene/FollowAction', '//AudioClip/SampleRef'
    ].each do |xpath|
      report << "== #{xpath}"
      report << "-- live 11"
      report.concat xml(live11, xpath).uniq
      report << "-- live 12"
      report.concat xml(live12, xpath).uniq
    end

    report << '== the MIDI tracks'
    report << "-- live 11 children"
    report.concat children(live11, '//MidiTrack').uniq.map(&:inspect)
    report << "-- live 12 children"
    report.concat children(live12, '//MidiTrack').uniq.map(&:inspect)
    report << '-- live 12 IsTuned'
    report.concat xml(live12, '//MidiTrack/IsTuned').uniq

    report << '== the MIDI tracks, one by one'
    %w[11 12].each do |version|
      document = version == '11' ? live11 : live12
      report << "-- live #{version}"
      document.xpath('//MidiTrack').each_with_index do |track, index|
        report << [index,
                   "LomId=#{track.at_xpath('./LomId')&.[]('Value')}",
                   "name=#{track.at_xpath('./Name/EffectiveName')&.[]('Value')}",
                   "IsTuned=#{track.at_xpath('./IsTuned')&.[]('Value')}",
                   "clips=#{track.xpath('.//MidiClip').length}",
                   "clips_in_key=#{track.xpath('.//MidiClip[IsInKey]').length}",
                   "clips_with_scale=#{track.xpath('.//MidiClip[ScaleInformation]').length}"].inspect
      end
    end

    report << '== the scenes, one by one'
    %w[11 12].each do |version|
      document = version == '11' ? live11 : live12
      report << "-- live #{version}"
      document.xpath('//LiveSet/Scenes/Scene').each_with_index do |scene, index|
        action = scene.at_xpath('./FollowAction')
        report << [index,
                   "name=#{scene.at_xpath('./Name/EffectiveName')&.[]('Value')}",
                   "follow_time=#{action&.at_xpath('./FollowTime')&.[]('Value')}",
                   "is_linked=#{action&.at_xpath('./IsLinked')&.[]('Value')}",
                   "enabled=#{action&.at_xpath('./FollowActionEnabled')&.[]('Value')}"].inspect
      end
    end

    report << '== the samples of the audio clips'
    report << '-- live 12'
    report.concat xml(live12, '//AudioClip/SampleRef/SamplesToAutoWarp').uniq

    puts report.join("\n")
  end
end
