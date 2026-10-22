require 'colorator'
require 'logger'
require 'optparse'

@loglevels = Logger::Severity.constants.sort_by { |name| Logger::Severity.const_get(name) } unless defined?(@loglevels)

# Display help message for generate_xsd
def help_generate_xsd(msg = nil)
  printf "Error: #{msg}\n\n".yellow unless msg.nil?
  msg = <<~END_HELP
    Generate_xsd reads one or more Ableton Live sets and generates an XSD with the given name.

    Syntax: generate_xsd OPTIONS XSD_FILE_NAME PATH_TO_ALS_FILE...

    Environment variables used in XSD_FILE_NAME and PATH_TO_ALS_FILE are expanded.

    Options are:
      -f Overwrite any existing xsd.
      -h Display this help message.

    Example:
      generate_xsd -f xsd_file_name $path/to/my_v12_set.als
  END_HELP
  printf msg.cyan
  exit 1
end

# Parse options for generate_xsd executable
def parse_options
  options = { loglevel: 'WARN' }
  opts = do_parse
  remaining = opts.order!(into: options)

  help_generate_xsd('No XSD file name provided.') if remaining.empty?
  @xsd_file = remaining.shift

  help_generate_xsd('No ALS file names provided.') if remaining.empty?
  @als_files = remaining

  xsd_directory = File.dirname(File.expand_path(@xsd_file))
  help_generate_xsd("Directory does not exist: #{xsd_directory}") unless Dir.exist?(xsd_directory)

  # Normalize loglevel to uppercase string
  options[:loglevel] = options[:loglevel].to_s.upcase if options[:loglevel]

  @loglevel = options[:loglevel]

  msg = "Invalid verbosity value (#{@loglevel}), must be one of one of: #{@loglevels.join ', '}."

  help_generate_xsd msg if @loglevel && !@loglevels.include?(@loglevel.upcase.to_sym)

  options
end

def do_parse
  OptionParser.new do |parser|
    parser.program_name = File.basename __FILE__
    @parser = parser

    parser.on('-f', '--force', 'Overwrite the output xsd if it already exists')
    parser.on('-l', '--loglevel LOGLEVEL', String, "Logging level (#{@loglevels.join ', '})")

    parser.on_tail('-h', '--help', 'Show this message') do
      generate_xsd
    end
  end
end
