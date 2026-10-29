require 'date'
require 'fileutils'
require 'shellwords'
require_relative '../common/run'

# Validates an Ableton Live set against an XSD schema.
#
# The .als file is gzip compressed XML, and the schema is read with Nokogiri, so no temporary file is needed.
class ValidateAsd
  # The error raised when one of the two files is not what it was said to be.
  class InvalidInput < StandardError; end

  # Check that a Live set conforms to an XSD schema.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Integer] the exit status of the command
  def self.run(args)
    remaining = parse_options(args)
    set_name, xsd_name = check_arguments remaining

    validate_asd = new set_name, xsd_name
    errors = validate_asd.validate

    if errors.empty?
      puts "#{set_name} is valid".green
      return 0
    end

    errors.each { |error| puts "#{set_name}:#{error.line}: #{message error}" }
    puts "#{set_name} fails to validate".red
    1
  rescue InvalidInput => e
    puts "Error: #{e.message}".red
    1
  end

  # Checks the arguments of the command.
  #
  # @param remaining [Array<String>] the arguments that are not options
  # @return [Array(String, String)] the path of the set and the path of the schema
  def self.check_arguments(remaining)
    abort help('An ALS file name and an XSD file name must be provided.') if remaining.length < 2
    abort help('Too many arguments. Only an ALS file name and an XSD file name are expected.') if remaining.length > 2

    set_name = remaining.shift&.expand_env
    xsd_name = remaining.shift&.expand_env

    abort help("#{set_name} does not exist") unless File.exist? set_name
    abort help("#{set_name} is a directory") if File.directory? set_name
    abort help("#{xsd_name} does not exist") unless File.exist? xsd_name
    abort help("#{xsd_name} is a directory") if File.directory? xsd_name

    [set_name, xsd_name]
  end

  def initialize(als_file, xsd_file)
    @als_file = als_file
    @xsd_file = xsd_file
  end

  # Checks the set against the schema.
  #
  # @return [Array<Nokogiri::XML::SyntaxError>] the errors the set has, or an empty array if it
  #   conforms to the schema
  # @raise [InvalidInput] when one of the two files is not what it was said to be
  def validate
    schema = read_schema
    document = read_document

    schema.validate(document)
  end

  private

  # Reads the schema, and checks that the file really is an XSD.
  #
  # @return [Nokogiri::XML::Schema] the schema
  def read_schema
    Nokogiri::XML::Schema.read_memory File.read(@xsd_file)
  rescue Nokogiri::XML::SyntaxError
    raise InvalidInput, "#{@xsd_file} is not an XSD file."
  end

  # Reads the Live set, and checks that the file really is an ALS file.
  #
  # @return [Nokogiri::XML::Document] the document
  def read_document
    document = Nokogiri::XML(AlsFile.read_gzip_text(@als_file), &:strict)
    root = document.root&.name
    raise InvalidInput, "#{@als_file} is not an ALS file. Its root element is <#{root}>." unless root == 'Ableton'

    document
  rescue Zlib::Error
    raise InvalidInput, "#{@als_file} is not an ALS file. It is not gzip compressed."
  rescue Nokogiri::XML::SyntaxError
    raise InvalidInput, "#{@als_file} is not an ALS file. It is not valid XML."
  end

  # Strips the "line:column: LEVEL: " prefix that Nokogiri adds to the message
  def message(error)
    error.message.sub(/\A\d+:\d+: \w+: /, '')
  end
end
