require 'cgi'
require 'colorator'
require 'nokogiri'
require 'zlib'

# This program ignores attributes and namespaces, treats text as strings, and assumes consistent child ordering. The
# generated XSD is a starting point, not a complete description of every XML document the format might allow.
#
# With just one XML file, the generator can detect children repeated within that file, but it can’t know that a child is
# optional if it never sees another instance of the same parent without that child. Multiple representative files help
# infer that.
#
# Usage: generate_xsd sample1.xml sample2.xml
#
class XsdFromXml
  # Generate an XSD from one or more Live sets, and write it to a file.
  #
  # @param args [Array<String>] the command line arguments
  # @return [void]
  def self.run(args)
    options, xsd_file, als_files = parse_options(args)

    als_files = als_files.map do |file|
      expanded_file = file.expand_env
      abort help("ALS file does not exist: #{expanded_file}") unless File.exist?(expanded_file)
      abort help("#{expanded_file} is a directory") if File.directory? expanded_file
      expanded_file
    end

    trap('SIGINT') { throw :ctrl_c }

    generate_xsd = new xsd_file, als_files, **options
    catch :ctrl_c do
      content = generate_xsd.generate
      File.write(xsd_file, content)
      puts "Wrote '#{File.expand_path xsd_file}'".green
    rescue Exception => e # rubocop:disable Lint/RescueException
      puts e.full_message
    end
  end

  def initialize(xsd_file, xml_files, **options)
    raise ArgumentError, 'Provide at least one XML file' if xml_files.empty?

    @overwrite = options[:force]

    @xsd_file = xsd_file
    @overwrite = options[:force]
    @xml_docs = []
    @roots = xml_files.map do |xml_file|
      contents = Zlib::GzipReader.open(xml_file, &:read)
      xml_doc = Nokogiri::Slop contents
      xml_doc.root || raise(ArgumentError, "#{xml_file} has no root element")
      @xml_docs << xml_doc
      xml_doc.root
    end

    @root_names = @roots.map(&:name).uniq
    raise ArgumentError, "XML files have different root elements: #{@root_names.join(', ')}" if @root_names.size > 1
  end

  def generate
    root_name = @root_names.first
    <<~XSD
      <?xml version="1.0" encoding="UTF-8"?>
      <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
      #{element_declaration(root_name, @roots, 1, root: true)}
      </xs:schema>
    XSD
  end

  private

  def element_declaration(name, instances, depth, **options)
    root = options.fetch(:root, false)
    min  = options.fetch(:min, 1)
    max  = options.fetch(:max, 1)

    indent = '  ' * depth
    occurrence = + ''
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
      lines << process_child(instances, child_name, depth)
    end

    lines.push(%(#{indent}    </xs:sequence>),
               %(#{indent}  </xs:complexType>),
               %(#{indent}</xs:element>))

    lines.join("\n")
  end

  def process_child(instances, child_name, depth)
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
