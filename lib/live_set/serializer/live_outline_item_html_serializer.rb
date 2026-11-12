require_relative '../model/live_outline_item'

# Serializes a `LiveOutlineItem` model as HTML.
#
# The items of the outline are written as a list. An item that has things under it is a
# disclosure widget, and the reader can fold it; an item that has none is a plain item.
#
# Sample usage:
# html = LiveOutlineItemHtmlSerializer.new(item).to_html
class LiveOutlineItemHtmlSerializer
  # The indentation of one level of the list.
  HTML_INDENT = '  '.freeze

  # Creates a serializer for the given item.
  #
  # @param item [LiveOutlineItem] the item to be serialized
  def initialize(item)
    @item = item
  end

  # Returns the item as HTML.
  #
  # @return [String] the serialized HTML
  def to_html
    x = @item.indent_for HTML_INDENT
    if @item.list?
      <<~END_HTML
        #{x}<li style="list-style: none;">
        #{x}  <details open>
        #{x}    <summary>#{@item.value}</summary>
        #{x}    #{children}
        #{x}  </details>
        #{x}</li>
      END_HTML
    else
      <<~END_HTML
        #{x}<li>#{@item.value}</li>
      END_HTML
    end
  end

  private

  # The HTML of the things under the item.
  #
  # @return [String] the HTML of the children
  def children
    @children ||= @item.children.map { |child| self.class.new(child).to_html }.join("\n")
  end
end
