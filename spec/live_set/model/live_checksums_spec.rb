require 'spec_helper'
require 'digest'
require 'live_set/model/live_checksums'
require 'support/live_sets'

# The checksums of a set.
#
# The checksums are the ones of the Live 11 reference set, which is checked in.
RSpec.describe LiveChecksums do
  # The checksums of the set.
  #
  # @return [LiveChecksums] the checksums
  def checksums
    @checksums ||= described_class.new LiveSets.fascination
  end

  it 'is the hash of the file on disk' do
    expect(checksums.file_hash).to eq Digest::SHA256.file(LiveSets.fascination).hexdigest
  end

  it 'is the hash of the content the file holds' do
    content = Zlib::GzipReader.open LiveSets.fascination, &:read

    expect(checksums.content_hash).to eq Digest::SHA256.hexdigest(content)
  end

  it 'is a different hash from the hash of the file, because the file is compressed' do
    expect(checksums.content_hash).not_to eq checksums.file_hash
  end
end
