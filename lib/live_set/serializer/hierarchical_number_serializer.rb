require_relative '../model/hierarchical_number'
require_relative 'live_markup'

# Serializes a node of the outline: its number, its text, and the nodes under it.
#
# The number says how deep the node is in the outline, and the indentation of the node
# comes from the number, so that the number and the place of the node always agree.
#
# The text of the node is written by the serializer of the node — the report writes
# "Track T1  🎹 MIDI  Kontakt 7" — and it is given to this class, which writes the marker of
# the list item and, in HTML, the disclosure widget that folds the nodes under it.
#
# Sample usage:
# markdown = HierarchicalNumberSerializer.new(number, 'Track T1  🎹 MIDI  Kontakt 7').to_markdown
class HierarchicalNumberSerializer
  # The indentation of one tag of the HTML.
  HTML_INDENT = '  '.freeze

  # The indentation of one level of the outline in HTML.
  #
  # A level of the outline is three tags deep: the item itself, the disclosure widget, and
  # the list that holds the nodes under it.
  HTML_LEVEL = (HTML_INDENT * 3).freeze

  # Creates a serializer for the given node.
  #
  # @param number [HierarchicalNumber] the number of the node in the report
  # @param value [String, nil] the text of the node
  def initialize(number, value = nil)
    @number = number
    @value = value
  end

  # Returns the node as markdown.
  #
  # @param children [Array<String>] the nodes under it, as they are written
  # @return [String] the serialized markdown
  def to_markdown(children = [])
    lines = ["#{markdown_indent}- #{text}"]
    lines.concat children
    lines.reject(&:empty?).join "\n"
  end

  # Returns the node as HTML.
  #
  # @param children [Array<String>] the nodes under it, as they are written
  # @return [String] the serialized HTML
  def to_html(children = [])
    x = html_indent
    if children.empty?
      <<~END_HTML
        #{x}<li>#{text}</li>
      END_HTML
    else
      <<~END_HTML
        #{x}<li style="list-style: none;">
        #{x}#{HTML_INDENT}<details open>
        #{x}#{HTML_INDENT}#{HTML_INDENT}<summary>#{text}</summary>
        #{x}#{HTML_INDENT}#{HTML_INDENT}<ul style="list-style: none;">
        #{children.join("\n")}
        #{x}#{HTML_INDENT}#{HTML_INDENT}</ul>
        #{x}#{HTML_INDENT}</details>
        #{x}</li>
      END_HTML
    end
  end

  # The indentation of the node in HTML.
  #
  # The node is an item of a list, and the list is one tag in.
  #
  # @return [String] the indentation
  def html_indent
    HTML_INDENT + @number.indent_for(HTML_LEVEL)
  end

  # The indentation of the nodes under the node, in HTML.
  #
  # The nodes under the node are a level deeper than the node.
  #
  # @return [String] the indentation
  def children_indent
    html_indent + HTML_LEVEL
  end

  private

  # The indentation of the node in markdown.
  #
  # @return [String] the indentation
  def markdown_indent
    @number.indent_for LiveMarkup::INDENT
  end

  # The text of the node.
  #
  # @return [String] the text
  def text
    @value.nil? ? @number.to_s : @value
  end
end
