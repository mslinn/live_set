require 'pathname'

# The 'Ableton Project Info' folders around a set.
#
# Live writes a folder of that name in the folder of the project, and the folder of a set is
# usually the folder of the project. Live gets confused when it finds one in a parent folder
# of the folder of the project: it may load the project from the wrong place.
#
# The folders are a fact about the machine the report is made on, and not about the set, so
# the report says what it found, and what it means.
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
    messages << "The `#{FOLDER}` folder is not present in `#{directory.gsub('/', '/<wbr>')}`" unless present?
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
