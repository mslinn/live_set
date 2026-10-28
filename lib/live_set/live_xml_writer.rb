# Writes an XML document the way Ableton Live writes it.
#
# Nokogiri writes XML with libxml2, and libxml2's way of writing it differs from Live's in four
# respects:
#
#   * an empty element is written as <Foo />, with a space before the slash
#   * a newline in an attribute value is written as &#x0A;
#   * a greater-than sign in an attribute value is written as &gt;
#   * the delimiter of an attribute value is chosen from the value itself
#
# The last one differs between Live versions. Live 10 and Live 11 always delimit with double
# quotes, writing a double quote inside the value as &quot;. Live 12 delimits with the quote
# character that occurs later in the value, so that the character that occurs first can be
# written as it is.
class LiveXmlWriter
  # The characters that have to be escaped in an attribute value.
  SPECIAL = /[&<>\n\r\t"']/

  # The Live version at which the delimiter of an attribute value began to be chosen from the
  # value itself.
  QUOTE_FROM_LIVE_VERSION = 12

  # How an attribute value is delimited.
  #
  #   :double - always delimit with double quotes, and write a double quote inside the value as
  #             &quot;                                          (Live 10, Live 11)
  #   :single - delimit with the quote character that occurs later in the value
  #                                                                (Live 12)
  #   :auto   - use the version of the document being written        (the default)
  #
  # @param quote [Symbol] :double, :single or :auto
  def initialize(quote: :auto)
    @quote = quote
  end

  # Writes a document, and returns it as a string.
  #
  # @param document [Nokogiri::XML::Document] the document to write
  # @return [String] the document, as Live would write it
  def write(document)
    policy = @quote == :auto ? policy_for(document) : @quote
    out = +%(<?xml version="1.0" encoding="UTF-8"?>\n)
    document.children.each { |child| write_node(child, out, policy) }
    out << "\n" # Live ends the file with a newline
    out
  end

  private

  # The policy for a document, when the caller did not give one.
  #
  # The version is the minor version of the set, e.g. "12.0_12402". The major version is no help:
  # Live 10, 11 and 12 all write MajorVersion="5".
  #
  # @param document [Nokogiri::XML::Document] the document to write
  # @return [Symbol] :double or :single
  def policy_for(document)
    root = document.root
    return :double if root.nil?

    version = root['MinorVersion'].to_s.split('.').first.to_i
    version >= QUOTE_FROM_LIVE_VERSION ? :single : :double
  end

  # The delimiter for an attribute value.
  #
  # A value that contains only one kind of quote is delimited by the other kind, so that the quote
  # it contains can be written as it is. A value that contains both kinds is delimited by the one
  # that occurs later, so that the one that occurs first can be written as it is.
  #
  # @param value [String] the value of the attribute
  # @return [String] the delimiter, a double quote or an apostrophe
  def delimiter_for(value)
    double = value.index('"')
    return '"' if double.nil?

    single = value.index("'")
    return "'" if single.nil?

    double < single ? "'" : '"'
  end

  def write_node(node, out, policy)
    case node.type
    when Nokogiri::XML::Node::ELEMENT_NODE then write_element(node, out, policy)
    when Nokogiri::XML::Node::TEXT_NODE then out << escape_text(node.content)
    when Nokogiri::XML::Node::CDATA_SECTION_NODE,
         Nokogiri::XML::Node::COMMENT_NODE,
         Nokogiri::XML::Node::PI_NODE then out << node.to_s
    else raise ArgumentError, "cannot write a node of type #{node.type} (#{node.name})"
    end
  end

  def write_element(node, out, policy)
    out << '<' << node.name
    node.attribute_nodes.each { |attribute| write_attribute(attribute, out, policy) }

    if node.children.empty?
      out << ' />'
    else
      out << '>'
      node.children.each { |child| write_node(child, out, policy) }
      out << '</' << node.name << '>'
    end
  end

  def write_attribute(attribute, out, policy)
    value = attribute.value
    delimiter = policy == :single ? delimiter_for(value) : '"'
    out << ' ' << attribute.name << '=' << delimiter << escape_value(value, delimiter) << delimiter
  end

  # Escapes an attribute value.
  #
  # Only the delimiter is escaped, so that the other kind of quote is written as it is.
  #
  # @param value [String] the value to escape
  # @param delimiter [String] the character that delimits the value
  # @return [String] the escaped value
  def escape_value(value, delimiter)
    return value unless SPECIAL.match?(value)

    value.gsub(SPECIAL) do |character|
      case character
      when '&' then '&amp;'
      when '<' then '&lt;'
      when '>' then '&gt;'
      when "\n" then '&#x0A;'
      when "\r" then '&#x0D;'
      when "\t" then '&#x09;'
      when '"' then delimiter == '"' ? '&quot;' : '"'
      when "'" then delimiter == "'" ? '&apos;' : "'"
      end
    end
  end

  # Escapes the text of an element.
  #
  # @param text [String] the text to escape
  # @return [String] the escaped text
  def escape_text(text)
    text.gsub('&', '&amp;').gsub('<', '&lt;')
  end
end
