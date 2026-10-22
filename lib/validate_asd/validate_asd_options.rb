require 'colorator'
require 'optparse'

class ValidateAsd
  # Display help message for validate_asd
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      Validate_asd checks that an Ableton Live set conforms to an XSD schema.

      Syntax: validate_asd PATH_TO_ALS_FILE SCHEMA.xsd

      Environment variables used in PATH_TO_ALS_FILE are expanded.

      Options are:
        -h Display this help message.

      Example:
        validate_asd $path/to/my_v12_set.als schema.xsd
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # Parse options for validate_asd executable
  #
  # @param args [Array<String>] the command line arguments
  # @return [Array<String>] the remaining arguments
  def self.parse_options(args)
    do_parse.order!(args)
  end

  def self.do_parse
    OptionParser.new do |parser|
      parser.program_name = 'validate_asd'

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
