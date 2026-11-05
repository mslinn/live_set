require 'digest'
require 'zlib'

# The checksums of a set: the hash of the file, and the hash of the content.
#
# A set is a gzip file, and two files with the same content need not have the same bytes: a
# set that was recompressed has the same content and a different file. The hash of the content
# says the material did not change; the hash of the file says the file did not change.
#
# See docs/serializer_plan.md, "The checksum".
class LiveChecksums
  attr_reader :content_hash, :file_hash

  # @param set_name [String] the path of the set
  def initialize(set_name)
    @file_hash = Digest::SHA256.file(set_name).hexdigest
    @content_hash = Digest::SHA256.hexdigest content_of(set_name)
  end

  private

  # The XML the set holds when it is inflated.
  #
  # @param set_name [String] the path of the set
  # @return [String] the content of the set
  def content_of(set_name)
    Zlib::GzipReader.open(set_name, &:read)
  rescue Zlib::GzipFile::Error
    File.binread set_name
  end
end
