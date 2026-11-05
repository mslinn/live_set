require 'colorator'
require 'logger'
require 'optparse'
require_relative '../common/command'
require_relative '../common/log'

class AlsToXsd
  # Display help message for als_to_xsd
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      als_to_xsd reads one or more Ableton Live sets and generates an XSD with the given name.

      Syntax: als_to_xsd [OPTIONS] XSD_FILE_NAME PATH_TO_ALS_FILE...

      Environment variables used in XSD_FILE_NAME and PATH_TO_ALS_FILE are expanded by the operating system.

      A PATH_TO_ALS_FILE that holds a glob pattern is expanded by the command, and a pattern
      that holds ** matches the files in the directories below the one that is named.

      OPTIONS may be specified anywhere on the command line:
        -f Overwrite any existing xsd.
        -h Display this help message.
        #{log_level_help}

      Example:
        $ als_to_xsd -f "$live_reference_sets/xsd/demo11.xsd" \
          "$live_reference_sets/sets/live_11/projects_and_als"/**/*.als
        Wrote '/mnt/f/work/ableton/live_reference_sets/xsd/demo11.xsd'
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # Parse options for the als_to_xsd command
  #
  # @param args [Array<String>] the command line arguments
  # @return [Array(Hash, String, Array<String>)] the options, the XSD file name, and the ALS file names
  def self.parse_options(args)
    options, remaining = super

    abort help('No XSD file name provided.') if remaining.empty?
    xsd_file = remaining.shift.expand_env

    abort help('No ALS file names provided.') if remaining.empty?

    xsd_directory = File.dirname(File.expand_path(xsd_file))
    abort help("Directory does not exist: #{xsd_directory}") unless Dir.exist?(xsd_directory)

    [options, xsd_file, remaining]
  end

  def self.parser
    OptionParser.new do |parser|
      parser.program_name = 'als_to_xsd'

      parser.on('-f', '--force', 'Overwrite the output xsd if it already exists')
      add_common_options parser

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
