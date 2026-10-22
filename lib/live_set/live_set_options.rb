require 'colorator'
require 'logger'
require 'optparse'
require_relative '../common/command_options'
require_relative '../common/log'

class LiveSet
  # Display help message for live_set
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      Live_set displays information about an Ableton Live set or converts a Live 12 set to Live 11 format.
      If the special folder called 'Ableton Project Info' is not present in the same folder as the .als file, a warning is generated.
      Similarly, if 'Ableton Project Info' is present in any parent folder, a warning is issued and the user is asked if the directory should be renamed.

      Syntax: live_set OPTIONS PATH_TO_ALS_FILE

      Environment variables used in PATH_TO_ALS_FILE are expanded.

      Options are:
        -11 Convert the Live 12 set to Live 11 format.
        -f If -11 is specified, overwrite any existing Live 11 set. Without it, an existing
           set is left alone.
        -h Display this help message.

      Example:
        live_set -11 -f $path/to/my_v12_set.als
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # Parse options for live_set executable
  #
  # @param args [Array<String>] the command line arguments
  # @return [Array(Hash, Array<String>)] the options and the remaining arguments
  def self.parse_options(args)
    options = { loglevel: 'WARN' }
    remaining = do_parse.order!(args, into: options)

    error = CommandOptions.loglevel_error(options)
    abort help(error) if error
    [options, remaining]
  end

  def self.do_parse
    OptionParser.new do |parser|
      parser.program_name = 'live_set'

      parser.on('-11', '--convert11', 'Make a copy of the set that is compatible with Live 11')
      parser.on('-f', '--force', 'Overwrite the output set if it already exists')
      parser.on('-l', '--loglevel LOGLEVEL', String, "Logging level (#{LOG_LEVELS.join ', '})")
      parser.on('-s', '--show', 'Display information about the Ableton Live set')

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
