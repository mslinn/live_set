require_relative 'live_markup'

# Serializes a `LiveSample` model as markdown.
#
# A sample is a file the set plays. The name of it is written in code type.
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
    "`#{LiveMarkup.escape @sample.name}`"
  end
end
