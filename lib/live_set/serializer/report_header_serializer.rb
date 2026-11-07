require 'markdown-tables'
require_relative '../model/header_block'

# Writes the table of the facts about a set, at the top of the report.
#
# The rows are sorted alphabetically, so that the facts are in the same order whatever they
# are.
#
# Sample usage:
# header = HeaderBlock.new(path, xml)
# markdown = LiveHeaderSerializer.new(header).to_markdown
class LiveHeaderSerializer
  # Creates a serializer for the facts about a set.
  #
  # @param header [HeaderBlock] the facts about the set
  def initialize(header)
    @header = header
  end

  # Returns the table of the facts about the set as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    rows = [ # Automatically sorted by key
      ['Directory',             @header.path_cell(@header.directory)],
      ['Format',                @header.format],
      ['On computer',           "<code>#{@header.computer}</code>"],
      ['Project created',       @header.project_created],
      ['Project last modified', @header.project_last_modified],
      ['Report generated',      @header.report_generated],
      ['Revision',              @header.revision],
      ['SchemaChangeCount',     @header.schema_change_count],
      ['Set created',           @header.set_created],
      ['Set last modified',     @header.set_last_modified],
      ['Time zone',             @header.time_zone],
      ['Written by',            @header.creator]
    ].sort_by { |row| row.first.downcase }

    MarkdownTables.make_table ['', ''], rows, align: %w[l r], is_rows: true
  end
end
