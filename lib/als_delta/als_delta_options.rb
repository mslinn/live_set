require 'colorator'
require 'logger'
require 'optparse'
require_relative '../common/command_options'
require_relative '../common/log'

class AlsDelta
  # Display help message for als_delta
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      als_delta: Shows changes to an .als file each time a session file is saved.
      Press any key to compare with previous version.

      Syntax: als_delta OPTIONS PATH_TO_ALS_FILE

      Environment variables used in PATH_TO_ALS_FILE are expanded.

      Options are:
        -k Keep each backup (default is to delete them)
        -h Display this help message.

      Example (references an environment variable called `path`):
      als_delta $path/to/my_v12_set.als
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # Parse options for als_delta executable
  #
  # @param args [Array<String>] the command line arguments
  # @return [Array(Hash, Array<String>)] the options and the remaining arguments
  def self.parse_options(args)
    options = { keep: false, loglevel: 'WARN' }
    remaining = do_parse.order!(args, into: options)

    error = CommandOptions.loglevel_error(options)
    abort help(error) if error

    [options, remaining]
  end

  def self.do_parse
    OptionParser.new do |parser|
      parser.program_name = 'als_delta'

      parser.on('-k', '--keep', 'Keep all backups')
      parser.on('-l', '--loglevel LOGLEVEL', String, "Log level (#{LOG_LEVELS.join ', '})")
      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
