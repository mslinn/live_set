# A sample of a set: a file the set plays.
#
# The audio of a set is in files beside it, and the set refers to them. A sample is one of
# those files.
class LiveSample
  # The folders the content of a pack is in.
  CONTENT_FOLDERS = %w[Samples Sounds IRs Devices Racks Presets].freeze

  attr_reader :path, :relative_path

  # @param path [String] the absolute path of the file
  # @param relative_path [String, nil] the path of the file relative to the project folder
  def initialize(path, relative_path = nil)
    @path = path
    @relative_path = relative_path
  end

  # The name of the file.
  #
  # @return [String] the name
  def name
    File.basename @path
  end

  # The pack the sample is in.
  #
  # The content of a pack is under a folder of its own — Samples, Sounds, IRs, Devices — and
  # the pack is the folder above the content of the pack. A file that is not under such a
  # folder is not in a pack.
  #
  # @return [String] the name of the pack
  def pack
    parts = @path.split('/')
    index = parts.index { |part| CONTENT_FOLDERS.include? part }
    return File.basename(@path) unless index&.positive?

    parts[index - 1]
  end

  # Whether the sample is in the project folder.
  #
  # A sample is collected when its file was copied into the project's `Samples/Imported/`
  # folder. See docs/als_notes.md, "Whether a sample has been collected".
  #
  # @return [Boolean] true when the sample is in the project
  def collected?
    !@relative_path.nil? && @relative_path.start_with?('Samples/Imported/')
  end
end
