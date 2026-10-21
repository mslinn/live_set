require 'nokogiri'
require 'cgi'

# This program ignores attributes and namespaces, treats text as strings, and assumes consistent child ordering. The
# generated XSD is a starting point, not a complete description of every XML document the format might allow.
#
# With just one XML file, the generator can detect children repeated within that file, but it can’t know that a child is
# optional if it never sees another instance of the same parent without that child. Multiple representative files help
# infer that.
#
# Usage:
# generate_xsd sample1.xml sample2.xml # Output XSD to STDOUT
#
class XsdFromXml
  def initialize(*files)
    raise ArgumentError, 'Provide at least one XML file' if files.empty?

    @roots = files.map do |file|
      document = Nokogiri::XML(File.read(file)) { |config| config.strict.nonet }
      document.root || raise(ArgumentError, "#{file} has no root element")
    end

    root_names = @roots.map(&:name).uniq
    raise ArgumentError, "XML files have different root elements: #{root_names.join(', ')}" if root_names.size > 1
  end

  def generate
    root = @roots.first
    <<~XSD
      <?xml version="1.0" encoding="UTF-8"?>
      <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
      #{element_declaration(root.name, @roots, 1, root: true)}
      </xs:schema>
    XSD
  end

  private

  def element_declaration(name, instances, depth, **options)
    root = options.fetch(:root, false)
    min  = options.fetch(:min, 1)
    max  = options.fetch(:max, 1)

    indent = '  ' * depth
    occurrence = +''
    occurrence << %( minOccurs="#{min}") unless root || min == 1
    occurrence << %( maxOccurs="unbounded") if !root && max > 1

    children_by_name = instances.flat_map(&:element_children)
                                .group_by(&:name)

    return %(#{indent}<xs:element name="#{escape(name)}" type="xs:string"#{occurrence}/>) \
      if children_by_name.empty?

    lines = [
      %(#{indent}<xs:element name="#{escape(name)}"#{occurrence}>),
      %(#{indent}  <xs:complexType>),
      %(#{indent}    <xs:sequence>)
    ]

    ordered_names = instances.flat_map { |node| node.element_children.map(&:name) }.uniq

    ordered_names.each do |child_name|
      lines << process_child(instances, child_name)
    end

    lines.push(%(#{indent}    </xs:sequence>),
               %(#{indent}  </xs:complexType>),
               %(#{indent}</xs:element>))

    lines.join("\n")
  end

  def process_child(instances, child_name)
    matches_by_parent = instances.map do |parent|
      parent.element_children.select { |child| child.name == child_name }
    end

    child_instances = matches_by_parent.flatten
    min_occurs = matches_by_parent.any?(&:empty?) ? 0 : 1
    max_occurs = matches_by_parent.map(&:length).max || 1

    element_declaration(
      child_name,
      child_instances,
      depth + 3,
      min: min_occurs,
      max: max_occurs
    )
  end

  def escape(value)
    CGI.escapeHTML(value)
  end
end
