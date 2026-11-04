require 'markdown-tables'
require_relative '../model/missing_samples'

# Writes the section of the report that names the samples of the set that are not in the
# project, by the pack they are in.
#
# Sample usage:
# markdown = MissingSamplesSerializer.new(missing_samples).to_markdown
class MissingSamplesSerializer
  # Creates a serializer for the samples that are not in the project.
  #
  # @param missing [MissingSamples] the samples that are not in the project
  def initialize(missing)
    @missing = missing
  end

  # Returns the section as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = ['## Missing Samples', '']
    if @missing.empty?
      lines << 'Every sample of the set is in the project.'
      return lines.join("\n")
    end

    rows = @missing.packs.sort.map do |pack, names|
      [pack, names.map { |name| "`#{name}`" }.join(', ')]
    end
    lines << MarkdownTables.make_table(%w[Pack Samples], rows, align: %w[l l], is_rows: true)
    lines.join("\n")
  end
end
