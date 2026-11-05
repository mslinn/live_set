require 'spec_helper'
require 'live_set/model/live_checksums'
require 'live_set/serializer/live_checksums_serializer'
require 'support/live_sets'

# The checksums of a set.
#
# The expected values are the checksums of the Live 11 reference set, which is checked in.
RSpec.describe LiveChecksumsSerializer, '#to_markdown' do
  # The checksums of the set.
  #
  # @return [LiveChecksums] the checksums
  def checksums
    @checksums ||= LiveChecksums.new LiveSets.fascination
  end

  it 'writes the heading of the section' do
    expect(described_class.new(checksums).to_markdown).to start_with "## The Checksums of the Set\n"
  end

  it 'writes the two checksums, and says which is which' do
    markdown = described_class.new(checksums).to_markdown

    expect(markdown).to include('|The checksum|Of what|The SHA-256|')
    expect(markdown).to include('|The hash of the file|the .als as it is on disk|')
    expect(markdown).to include('|The hash of the content|the XML the .als holds when it is inflated|')
  end

  it 'writes the hash of the file' do
    expect(described_class.new(checksums).to_markdown).to include checksums.file_hash
  end

  it 'writes the hash of the content' do
    expect(described_class.new(checksums).to_markdown).to include checksums.content_hash
  end
end
