require 'spec_helper'
require 'live_set/live_set_scene'
require 'support/live_sets'

# A scene of a set, and the tempo it carries.
#
# The scene is a real one, from the Live 11 Suite demo set. No scene in the corpus has a tempo of
# its own, so that case is made by changing the value of one real element.
RSpec.describe LiveScene do
  # The path of the set the scene is in.
  def path
    LiveSets.suite
  end

  # A scene of the set.
  def scene_element
    @scene_element ||= LiveSets.node(path, '//Scenes/Scene[@Id="1"]')
  end

  # The scene.
  def scene
    @scene ||= described_class.new scene_element
  end

  # The scene with a tempo of its own.
  def scene_with_tempo
    @scene_with_tempo ||= begin
      element = LiveSets.with_attribute scene_element, 'Id', '999'
      element.at_xpath('./IsTempoEnabled')['Value'] = 'true'
      described_class.new element
    end
  end

  describe '#initialize' do
    it 'reads the name' do
      expect(scene.instance_variable_get(:@name)).to eq('Verse A')
    end

    it 'reads the id' do
      expect(scene.instance_variable_get(:@id)).to eq('1')
    end

    it 'leaves the tempo nil when the scene has no tempo of its own' do
      expect(scene.instance_variable_get(:@tempo)).to be_nil
    end

    it 'reads the tempo as a float when the scene has one' do
      expect(scene_with_tempo.instance_variable_get(:@tempo)).to eq(120.0)
    end
  end
end
