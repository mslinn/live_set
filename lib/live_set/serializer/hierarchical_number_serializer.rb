require_relative '../model/hierarchical_number'

# Serializes a `HierarchicalNumber` model as markdown or as HTML.
#
# The number is written with the indentation that goes with it: two spaces for each level of
# the outline.
#
# Sample usage:
# markdown = HierarchicalNumberSerializer.new(number).to_markdown
class HierarchicalNumberSerializer
  # Creates a serializer for the given number.
  #
  # @param number [HierarchicalNumber] the number to be serialized
  def initialize(number)
    @number = number
  end

  # Returns the number as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    "#{@number.indent_for}- #{@number}"
  end

  # Returns the number as HTML.
  #
  # @return [String] the serialized HTML
  def to_html
    "#{@number.indent_for}#{@number}"
  end
end
