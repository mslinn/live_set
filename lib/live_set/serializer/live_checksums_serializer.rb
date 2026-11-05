require 'markdown-tables'
require_relative '../model/live_checksums'

# Writes the checksums of a set.
#
# The two checksums are of different things: the file, and the content the file holds. The
# report says which is which.
#
# Sample usage:
# markdown = LiveChecksumsSerializer.new(checksums).to_markdown
class LiveChecksumsSerializer
  # Creates a serializer for the checksums of a set.
  #
  # @param checksums [LiveChecksums] the checksums of the set
  def initialize(checksums)
    @checksums = checksums
  end

  # Returns the section as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    rows = [
      ['The hash of the file', 'the .als as it is on disk', @checksums.file_hash],
      ['The hash of the content', 'the XML the .als holds when it is inflated', @checksums.content_hash]
    ]

    lines = ['## The Checksums of the Set', '']
    lines << MarkdownTables.make_table(['The checksum', 'Of what', 'The SHA-256'], rows,
                                       align: %w[l l l], is_rows: true)
    lines.join("\n")
  end
end
