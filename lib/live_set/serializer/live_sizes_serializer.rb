require 'markdown-tables'
require 'twitter_cldr'
require_relative '../model/live_sizes'

# Writes the sizes of a set.
#
# The report is evidence: it has to say how big a set is. Each size says what it is, how it
# was computed, and what it needs, so that a reader can tell what was measured and what was
# not.
#
# Sample usage:
# markdown = LiveSizesSerializer.new(sizes).to_markdown
class LiveSizesSerializer
  # The sizes, and what is said about each of them.
  #
  # The size that could not be computed says so, instead of the size that was not computed.
  SIZES = [
    { name: 'The set file',              key: :set_file_size,
      what: 'the size of the .als',
      how:  'the file on disk' },
    { name: 'Expected Project Size', key: :expected_project_size,
      what: 'what the project should be, according to the .als: the set file, and every ' \
            'sample the set refers to that is in the project, counted once',
      how:  'the sizes Live recorded, and the size on disk where Live recorded zero' },
    { name: 'Actual Project Size', key: :actual_project_size,
      what: 'what the project is, on disk',
      how:  'the files in the project folder' },
    { name: 'Fully Resolved Size', key: :resolved_size,
      what: 'everynode the set draws on: the project, and the assets outside it',
      how:  'the expected size, with the assets outside the project added' }
  ].freeze

  # Creates a serializer for the sizes of a set.
  #
  # @param sizes [LiveSizes] the sizes of the set
  def initialize(sizes)
    @sizes = sizes
  end

  # Returns the section as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    rows = SIZES.map do |size|
      [size[:name], value_of(size[:key]), size[:what], size[:how]]
    end

    lines = ['### Set Sizes', '']
    lines << MarkdownTables.make_table(['', 'Bytes', 'Describes', 'How Computed'],
                                       rows, align: %w[l r l l], is_rows: true)
    lines.join("\n")
  end

  private

  # The size, as the report writes it.
  #
  # @param key [Symbol] the size
  # @return [String] the size
  def value_of(key)
    value = @sizes.public_send key
    return 'not computed' if value.nil?

    "#{value.localize} bytes"
  end
end
