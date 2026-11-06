require 'markdown-tables'
require_relative 'live_markup'
require_relative 'live_sample_serializer'

# Writes the samples of a set that are not in the project.
#
# A sample that comes from a pack or from the Core Library of Live is not missing from the
# set: the pack holds it, and the packs of the set are reported on their own.
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

  # Returns the collection as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = ['## Missing Samples', '']
    if @missing.empty?
      lines << 'Every sample of the set is in the project.'
      return lines.join("\n")
    end

    rows = @missing.sources.sort.map do |source, names|
      [source, names.map { |name| "`#{LiveMarkup.escape name}`" }.join(', ')]
    end
    lines << MarkdownTables.make_table(%w[Source Samples], rows, align: %w[l l], is_rows: true)
    lines.join("\n")
  end
end
