require 'logger'
require 'optparse'
require_relative '../common/command'
require_relative '../common/log'

class AlsDelta
  extend Command

  # Display help message for als_delta
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      als_delta: Shows changes to an .als file each time a session file is saved.
      Press any key to make a backup of the current version of the `als` file and
      compare it with previous version.

      Backups can be kept by using the -k option. By default, only one backup is
      used, and it is deleted when the process exits.

      Syntax: als_delta [OPTIONS] PATH_TO_ALS_FILE

      Environment variables used in PATH_TO_ALS_FILE are expanded.

      OPTIONS can be specified anywhere on the command line:
        #{help_help}
        -k      Keep each backup and timestamp it, instead of overwriting the previous backup.
        #{log_level_help}

      Example (references an environment variable called "path"):
        $ als_delta "$path/to/my_set.als"
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # The options the command starts with.
  #
  # @return [Hash] the options
  def self.default_options
    super.merge(keep: false)
  end

  def self.parser
    OptionParser.new do |parser|
      parser.program_name = 'als_delta'

      parser.on('-k', '--keep', 'Keep all backups')
      add_common_options parser
      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
