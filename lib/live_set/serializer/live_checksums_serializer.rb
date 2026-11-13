require_relative '../model/live_checksums'

# Writes the checksums of a set.
#
# The two checksums are of different nodes: the file, and the content the file holds. The
# report says which is which.
#
# Sample usage:
# markdown = LiveChecksumsSerializer.new(checksums).to_markdown
class LiveChecksumsSerializer
  # Creates a serializer for the checksums of a set.
  #
  # @param checksums [LiveChecksums] the checksums of the set
  def initialize((checksums))
    @checksums = checksums
  end

  # Returns the section as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    [
      '### Set Checksums',
      '',
      '#### File Hash',
      '',
      'Checksum of the .als file on disk:<br>',
      "`#{@checksums.file_hash}`",
      '',
      '#### XML hash',
      '',
      'Checksum of the XML within the .als file:<br>',
      "`#{@checksums.content_hash}`"
    ]
      .join("\n")
  end
end
