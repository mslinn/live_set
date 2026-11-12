require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require 'live_set/model/missing_samples'
require 'live_set/model/live_sample'
require 'live_set/serializer/missing_samples_serializer'

# The samples of a set that are not in the project.
RSpec.describe MissingSamplesSerializer, '#to_markdown' do
  # A sample that is not in the project, and not from a pack or from a library.
  #
  # @param path [String] the path of the file
  # @return [LiveSample] the sample
  def sample(path)
    LiveSample.new path
  end

  it 'writes the heading of the section' do
    expect(described_class.new(MissingSamples.new([])).to_markdown).to start_with "## Missing Samples\n"
  end

  it 'says that every sample of the set is accounted for when there are none' do
    markdown = described_class.new(MissingSamples.new([])).to_markdown

    expect(markdown).to include('Every sample referenced in this set is either present in the project')
  end

  it 'names the samples that are not in the project' do
    markdown = described_class.new(MissingSamples.new([sample('/nowhere/pink noise.wav')])).to_markdown

    expect(markdown).to include('`pink noise.wav`')
  end

  it 'says nothing of the machine when it is not asked for' do
    markdown = described_class.new(MissingSamples.new([sample('/nowhere/pink noise.wav')])).to_markdown

    expect(markdown).not_to include('on this machine')
  end

  it 'says how many of the samples are on this machine' do
    Dir.mktmpdir 'live_set_spec_' do |directory|
      here = File.join directory, 'pink noise.wav'
      FileUtils.touch here
      samples = MissingSamples.new([sample(here), sample('/nowhere/tambourine.aif')])

      markdown = described_class.new(samples, machine: true).to_markdown

      expect(markdown).to include('1 of them are on this machine.')
    end
  end
end
