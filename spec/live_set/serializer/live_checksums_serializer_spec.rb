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
    expect(described_class.new(checksums).to_markdown).to start_with "### Set Checksums\n"
  end

  it 'writes the two checksums in their own subsections, and says which is which' do
    markdown = described_class.new(checksums).to_markdown

    expect(markdown).to include('#### File Hash')
    expect(markdown).to include('#### XML hash')
    expect(markdown).to include('Checksum of the .als file on disk:<br>')
    expect(markdown).to include('Checksum of the XML within the .als file:<br>')
  end

  it 'writes the hash of the file' do
    expect(described_class.new(checksums).to_markdown).to include checksums.file_hash
  end

  it 'writes the hash of the content' do
    expect(described_class.new(checksums).to_markdown).to include checksums.content_hash
  end
end
