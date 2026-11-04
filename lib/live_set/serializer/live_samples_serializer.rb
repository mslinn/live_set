require 'markdown-tables'
require_relative '../model/live_samples'

# Writes the section of the report that names the samples of the set, by the pack they are
# in, and says whether each of them is in the project.
#
# Sample usage:
# markdown = LiveSamplesSerializer.new(samples).to_markdown
class LiveSamplesSerializer
  # Creates a serializer for the samples of the set.
  #
  # @param samples [LiveSamples] the samples of the set
  def initialize(samples)
    @samples = samples
  end

  # Returns the section as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = ['## Samples', '']
    if @samples.samples.empty?
      lines << 'The set plays no files.'
      return lines.join("\n")
    end

    rows = @samples.samples.group_by(&:pack).sort.map do |pack, in_pack|
      names = in_pack.map(&:name).uniq.sort.map do |name|
        sample = in_pack.find { |candidate| candidate.name == name }
        sample.collected? ? "`#{name}`" : "`#{name}` (not in the project)"
      end
      [pack, names.join(', ')]
    end
    lines << MarkdownTables.make_table(%w[Pack Samples], rows, align: %w[l l], is_rows: true)
    lines.join("\n")
  end
end
