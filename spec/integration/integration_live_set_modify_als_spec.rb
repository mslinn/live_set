require 'spec_helper'
require 'conversions'
require 'demo_sets'

# What the live_set command does when it is asked to convert a set to the Live 11 format.
#
# These examples run the command as a subprocess, because the command is what a user runs. The
# code in this repository is used rather than an installed gem, so the examples test the code
# that is in the repository.
#
# The unit specs in spec/live_set/live_set_modify_als_spec.rb call the method directly. These
# ones check the whole path: the executable, the options, the file that is written, and the
# file that is not.
#
# The command is run three times on the same set, and the result is shared by every example
# that looks at it. See spec/conversions.rb.
#
# See docs/live_11_12_diff.md, "The elements the two versions name differently", and
# "The values the two versions write differently".
RSpec.describe LiveSet, '#modify_als' do
  # The Live 12 demo set that Ableton ships.
  let(:live12_path) { DemoSets.path '12' }

  # What happened when the command was run three times on the set.
  let(:scenario) { Conversions.command_scenario live12_path }

  # The set the command was given.
  let(:original) { Conversions.read_set live12_path }

  before { skip 'the Live 12 demo set is not installed' if live12_path.nil? }

  describe 'the first run' do
    it 'succeeds' do
      expect(scenario.first_run).to be_success
    end

    it 'writes the converted set' do
      expect(File.exist?(scenario.first_run.path)).to be true
    end

    it 'writes the set next to the set it was given' do
      expect(File.dirname(scenario.first_run.path)).to eq File.dirname(scenario.source)
    end

    it 'says that it wrote the set' do
      expect(scenario.first_run.output).to include 'Conversion complete'
    end

    it 'writes a set that says it was made by Live 11' do
      expect(scenario.converted.at('//Ableton')['Creator']).to eq('Ableton Live 11.3.21')
    end

    it 'writes a set that says it is the Live 11 format' do
      expect(scenario.converted.at('//Ableton')['MinorVersion']).to eq('11.0_11300')
    end

    it 'writes a set that has the same tracks as the set it was given' do
      expect(scenario.converted.xpath('//AudioTrack').length).to eq(original.xpath('//AudioTrack').length)
    end

    it 'writes a set that has the same clips as the set it was given' do
      expect(scenario.converted.xpath('//AudioClip').length).to eq(original.xpath('//AudioClip').length)
    end

    it 'writes a set that has the same group tracks as the set it was given' do
      expect(scenario.converted.xpath('//GroupTrack').length).to eq(original.xpath('//GroupTrack').length)
    end

    it 'writes a set with the lanes named the way Live 11 names them' do
      expect(scenario.converted.xpath('//ContentLanes/ExpressionLane')).not_to be_empty
    end

    it 'writes a set with no lane named the way Live 12 names them' do
      expect(scenario.converted.xpath('//ContentLanes/MidiEditorLaneModel')).to be_empty
    end

    it 'writes a set that keeps the content lanes, because Live 11 crashes without them' do
      expect(scenario.converted.xpath('//ContentLanes').length).to eq(1)
    end

    it 'writes a set that keeps the expression lanes, because Live 11 crashes without them' do
      expect(scenario.converted.xpath('//ExpressionLanes').length).to eq(1)
    end

    it 'writes a set with the Oversampling values spelled the way Live 11 spells them' do
      values = scenario.converted.xpath('//Saturator/Oversampling').map { |node| node['Value'] }.uniq.sort

      expect(values).to eq(%w[0 1])
    end

    it 'writes a set without the elements that Live 11 does not have' do
      expect(scenario.converted.xpath('//InstrumentMeld|//Roar|//MxPatchRef')).to be_empty
    end

    it 'leaves the set it was given alone' do
      expect(scenario.source_after).to eq(scenario.source_before)
    end
  end

  describe 'the second run' do
    # The set that is already there must not be destroyed by a run that was not asked to
    # overwrite it. The gzip writer truncates the file it opens, so without the check a
    # conversion would silently destroy the previous result.
    it 'fails' do
      expect(scenario.second_run).not_to be_success
    end

    it 'says that the set already exists' do
      expect(scenario.second_run.output).to include 'already exists'
    end

    it 'says how to overwrite it' do
      expect(scenario.second_run.output).to include '-f'
    end

    it 'leaves the set that is already there alone' do
      expect(scenario.after_second).to eq(scenario.after_third)
    end
  end

  describe 'the third run, which is given the force option' do
    it 'succeeds' do
      expect(scenario.third_run).to be_success
    end

    it 'says that it is overwriting the set' do
      expect(scenario.third_run.output).to include 'Overwriting existing'
    end

    it 'writes the same set that the first run wrote' do
      expect(scenario.after_third).to eq(scenario.after_second)
    end

    it 'leaves the set it was given alone' do
      expect(scenario.source_after).to eq(scenario.source_before)
    end
  end
end
