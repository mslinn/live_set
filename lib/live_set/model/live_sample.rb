require_relative 'live_origin'

# A sample of a set: a file the set plays.
#
# The audio of a set is in files beside it, and the set refers to them. A sample is one of
# those files.
#
# Two paths name a sample. The path Live wrote is where the file was when the set was saved,
# and it says which pack the file came from. The relative path is where the file is in the
# project.
#
# See docs/als_notes.md, "Where a file comes from".
class LiveSample
  attr_reader :path, :project_directory, :relative_path

  # @param path [String, nil] the path Live wrote for the file
  # @param relative_path [String, nil] the path of the file relative to the project folder
  # @param project_directory [String, nil] the directory of the project
  def initialize(path, relative_path = nil, project_directory = nil)
    @path = path
    @relative_path = relative_path
    @project_directory = project_directory
  end

  # The name of the file.
  #
  # @return [String] the name
  def name
    File.basename(@path || @relative_path).to_s
  end

  # The pack the file came from.
  #
  # @return [String, nil] the name of the pack, or nil when the file is not in one
  def pack
    LiveOrigin.pack @path, @project_directory
  end

  # The path of the pack the file came from.
  #
  # @return [String, nil] the path of the pack, or nil when the file is not in one
  def pack_path
    LiveOrigin.pack_path @path
  end

  # The library the file came from.
  #
  # @return [String, nil] the name of the library, or nil when the file is not in one
  def library
    LiveOrigin.library @path
  end

  # Whether the file came from a pack.
  #
  # @return [Boolean] true when the file is in a pack
  def from_pack?
    !pack.nil?
  end

  # Whether the file came from the Core Library of Live.
  #
  # @return [Boolean] true when the file is in the Core Library
  def from_core_library?
    library == LiveOrigin::CORE_LIBRARY
  end

  # Where the file comes from, as the report groups the samples.
  #
  # @return [String] the pack, the library, or the project
  def source
    pack || library || 'the project'
  end

  # Whether the sample is collected into the project.
  #
  # A sample is collected when its file was copied into the project's `Samples/Imported/`
  # folder. See docs/als_notes.md, "Whether a sample has been collected".
  #
  # @return [Boolean] true when the sample is in the project
  def collected?
    !@relative_path.nil? && @relative_path.start_with?('Samples/Imported/')
  end
end
