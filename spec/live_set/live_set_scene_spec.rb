require 'spec_helper'
require 'live_set/live_set_scene'

RSpec.describe LiveScene do
  # Parses a <Scene> element and builds a LiveScene from it.
  def scene_from(xml)
    described_class.new Nokogiri::Slop(xml).xpath('//Scene').first
  end

  describe '#initialize' do
    context 'when the values are element text, as in Live 12' do
      let(:scene) do
        scene_from(<<~XML)
          <Scene Id="1">
            <Name Value="Scene 1"/>
            <Tempo Value="120"/>
            <IsTempoEnabled Value="true"/>
          </Scene>
        XML
      end

      it 'reads the name' do
        expect(scene.instance_variable_get(:@name)).to eq('Scene 1')
      end

      it 'reads the tempo as a float' do
        expect(scene.instance_variable_get(:@tempo)).to eq(120.0)
      end
    end

    context 'when the values are Value attributes, as in Live 8' do
      let(:scene) do
        scene_from(<<~XML)
          <Scene Id="2">
            <Name Value="Scene 2"/>
            <Tempo Value="140"/>
            <IsTempoEnabled Value="true"/>
          </Scene>
        XML
      end

      it 'reads the name' do
        expect(scene.instance_variable_get(:@name)).to eq('Scene 2')
      end

      it 'reads the tempo as a float' do
        expect(scene.instance_variable_get(:@tempo)).to eq(140.0)
      end
    end

    context 'when the scene has no tempo of its own' do
      let(:scene) do
        scene_from(<<~XML)
          <Scene Id="3">
            <Name Value="Scene 3"/>
            <Tempo Value="120"/>
            <IsTempoEnabled Value="false"/>
          </Scene>
        XML
      end

      it 'leaves the tempo nil' do
        expect(scene.instance_variable_get(:@tempo)).to be_nil
      end
    end
  end
end
