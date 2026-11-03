# TODO: This is a placeholder to start off the changes described as TODO comments in lib/live_set/live_palette.rb
# TODO Write unit tests
#
# Writes the "Push 3 Standalone" section of the markdown report for a `LiveSet` model.
#
# Sample usage:
# markdown = LiveHeaderSerializer.new(live_set).to_markdown
class LiveHeaderSerializer
  # Create a serializer for the HTML table at the top of the report for the given set.
  #
  # @param live_set [LiveSet] the live_set to report on
  def initialize(live_set)
    @live_set = live_set
  end

  # Return the HTML table at the top of the report as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    # TODO: write me
  end
end
