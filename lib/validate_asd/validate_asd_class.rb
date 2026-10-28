require 'colorator'
require 'nokogiri'
require 'zlib'

# Validates an Ableton Live set against an XSD schema.
#
# The .als file is gzip compressed XML, and the schema is read with Nokogiri, so no temporary file is needed.
class ValidateAsd
  # Check that a Live set conforms to an XSD schema.
  #
  # @param args [Array<String>] the command line arguments
  # @return [void]
  def self.run(args)
    remaining = parse_options(args)

    abort help('An ALS file name and an XSD file name must be provided.') if remaining.length < 2
    abort help('Too many arguments. Only an ALS file name and an XSD file name are expected.') if remaining.length > 2

    set_name = remaining.shift&.expand_env
    xsd_name = remaining.shift&.expand_env

    abort help("#{set_name} does not exist") unless File.exist? set_name
    abort help("#{set_name} is a directory") if File.directory? set_name
    abort help("#{xsd_name} does not exist") unless File.exist? xsd_name
    abort help("#{xsd_name} is a directory") if File.directory? xsd_name

    validate_asd = new set_name, xsd_name
    exit 1 unless validate_asd.validate
  end

  def initialize(als_file, xsd_file)
    @als_file = als_file
    @xsd_file = xsd_file
  end

  # @return [Boolean] true if the set conforms to the schema
  def validate
    schema = read_schema
    document = read_document
    errors = schema.validate(document)

    if errors.empty?
      puts "#{@als_file} is valid".green
      return true
    end

    errors.each { |error| puts "#{@als_file}:#{error.line}: #{message error}" }
    puts "#{@als_file} fails to validate".red
    false
  rescue ArgumentError => e
    puts "Error: #{e.message}".red
    false
  end

  private

  # Reads the schema, and checks that the file really is an XSD.
  #
  # @return [Nokogiri::XML::Schema] the schema
  def read_schema
    Nokogiri::XML::Schema.read_memory File.read(@xsd_file)
  rescue Nokogiri::XML::SyntaxError
    raise ArgumentError, "#{@xsd_file} is not an XSD file."
  end

  # Reads the Live set, and checks that the file really is an ALS file.
  #
  # @return [Nokogiri::XML::Document] the document
  def read_document
    document = Nokogiri::XML(Zlib::GzipReader.open(@als_file, &:read), &:strict)
    root = document.root&.name
    raise ArgumentError, "#{@als_file} is not an ALS file. Its root element is <#{root}>." unless root == 'Ableton'

    document
  rescue Zlib::Error
    raise ArgumentError, "#{@als_file} is not an ALS file. It is not gzip compressed."
  rescue Nokogiri::XML::SyntaxError
    raise ArgumentError, "#{@als_file} is not an ALS file. It is not valid XML."
  end

  # Strips the "line:column: LEVEL: " prefix that Nokogiri adds to the message
  def message(error)
    error.message.sub(/\A\d+:\d+: \w+: /, '')
  end
end
