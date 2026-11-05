require 'spec_helper'
require 'live_set/model/live_assets'
require 'live_set/model/live_sizes'
require 'live_set/serializer/live_sizes_serializer'
require 'support/live_sets'

# The sizes of a set.
#
# The expected values are the sizes of the Live 11 reference set, which is checked in.
RSpec.describe LiveSizesSerializer, '#to_markdown' do
  # The sizes of the set.
  #
  # @return [LiveSizes] the sizes
  def sizes
    @sizes ||= LiveSizes.new LiveSets.fascination,
                             LiveAssets.new(LiveSets.directory(LiveSets.fascination),
                                            LiveSets.document(LiveSets.fascination))
  end

  it 'writes the heading of the section' do
    expect(described_class.new(sizes).to_markdown).to start_with "## The Size of the Set\n"
  end

  it 'writes the four sizes' do
    markdown = described_class.new(sizes).to_markdown

    expect(markdown).to include('|The size|The size in bytes|What it is|How it was computed|')
    expect(markdown).to include('|The set file|')
    expect(markdown).to include('|The expected size of the project|')
    expect(markdown).to include('|The actual size of the project|')
    expect(markdown).to include('|The fully resolved size|')
  end

  it 'writes the size of the set file, in bytes and in a size a reader can see' do
    markdown = described_class.new(sizes).to_markdown

    expect(markdown).to include("|#{sizes.set_file_size} (")
  end

  it 'says what each size was computed from' do
    markdown = described_class.new(sizes).to_markdown

    expect(markdown).to include('the file on disk')
    expect(markdown).to include('the sizes Live recorded, and the size on disk where Live recorded zero')
    expect(markdown).to include('the files in the project folder')
    expect(markdown).to include('the expected size, with the assets outside the project added')
  end
end
