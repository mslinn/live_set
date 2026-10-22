require_relative '../common/xml'

# An Ableton Live scene is a horizontal row of clip slots in the Session View where launching the scene triggers all the
# clips in that row at the same time.
class LiveScene
  include Xml

  # @param live_scene is an XML element as parsed by Nokogiri
  def initialize(live_scene)
    @live_scene = live_scene
    @id = @live_scene['Id']
    @name = xml_value(@live_scene.Name)
    @tempo = xml_value(@live_scene.Tempo)&.to_f if xml_bool?(@live_scene.IsTempoEnabled, description: "Scene #{@id} IsTempoEnabled")
  end
end
