require 'markdown-tables'
require_relative 'live_sample_serializer'

# Writes a collection of samples.
#
# The collection is never written by itself: each sample is written by the serializer of a
# sample, and the outputs are mapped together, under the pack each sample is in.
#
# Sample usage:
# markdown = LiveSamplesSerializer.new(samples).to_markdown
class LiveSamplesSerializer
  # Creates a serializer for a collection of samples.
  #
  # @param samples [LiveSamples] the samples of the collection
  def initialize(samples)
    @samples = samples
  end

  # Returns the collection as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = ['## Samples', '']
    if @samples.samples.empty?
      lines << 'The set plays no files.'
      return lines.join("\n")
    end

    rows = @samples.samples.group_by(&:pack).sort.map do |pack, in_pack|
      names = in_pack.uniq(&:name).sort.map do |sample|
        LiveSampleSerializer.new(sample).to_markdown
      end
      [pack, names.join(', ')]
    end
    lines << MarkdownTables.make_table(%w[Pack Samples], rows, align: %w[l l], is_rows: true)
    lines.join("\n")
  end
end
