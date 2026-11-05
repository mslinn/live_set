require 'optparse'
require_relative 'command_options'

# The parts of a command that are the same everywhere.
#
# Every command is a class with three methods: `run` takes the command line arguments and
# does the work, `help` says what the command does and what its options mean, and `parser`
# describes the options of the command.
#
# A command extends this module, and it gets the parsing of the options, the check of the
# log level, and the handling of the errors of the parser. A command that is given an
# option it does not understand, or an option that is missing its argument, says so and
# prints its help, instead of failing with a backtrace.
#
#   class AlsExample
#     extend Command
#
#     def self.run(args)
#       options, remaining = parse_options(args)
#       ...
#     end
#
#     def self.help(msg = nil)
#       ...
#     end
#
#     def self.parser
#       OptionParser.new do |parser|
#         parser.program_name = 'als_example'
#         ...
#       end
#     end
#   end
module Command
  # Parses the options of the command.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Array(Hash, Array<String>)] the options and the remaining arguments
  def parse_options(args)
    options = default_options
    remaining = parser.permute!(args, into: options)
    normalize_options options

    error = CommandOptions.loglevel_error(options)
    abort help(error) if error

    [options, remaining]
  rescue OptionParser::ParseError => e
    abort help(e.message)
  end

  # The options the command starts with.
  #
  # @return [Hash] the options
  def default_options
    { loglevel: 'WARN' }
  end

  # The parser of the options of the command.
  #
  # @return [OptionParser] the parser
  def parser
    raise NotImplementedError, "#{name} does not describe its options"
  end

  # The help message of the command.
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def help(msg = nil)
    raise NotImplementedError, "#{name} does not describe itself"
  end

  private

  # The options that OptionParser names differently than the command does.
  #
  # @param options [Hash] the options, which are updated in place
  # @return [void]
  def normalize_options(options)
    options[:time_zone] = options.delete(:'time-zone') if options.key?(:'time-zone')
  end
end
