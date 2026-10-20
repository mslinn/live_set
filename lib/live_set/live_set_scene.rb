# An Ableton Live scene is a horizontal row of clip slots in the Session View where launching the scene triggers all the
# clips in that row at the same time.
class LiveScene
  # @param live_scene is an XML element as parsed by Nokogiri
  def initialize(live_scene)
    @live_scene = live_scene
    @id = @live_scene['Id']
    @name = @live_scene.Name['Value']
    @tempo = @live_scene.Tempo['Value'] if @live_scene.IsTempoEnabled['Value'].to_bool
  end
end
