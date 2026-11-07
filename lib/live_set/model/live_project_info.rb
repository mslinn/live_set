require 'pathname'

# Detects `Ableton Project Info` folders around a set.
#
# The Ableton Live file system icon is intended to make you think that a Live set is just one file. In actuality, the
# icon is a attached to a directory. Inside this directory is the `.als` file (Ableton Live Set) and project assets.
#
# Live writes a folder called `Ableton Project Info` next to the `.als` file in the directory.
#
# This is all very confusing for users, and apparently for Live as well.  Live gets confused when it finds a directory
# called `Ableton Project Info` above or below a project folder. Live does not provide users with any notice that this
# might be a problem. `als_report` gives a clear indication if extra`Ableton Project Info` directories are a problem.
#
# The `Ableton Project Info` folders are a fact about the machine the report is made on, and not about the set itself.
#
# See docs/als_notes.md, "The 'Ableton Project Info' folder".
class LiveProjectInfo
  # The name of the folder.
  FOLDER = 'Ableton Project Info'.freeze

  # @param directory [String] the directory the set is in
  def initialize(directory)
    @directory = directory
  end

  # The directory the set is in.
  #
  # @return [String] the path of the directory
  attr_reader :directory

  # The path of the folder in the directory of the set.
  #
  # @return [String] the path of the folder
  def path
    File.join directory, FOLDER
  end

  # Whether the folder is in the directory of the set.
  #
  # @return [Boolean] true when the folder is there
  def present?
    File.exist? path
  end

  # Whether the folder in the directory of the set is a directory.
  #
  # @return [Boolean] true when it is a directory
  def a_directory?
    Dir.exist? path
  end

  # The parent directories that have a folder of that name.
  #
  # @return [Array<String>] the paths of the directories
  def in_parents
    @in_parents ||= parent_directories.select { |parent| File.exist? File.join(parent, FOLDER) }
  end

  # What is wrong with the folders around the set.
  #
  # @return [Array<String>] the warnings
  def warnings
    # TODO: return [] # if running als_report (so these warnings are not logged when generating a report)

    messages = []
    messages << "The `#{FOLDER}` folder is not present in <code>#{directory.gsub('/', '/<wbr>')}</code>" unless present?
    messages << "The `#{FOLDER}` folder in `#{directory}` is not a directory" if present? && !a_directory?
    in_parents.each { |parent| messages << "A '#{FOLDER}' folder is present in the parent directory #{parent}" }
    messages
  end

  private

  # The parent directories of the directory of the set, up to the root.
  #
  # @return [Array<String>] the paths of the directories
  def parent_directories
    directory = Pathname.new(@directory).parent
    directories = []
    until directory.nil? || directory.root?
      directories << directory.to_path
      directory = directory.parent
    end
    directories
  end
end
