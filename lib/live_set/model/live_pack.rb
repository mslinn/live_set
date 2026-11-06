# A pack the set refers to.
#
# A pack is a folder of content that Ableton sells: the samples, the sounds, the devices and
# the presets of it. A set that plays a file of a pack refers to the pack, and the pack has
# to be installed for the file to be found.
class LivePack
  attr_reader :name, :path

  # @param name [String] the name of the pack
  # @param path [String] the path of the folder of the pack
  def initialize(name, path)
    @name = name
    @path = path
  end

  # Whether the pack is on this machine.
  #
  # @return [Boolean] true when the folder of the pack is there
  def located?
    !@path.nil? && File.directory?(@path)
  end
end
