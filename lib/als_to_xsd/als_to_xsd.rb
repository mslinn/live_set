require 'colorator'
require 'nokogiri'
require 'zlib'
require_relative '../common/command'
require_relative '../live_set/als_file'
require_relative 'als_to_xsd_options'
require_relative 'xsd_builder'

# Generates an XML Schema (XSD) from one or more Ableton Live sets.
#
# The sets are read and their structure is handed to XsdBuilder, which turns it
# into the schema. See `lib/generate_xsd/xsd_builder.rb` for what the schema
# describes, and what the generator infers from the sample.
#
# The schema is inferred from the XML stored in the sets it is given, so it
# describes what those sets contain and nothing more. Newer versions of Live
# write constructs that older demo sets do not have: the schema inferred from
# the demo sets alone rejects the file Live wrote when it opened and saved a set
# of an older version. Give the generator every set of the version you have, not
# just the demo sets.
#
# The class is a library and a command: `AlsToXsd.schema_of` gives the schema
# of a set of files to other code, and `AlsToXsd.run` is the command that writes
# it to a file.
#
# Usage: generate_xsd OPTIONS XSD_FILE_NAME PATH_TO_ALS_FILE...
class AlsToXsd
  extend Command

  # Generate an XSD from one or more Live sets, and write it to a file.
  #
  # The command returns an error code, and it does not exit the process, so that it can
  # be called from other code.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Integer] the exit status: zero when the schema was written
  def self.run(args)
    options, remaining = parse_options(args)
    xsd_file, als_files = arguments_of(remaining)

    check_overwrite(xsd_file, options[:force])

    als_files = expand_globs(als_files).map do |file|
      expanded_file = file.expand_env
      abort "Error: ALS file does not exist: #{expanded_file}" unless File.exist?(expanded_file)
      abort "Error: #{expanded_file} is a directory" if File.directory? expanded_file
      expanded_file
    end

    trap('SIGINT') { throw :ctrl_c }

    catch :ctrl_c do
      write_schema xsd_file, als_files, **options
      0
    end
  rescue StandardError => e
    warn e.full_message
    1
  end

  # The XSD file and the ALS files that the arguments name.
  #
  # @param remaining [Array<String>] the arguments that are not options
  # @return [Array(String, Array<String>)] the path of the XSD file, and the paths of the ALS files
  def self.arguments_of(remaining)
    abort help('No XSD file name provided.') if remaining.empty?
    xsd_file = remaining.shift.expand_env

    abort help('No ALS file names provided.') if remaining.empty?

    directory = File.dirname(File.expand_path(xsd_file))
    abort help("Directory does not exist: #{directory}") unless Dir.exist?(directory)

    [xsd_file, remaining]
  end

  # The schema of the given sets.
  #
  # This is the library: it takes the sets, and it returns the schema. It does not write a
  # file, and it does not parse a command line.
  #
  # @param als_files [Array<String>] the paths of the sets
  # @param options [Hash] the command line options
  # @return [String] the schema
  def self.schema_of(als_files, **)
    new(als_files, **).generate
  end

  # Writes the schema of the given sets to a file.
  #
  # @param xsd_file [String] the path of the file to write
  # @param als_files [Array<String>] the paths of the sets
  # @param options [Hash] the command line options
  # @return [void]
  def self.write_schema(xsd_file, als_files, **)
    generator = new(als_files, **)
    content = generator.generate
    generator.write(xsd_file, content)
    puts "Wrote '#{File.expand_path xsd_file}'".green
  end

  # The files the arguments name.
  #
  # An argument that holds a glob pattern is expanded by the command, and a pattern that
  # holds `**` matches the files in the directories below the one that is named. The shell
  # expands the patterns it is given before the command sees them, so the command expands
  # only the ones that are left.
  #
  # @param files [Array<String>] the arguments
  # @return [Array<String>] the files
  def self.expand_globs(files)
    files.flat_map do |file|
      path = file.expand_env
      path.include?('*') ? Dir.glob(path) : [file]
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

  # @param xml_files [Array<String>] the paths of the Live set files to read
  # @param options [Hash] the command line options
  def initialize(xml_files, **options)
    raise ArgumentError, 'Provide at least one XML file' if xml_files.empty?

    @overwrite = options[:force]
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
  # @param xsd_file [String] the path of the XSD file to write
  # @param content [String] the generated schema
  # @return [void]
  def write(xsd_file, content)
    self.class.check_overwrite(xsd_file, @overwrite)

    File.write(xsd_file, content, encoding: 'UTF-8')
  end
end
