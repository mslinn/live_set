require 'logger'
require 'optparse'
require_relative '../common/command'
require_relative '../common/log'

class AlsToXsd
  extend Command

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
        -f      Overwrite any existing xsd.
        #{help_help}
        #{log_level_help}

      Example:
        $ als_to_xsd -f "$live_reference_sets/xsd/demo11.xsd" \
          "$live_reference_sets/sets/live_11/demo/projects_and_als"/**/*.als
        Wrote '/mnt/f/work/ableton/live_reference_sets/xsd/demo11.xsd'
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
      parser.program_name = 'als_to_xsd'

      parser.on('-f', '--force', 'Overwrite the output xsd if it already exists')
      add_common_options parser

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
