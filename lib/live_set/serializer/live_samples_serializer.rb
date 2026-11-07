require 'markdown-tables'
require_relative 'live_sample_serializer'

# Writes the samples of a set that are not missing.
#
# The collection is never written by itself: each sample is written by the serializer of a
# sample, and the outputs are mapped together, under the source each sample comes from.
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
    lines = ['## Located Samples', '']
    located = @samples.located
    if located.empty?
      lines << 'The set plays no files.'
      return lines.join("\n")
    end

    lines << 'The samples of the set that are in the project, and the ones that come from a ' \
             'pack or from the Live core library.'
    lines << ''

    rows = located.group_by(&:source).sort.map do |source, in_source|
      names = in_source.uniq(&:name).sort_by(&:name).map do |sample|
        LiveSampleSerializer.new(sample).to_markdown
      end
      [source, names.join(', ')]
    end
    lines << MarkdownTables.make_table(%w[Source Samples], rows, align: %w[l l], is_rows: true)
    lines.join("\n")
  end
end
