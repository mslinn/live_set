require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require 'live_set/model/live_project_info'

# The 'Ableton Project Info' folders around a set.
RSpec.describe LiveProjectInfo do
  # A directory with a set in it, and the folders around it.
  around do |example|
    Dir.mktmpdir 'live_set_spec_' do |directory|
      @directory = directory
      example.run
    end
  end

  # The directory the set is in.
  #
  # @return [String] the path of the directory
  attr_reader :directory

  it 'knows the folder it looks for' do
    expect(described_class.new(directory).path).to eq File.join(directory, 'Ableton Project Info')
  end

  it 'says that the folder is not present when it is not there' do
    project_info = described_class.new directory

    expect(project_info).not_to be_present
    # expect(project_info.warnings).to include(
    #   "The 'Ableton Project Info' folder is not present in #{directory}"
    # )
  end

  it 'says nothing when the folder is there' do
    FileUtils.mkdir_p File.join(directory, 'Ableton Project Info')
    project_info = described_class.new directory

    expect(project_info).to be_present
    expect(project_info.a_directory?).to be true
    expect(project_info.warnings).to be_empty
  end

  it 'finds a folder in a parent directory' do
    parent = File.join directory, 'project'
    FileUtils.mkdir_p File.join(parent, 'Ableton Project Info')
    project_info = described_class.new File.join(parent, 'sets')

    expect(project_info.in_parents).to eq [parent]
    expect(project_info.warnings).to include(
      "A 'Ableton Project Info' folder is present in the parent directory #{parent}"
    )
  end

  it 'says that a folder that is a file is not a directory' do
    FileUtils.touch File.join(directory, 'Ableton Project Info')
    project_info = described_class.new directory

    expect(project_info).to be_present
    expect(project_info.a_directory?).to be false
    expect(project_info.warnings).to include(
      "The 'Ableton Project Info' folder in #{directory} is not a directory"
    )
  end
end
