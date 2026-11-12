require 'markdown-tables'
require_relative '../model/header_block'

# Writes the facts that are the same for every set of a project.
#
# The facts are written once, above the reports of the sets, so that a reader sees what is
# common before what is specific to a set.
#
# Sample usage:
# markdown = LiveCommonSerializer.new(header, context).to_markdown
class LiveCommonSerializer
  # Creates a serializer for the facts that are common to the sets of a project.
  #
  # @param header [HeaderBlock] the facts about the sets
  # @param context [ReportContext] what the report is about, and what it may say
  def initialize(header, context)
    @header = header
    @context = context
  end

  # Returns the table of the common facts as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    rows = [
      ['Context',              @context.sentence],
      ['Directory',            @header.path_cell(@header.directory)],
      ['On computer',          "<code>#{@header.computer}</code>"],
      ['Project created',      @header.project_created],
      ['Project last modified', @header.project_last_modified],
      ['Report generated',     @header.report_generated],
      ['Time zone',            @header.time_zone]
    ].reject { |row| row.last.nil? }

    MarkdownTables.make_table ['', ''], rows, align: %w[l r], is_rows: true
  end
end
