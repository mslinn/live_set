require 'markdown-tables'
require_relative 'live_markup'
require_relative 'live_sample_serializer'

# Writes the samples of a set that are not in the project.
#
# A sample that comes from a pack or from the Live core library is not missing from the
# set: the pack holds it, and the packs of the set are reported on their own.
#
# Sample usage:
# markdown = MissingSamplesSerializer.new(missing_samples).to_markdown
class MissingSamplesSerializer
  # Creates a serializer for the samples that are not in the project.
  #
  # @param missing [MissingSamples] the samples that are not in the project
  # @param machine [Boolean] whether the facts of the machine are written
  def initialize(missing, machine: false)
    @missing = missing
    @machine = machine
  end

  # Returns the collection as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = ['## Missing Samples', '']
    if @missing.empty?
      lines << <<~END_MSG
        Every sample referenced in this set is either present in the project,
        or was installed from a pack,
        or came from the Live Core Library.
      END_MSG
      return lines.join("\n")
    end

    lines << 'The samples of the set that are not in the project, and that do not come from a ' \
             'pack or from the Live core library. A set with such a sample is not ' \
             'self-contained: the file has to be found again.'
    lines << ''
    lines << machine_line if @machine
    rows = @missing.sources.sort.map do |source, names|
      [source, names.map { |name| "`#{LiveMarkup.escape name}`" }.join(', ')]
    end
    lines << MarkdownTables.make_table(%w[Source Samples], rows, align: %w[l l], is_rows: true)
    lines.join("\n")
  end

  private

  # The line that says how many of the samples are on this machine.
  #
  # @return [String] the line
  def machine_line
    here = @missing.count(&:there?)

    "#{here} of them are on this machine.\n"
  end
end
