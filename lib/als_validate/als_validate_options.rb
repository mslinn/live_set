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

      Syntax: als_validate PATH_TO_ALS_FILE SCHEMA.xsd

      Environment variables used in PATH_TO_ALS_FILE are expanded.

      Options are:
        -h Display this help message.

      Example:
        validate_asd $path/to/my_v12_set.als schema.xsd
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  def self.parser
    OptionParser.new do |parser|
      parser.program_name = 'als_validate'

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
