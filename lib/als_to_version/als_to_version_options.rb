require 'logger'
require 'optparse'
require_relative '../common/command'
require_relative '../common/log'

class AlsToVersion
  extend Command

  # Display help message for als_to_version
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      als_to_version converts a Live set to another version of the Live format.
      If SRC is already at the version it is converted to, the program says so and stops.

      Syntax: als_to_version [OPTIONS] VERSION SRC [DST]

      Where:
        VERSION  is the Ableton Live version to be converted to, e.g. 11.
        SRC      is the path of of the set to be converted, or a selector of a demo set,
                 e.g. demo:11:suite
        DST      is the optional path to write the converted set to. Without it, the
                 converted set is written to the same directory as SRC, with the version
                 as a suffix. For example, if SRC is set.als, and VERSION is 11, the default
                 destination path would be set_11.als.

      OPTIONS can be specified anywhere on the command line:
        -f    Overwrite the destination if it already exists.
        -h    Display this help message.
        #{log_level_help}

      Example:
        als_to_version 11 "$path/to/sample_set.als"  # writes to "$path/to/sample_set_11.als"
        als_to_version 12 "$path/to/sample_set.als" "live_12_test_conversion.als" -f
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # The options the command starts with.
  #
  # @return [Hash] the options
  def self.default_options
    super.merge(force: false)
  end

  def self.parser
    OptionParser.new do |parser|
      parser.program_name = 'als_to_version'

      parser.on('-f', '--force', 'Overwrite the destination when it already exists')
      add_common_options parser

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
