require 'colorator'
require 'nokogiri'
require 'zlib'
require_relative '../live_set/als_file'
require_relative 'generate_xsd_options'
require_relative 'xsd_builder'

# Generates an XML Schema (XSD) from one or more Ableton Live sets.
#
# The sets are read and their structure is handed to XsdBuilder, which turns it into the schema.
# See lib/generate_xsd/xsd_builder.rb for what the schema describes, and what the generator
# infers from the sample.
#
# Usage: generate_xsd OPTIONS XSD_FILE_NAME PATH_TO_ALS_FILE...
class XsdFromXml
  # Generate an XSD from one or more Live sets, and write it to a file.
  #
  # @param args [Array<String>] the command line arguments
  # @return [void]
  def self.run(args)
    options, xsd_file, als_files = parse_options(args)

    check_overwrite(xsd_file, options[:force])

    als_files = als_files.map do |file|
      expanded_file = file.expand_env
      abort help("ALS file does not exist: #{expanded_file}") unless File.exist?(expanded_file)
      abort help("#{expanded_file} is a directory") if File.directory? expanded_file
      expanded_file
    end

    trap('SIGINT') { throw :ctrl_c }

    catch :ctrl_c do
      generate_xsd = new xsd_file, als_files, **options
      content = generate_xsd.generate
      generate_xsd.write(content)
      puts "Wrote '#{File.expand_path xsd_file}'".green
    rescue StandardError => e
      warn e.full_message
      exit 1
    end
  end

  # Refuse to overwrite an existing file, unless the caller asked us to.
  #
  # @param path [String] the path of the file to write
  # @param force [Boolean] whether overwriting was requested
  # @return [void]
  def self.check_overwrite(path, force)
    return if force || !File.exist?(path)

    abort help("File already exists: #{path}. Use --force to overwrite it.")
  end

  # @param xsd_file [String] the path of the XSD file to write
  # @param xml_files [Array<String>] the paths of the Live set files to read
  # @param options [Hash] the command line options
  def initialize(xsd_file, xml_files, **options)
    raise ArgumentError, 'Provide at least one XML file' if xml_files.empty?

    @overwrite = options[:force]
    @xsd_file = xsd_file
    @roots = xml_files.map do |xml_file|
      contents = AlsFile.read_text(xml_file)
      xml_doc = Nokogiri::XML(contents)
      xml_doc.root || raise(ArgumentError, "#{xml_file} has no root element")
      xml_doc.root
    end

    root_names = @roots.map(&:name).uniq
    raise ArgumentError, "XML files have different root elements: #{root_names.join(', ')}" if root_names.size > 1
  end

  # Generate the schema.
  #
  # @return [String] the XSD document
  def generate
    XsdBuilder.new(@roots).build
  end

  # Write the generated schema to the output file.
  #
  # @param content [String] the generated schema
  # @return [void]
  def write(content)
    self.class.check_overwrite(@xsd_file, @overwrite)

    File.write(@xsd_file, content, encoding: 'UTF-8')
  end
end
