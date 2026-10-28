require 'cgi'
require_relative '../common/log'

# Builds the text of an XML Schema (XSD) from parsed Ableton Live sets.
#
# The generated schema describes the elements that the sample sets contain, the attributes those
# elements carry, and the bounds on how often the elements may appear. It is inferred from a
# sample, not derived from a specification of the format, so it is a starting point rather than a
# complete description of every document the format might allow.
#
# The builder draws these conclusions from the sample:
#
#   * A child element is optional (minOccurs="0") if some instance of its parent lacks it.
#   * A child element may repeat (maxOccurs="unbounded") if some instance of its parent repeats
#     it. The real maximum cannot be learned from a sample, so it is left unbounded.
#   * An attribute is required if every instance of its element carries it, and optional
#     otherwise.
class XsdBuilder
  # The comment that heads the generated schema.
  SCHEMA_PREAMBLE = [
    '  <!--',
    '    This schema was generated from Ableton Live set files. It describes the elements those',
    '    files contained, the attributes they carry, and the bounds on how often they may appear.',
    '    It is an inference from a sample of the format, not a specification of it.',
    '',
    '    maxOccurs is "unbounded" wherever a child element was seen to repeat, because a sample',
    '    cannot reveal the real maximum.',
    '  -->'
  ].freeze

  # @param roots [Array<Nokogiri::XML::Element>] the root elements of the Live sets
  def initialize(roots)
    @roots = roots
  end

  # Build the schema.
  #
  # @return [String] the XSD document
  def build
    [
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">',
      *SCHEMA_PREAMBLE,
      element_declaration(@roots.first.name, @roots, 1, root: true),
      '</xs:schema>'
    ].join("\n")
  end

  private

  # Describe one element, and the elements and attributes it contains.
  #
  # @param name [String] the element's name
  # @param instances [Array<Nokogiri::XML::Element>] instances of the element
  # @param depth [Integer] the indentation depth
  # @param options [Hash] the root flag and the occurrence bounds
  # @return [String] the XSD fragment describing the element
  def element_declaration(name, instances, depth, **options)
    root = options.fetch(:root, false)
    min = options.fetch(:min, 1)
    max = options.fetch(:max, 1)

    indent = '  ' * depth
    occurrence = +''
    occurrence << %( minOccurs="#{min}") unless root || min == 1
    occurrence << %( maxOccurs="unbounded") if !root && max > 1

    sequences = instances.map { |node| node.element_children.map(&:name) }
    ordered_names = sequences.flatten.uniq
    attributes = attribute_declarations(instances, depth + 2)
    check_child_order(name, sequences)

    return %(#{indent}<xs:element name="#{escape(name)}"#{occurrence} type="xs:string"/>) if ordered_names.empty? && attributes.empty?

    lines = [
      %(#{indent}<xs:element name="#{escape(name)}"#{occurrence}>),
      %(#{indent}  <xs:complexType>)
    ]
    lines.concat(element_body(ordered_names, instances, attributes, depth, indent))
    lines << %(#{indent}  </xs:complexType>)
    lines << %(#{indent}</xs:element>)
    lines.join("\n")
  end

  # Describe the contents of a complexType.
  #
  # An element with children gets a sequence of them. An element with only attributes gets simple
  # content, so that the attributes can be declared.
  #
  # @param ordered_names [Array<String>] the names of the child elements
  # @param instances [Array<Nokogiri::XML::Element>] instances of the element
  # @param attributes [Array<String>] the attribute declarations
  # @param depth [Integer] the indentation depth
  # @param indent [String] the indentation for this level
  # @return [Array<String>] the XSD fragments describing the contents
  def element_body(ordered_names, instances, attributes, depth, indent)
    return simple_content(attributes, indent) if ordered_names.empty?

    [
      %(#{indent}    <xs:sequence>),
      *ordered_names.map { |child_name| process_child(instances, child_name, depth + 3) },
      %(#{indent}    </xs:sequence>),
      *attributes
    ]
  end

  # Describe an element that has attributes but no child elements.
  #
  # @param attributes [Array<String>] the attribute declarations
  # @param indent [String] the indentation for this level
  # @return [Array<String>] the XSD fragments describing the simple content
  def simple_content(attributes, indent)
    [
      %(#{indent}    <xs:simpleContent>),
      %(#{indent}      <xs:extension base="xs:string">),
      *attributes,
      %(#{indent}      </xs:extension>),
      %(#{indent}    </xs:simpleContent>)
    ]
  end

  # Describe the attributes that appear on the given instances of an element.
  #
  # An attribute is required if every instance carries it, and optional otherwise.
  #
  # @param instances [Array<Nokogiri::XML::Element>] instances of the element
  # @param depth [Integer] the indentation depth
  # @return [Array<String>] the XSD fragments describing the attributes
  def attribute_declarations(instances, depth)
    indent = '  ' * depth
    per_instance = instances.map { |node| node.attribute_nodes.map(&:name) }

    per_instance.flatten.uniq.map do |attribute_name|
      required = per_instance.all? { |names| names.include?(attribute_name) }
      use = required ? ' use="required"' : ''
      %(#{indent}<xs:attribute name="#{escape(attribute_name)}" type="xs:string"#{use}/>)
    end
  end

  # Warn if the sample files disagree about the order of an element's children.
  #
  # The generated schema declares the children in the order they were first seen, and an
  # xs:sequence requires them to appear in that order. If the samples disagree, the schema will
  # only validate the files that happen to use the first-seen order.
  #
  # @param name [String] the element's name
  # @param sequences [Array<Array<String>>] the child names of each instance
  # @return [void]
  def check_child_order(name, sequences)
    order = sequences.flatten.uniq
    conflicting = sequences.reject { |sequence| consistent_order?(order, sequence) }

    return if conflicting.empty?

    Log.warn("The child elements of <#{name}> are in different orders in the sample files. " \
             'The generated schema uses the order in which they were first seen, and will only ' \
             'validate files that use that order.')
  end

  # Determine whether a sequence of child names follows the given order.
  #
  # Only the names that both sequences have in common are compared, because one file may not
  # contain every child that another file contains.
  #
  # @param order [Array<String>] the expected order of the child names
  # @param sequence [Array<String>] the child names of one instance
  # @return [Boolean] true if the common names appear in the same relative order
  def consistent_order?(order, sequence)
    shared = order & sequence
    return true if shared.size < 2

    positions = shared.map { |child_name| sequence.index(child_name) }
    positions.each_cons(2).all? { |first, second| first < second }
  end

  # Describe one child element.
  #
  # @param instances [Array<Nokogiri::XML::Element>] instances of the parent element
  # @param child_name [String] the name of the child element
  # @param depth [Integer] the indentation depth
  # @return [String] the XSD fragment describing the child element
  def process_child(instances, child_name, depth)
    matches_by_parent = instances.map do |parent|
      parent.element_children.select { |child| child.name == child_name }
    end

    child_instances = matches_by_parent.flatten
    min_occurs = matches_by_parent.any?(&:empty?) ? 0 : 1
    max_occurs = matches_by_parent.map(&:length).max || 1

    element_declaration(child_name, child_instances, depth, min: min_occurs, max: max_occurs)
  end

  # Escape a name so that it can be used in an XSD attribute value.
  #
  # @param value [String] the name to escape
  # @return [String] the escaped name
  def escape(value)
    CGI.escapeHTML(value)
  end
end
