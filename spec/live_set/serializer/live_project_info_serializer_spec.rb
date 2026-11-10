require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require 'live_set/model/live_project_info'
require 'live_set/serializer/live_project_info_serializer'

# What the report found of the 'Ableton Project Info' folders around the set.
RSpec.describe LiveProjectInfoSerializer, '#to_markdown' do
  # A directory with a set in it.
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

  it 'writes the heading of the section' do
    markdown = described_class.new(LiveProjectInfo.new(directory)).to_markdown

    expect(markdown).to start_with "### The Ableton Project Info Folder\n"
  end

  it 'writes the warning about a folder that is not there' do
    markdown = described_class.new(LiveProjectInfo.new(directory)).to_markdown

    expect(markdown).to include(
      "The `Ableton Project Info` folder is not present in <code>#{directory.gsub('/', '/<wbr>')}</code>"
    )
  end

  it 'writes the warning about a folder in a parent directory' do
    parent = File.join directory, 'project'
    FileUtils.mkdir_p File.join(parent, 'Ableton Project Info')
    project_info = LiveProjectInfo.new File.join(parent, 'sets')

    expect(described_class.new(project_info).to_markdown).to include(
      "- A 'Ableton Project Info' folder is present in the parent directory #{parent}"
    )
  end

  it 'says that Live can be confused by a folder in a parent directory' do
    markdown = described_class.new(LiveProjectInfo.new(directory)).to_markdown

    expect(markdown).to include(
      'Live gets confused by a <code>Ableton Project Info</code> folder in a parent folder'
    )
  end
end
