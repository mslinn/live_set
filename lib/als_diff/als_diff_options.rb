require 'logger'
require 'optparse'
require_relative '../common/command'
require_relative '../common/log'

class AlsDiff
  extend Command

  # Display help message for als_diff
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      Als_diff compares two Ableton Live sets element by element, and prints the
      differences.

      A Live set is XML, usually gzip-compressed, so the documents can be .als files
      or files containing XML extracted from an ALS file. The two documents are
      first promoted to the newer of the two ALS versions, and are then walked in
      parallel: the children of two elements are matched by their names, and the
      children that one of the elements has and the other does not are reported as
      differences. The attributes of two elements are compared as well.

      Syntax: als_diff [OPTIONS] FILE1 FILE2

      Where: FILE1 and FILE2 are paths

      OPTIONS can be specified before or after positional parameters:
        --count only print the number of differences
        #{help_help}
        #{log_level_help}
        --max N print at most N differences
        --skip NAME
                Do not compare elements with this name, or any children.
                This option may be specified more than once.

      The exit status is 0 when the documents are the same, and 1 when they are not.

      Examples:
        als_diff live11.als live12.als
        als_diff live11.als live12.als --skip Devices --skip DeviceChain
        als_diff live11.als live12.als --count
        als_diff --skip Devices --skip DeviceChain live11.als live12.als
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # The options the command starts with.
  #
  # @return [Hash] the options
  def self.default_options
    super.merge(skip: [])
  end

  def self.parser
    OptionParser.new do |parser|
      parser.program_name = 'als_diff'

      parser.on('--skip NAME', Array, 'Do not compare the elements with this name')
      parser.on('--count', 'Print the number of differences')
      parser.on('--max N', Integer, 'Print at most N differences')
      add_common_options parser

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
