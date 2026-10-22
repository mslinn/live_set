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

    set_name = remaining.shift&.expand_env
    xsd_name = remaining.shift&.expand_env

    abort help('An XSD file name must be provided.') if xsd_name.nil?
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
    schema = Nokogiri::XML::Schema.read_memory File.read(@xsd_file)
    document = Nokogiri::XML(Zlib::GzipReader.open(@als_file, &:read), &:strict)
    errors = schema.validate(document)

    if errors.empty?
      puts "#{@als_file} is valid".green
      return true
    end

    errors.each { |error| puts "#{@als_file}:#{error.line}: #{message error}" }
    puts "#{@als_file} fails to validate".red
    false
  rescue Zlib::Error, Nokogiri::XML::SyntaxError => e
    puts "Error: #{e.message}".red
    false
  end

  private

  # Strips the "line:column: LEVEL: " prefix that Nokogiri adds to the message
  def message(error)
    error.message.sub(/\A\d+:\d+: \w+: /, '')
  end
end
