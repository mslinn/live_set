require_relative 'live_assets'

# The sizes of a set.
#
# Four sizes, and each of them says what it was computed from:
#
# | The size | What it is |
# | --- | --- |
# | the set file | the size of the `.als` |
# | the expected size of the project | what the project should be, according to the `.als`: the set file, and every sample the set refers to that is in the project, counted once |
# | the actual size of the project | what the project is, on disk: the files in the project folder |
# | the fully resolved size | everything the set draws on: the project, and the assets outside it |
#
# A sample that is not on disk has no size on disk, and the report says so rather than
# guessing at one. A project folder that is not there has no actual size, and the report says
# that instead of the expected one.
#
# See docs/serializer_plan.md, "The sizes", and docs/glossary.md, "Fully resolved size".
class LiveSizes
  attr_reader :actual_project_size, :expected_project_size, :resolved_size, :set_file_size

  # @param set_name [String] the path of the set
  # @param assets [LiveAssets] the assets of the set
  def initialize(set_name, assets)
    @set_name = set_name
    @assets = assets
    @set_file_size = File.size set_name
    @expected_project_size = @set_file_size + assets.in_project.sum(&:expected_size)
    @actual_project_size = size_of_project
    @resolved_size = @expected_project_size + assets.outside_project.sum { |asset| asset.size_on_disk.to_i }
  end

  # The directory the set is in, which is the project folder.
  #
  # @return [String] the path of the directory
  def project_directory
    File.dirname File.expand_path(@set_name)
  end

  private

  # The size of the files in the project folder.
  #
  # @return [Integer, nil] the size in bytes, or nil when the project folder is not there
  def size_of_project
    directory = project_directory
    return nil unless File.directory? directory

    Dir.glob(File.join(directory, '**', '*'), File::FNM_DOTMATCH).sum do |path|
      File.file?(path) ? File.size(path) : 0
    end
  end
end
