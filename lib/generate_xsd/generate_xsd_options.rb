require 'colorator'
require 'logger'
require 'optparse'
require_relative '../common/command_options'
require_relative '../common/log'

class XsdFromXml
  # Display help message for generate_xsd
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      Generate_xsd reads one or more Ableton Live sets and generates an XSD with the given name.

      Syntax: generate_xsd OPTIONS XSD_FILE_NAME PATH_TO_ALS_FILE...

      Environment variables used in XSD_FILE_NAME and PATH_TO_ALS_FILE are expanded.

      Options are:
        -f Overwrite any existing xsd.
        -h Display this help message.

      Example:
        generate_xsd -f xsd_file_name $path/to/my_v12_set.als
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # Parse options for generate_xsd executable
  #
  # @param args [Array<String>] the command line arguments
  # @return [Array(Hash, String, Array<String>)] the options, the XSD file name, and the ALS file names
  def self.parse_options(args)
    options = { loglevel: 'WARN' }
    remaining = do_parse.order!(args, into: options)

    abort help('No XSD file name provided.') if remaining.empty?
    xsd_file = remaining.shift

    abort help('No ALS file names provided.') if remaining.empty?

    xsd_directory = File.dirname(File.expand_path(xsd_file))
    abort help("Directory does not exist: #{xsd_directory}") unless Dir.exist?(xsd_directory)

    error = CommandOptions.loglevel_error(options)
    abort help(error) if error

    [options, xsd_file, remaining]
  end

  def self.do_parse
    OptionParser.new do |parser|
      parser.program_name = 'generate_xsd'

      parser.on('-f', '--force', 'Overwrite the output xsd if it already exists')
      parser.on('-l', '--loglevel LOGLEVEL', String, "Logging level (#{LOG_LEVELS.join ', '})")

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
