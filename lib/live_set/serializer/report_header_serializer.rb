require 'markdown-tables'
require_relative '../model/header_block'

# Writes the table of the facts about a set, at the top of the report.
#
# The rows are sorted alphabetically, so that the facts are in the same order whatever they
# are.
#
# The report of a lone set holds the facts of the set and the facts that are the same for
# every set of a project. The report of a set of a project holds the facts of the set alone:
# the facts that are the same for every set are written once, above the reports of the sets.
#
# Sample usage:
# header = HeaderBlock.new(path, xml)
# markdown = LiveHeaderSerializer.new(header).to_markdown
class LiveHeaderSerializer
  # Creates a serializer for the facts about a set.
  #
  # @param header [HeaderBlock] the facts about the set
  # @param context [ReportContext, nil] what the report is about, and what it may say
  def initialize(header, context = nil)
    @header = header
    @context = context
  end

  # Returns the table of the facts about the set as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    rows = (set_rows + common_rows).sort_by { |row| row.first.downcase }

    MarkdownTables.make_table ['', ''], rows, align: %w[l r], is_rows: true
  end

  private

  # The facts about the set.
  #
  # @return [Array<Array(String, String)>] the rows
  def set_rows
    [
      ['Format',              @header.format],
      ['Revision',            @header.revision],
      ['SchemaChangeCount',   @header.schema_change_count],
      ['Set created',         @header.set_created],
      ['Set last modified',   @header.set_last_modified],
      ['Written by',          @header.creator]
    ]
  end

  # The facts that are the same for every set of a project.
  #
  # The report of a set of a project does not hold them: they are written once, above the
  # reports of the sets.
  #
  # @return [Array<Array(String, String)>] the rows
  def common_rows
    return [] if @context&.project?

    [
      ['Context',          @context&.sentence],
      ['Directory',        @header.path_cell(@header.directory)],
      ['On computer',      "<code>#{@header.computer}</code>"],
      ['Report generated', @header.report_generated],
      ['Time zone',        @header.time_zone]
    ].reject { |row| row.last.nil? }
  end
end
