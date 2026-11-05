require_relative 'live_markup'

# Serializes a `LiveSample` model as markdown.
#
# A sample is a file the set plays. The name of it is written in code type, and a sample
# that is not in the project is marked as one that is not.
#
# Sample usage:
# markdown = LiveSampleSerializer.new(sample).to_markdown
class LiveSampleSerializer
  # Creates a serializer for the given sample.
  #
  # @param sample [LiveSample] the sample to be serialized
  def initialize(sample)
    @sample = sample
  end

  # Returns the sample as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    name = "`#{LiveMarkup.escape @sample.name}`"
    return name if @sample.collected?

    "#{name} (not in the project)"
  end
end
