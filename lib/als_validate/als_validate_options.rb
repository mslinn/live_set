require 'colorator'
require 'optparse'
require_relative '../common/command'

class AlsValidate
  # Display help message for als_validate
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      Als_validate checks that an Ableton Live set conforms to an XSD schema.

      Syntax: als_validate [OPTIONS] PATH_TO_ALS_FILE SCHEMA.xsd

      Environment variables used in PATH_TO_ALS_FILE are expanded by the operating system.

      OPTIONS may be specified anywhere on the command line:
        -h Display this help message.
        #{log_level_help}

      Example:
        $ als_validate \
          "$live_reference_sets/sets/live_11/experiments/projects_and_als/one_midi_track_only_11 Project/factory_default_11.als" \
          "$live_reference_sets/xsd/demo11.xsd"
        /mnt/f/work/ableton/live_reference_sets/sets/live_11/experiments/projects_and_als/one_midi_track_only_11 Project/factory_default_11.als is valid
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  def self.parser
    OptionParser.new do |parser|
      parser.program_name = 'als_validate'

      add_common_options parser

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
