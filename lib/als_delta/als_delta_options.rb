require 'colorator'
require 'logger'
require 'optparse'
require_relative '../common/command'
require_relative '../common/log'

class AlsDelta
  # Where the backups are stored.
  #
  # A backup is written beside the set it is a backup of: it is the file of the set with
  # `_backup` before the extension, e.g. `song_backup.als` beside `song.als`. The backup is
  # deleted when the command exits, unless the `-k` option is given: a kept backup is the
  # file of the set with the time it was made before the extension, e.g.
  # `song_2026-11-09_19:30:00.als`. The location of the backups is the directory of the set,
  # and there is no option that changes it.

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

      Syntax: als_delta OPTIONS PATH_TO_ALS_FILE

      Environment variables used in PATH_TO_ALS_FILE are expanded.

      Options are:
        -k Keep each backup and timestamp it, instead of overwriting the previous backup.
        -h Display this help message.
        #{log_level_help}

      Example (references an environment variable called `path`):
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
