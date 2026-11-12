require 'optparse'
require_relative 'command_options'
require_relative 'log'

# Mixin for the common parts of a command.
#
# Every command is a class with three methods:
# - `run` takes the command line arguments and does the work
# - `help` says what the command does and what its options mean
# - `parser` describes the options of the command.
#
# The last two live in a file of their own, next to the command:
# `lib/als_example/als_example_options.rb`. The command requires that file, and the
# file requires what it needs itself, so that either of them can be loaded on its own.
#
# Every command mixes in this module; it provides functionality common to all commands, including option parsing, and
# logging. A command that is given an option it does not understand, or an option that is missing its argument, says so
# and prints its help message, instead of failing with a backtrace.
#
# lib/als_example/als_example.rb:
#   require 'shellwords'
#   require_relative '../common/command'
#   require_relative '../common/run'
#   require_relative 'als_example_options'
#
#   class AlsExample
#     extend Command
#     include Run
#
#     def self.run(args)
#       options, remaining = parse_options(args)
#       ...
#     end
#
#     def initialize(whatever, **options)
#       ...
#     end
#   end
#
#
# lib/als_example/als_example_options.rb:
#   require 'logger'
#   require 'optparse'
#   require_relative '../common/command'
#   require_relative '../common/log'
#
#   class AlsExample
#     extend Command
#
#     # Display help message for als_example
#     # @param msg [String, nil] an error message to show above the help
#     # @return [String] the help message
#     def self.help(msg = nil)
#       ...
#     end
#
#     # The options the command starts with.
#     # @return [Hash] the options
#     def self.default_options
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
  # Parses command options.
  #
  # The parser names an option after its long switch, so the log level is parsed as `:log`
  # and held as `:loglevel`, which is the name the commands use.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Array(Hash, Array<String>)] the options and the remaining arguments
  def parse_options(args)
    options = default_options
    remaining = parser.permute!(args, into: options)
    options[:loglevel] = options.delete(:log) if options.key? :log
    error = CommandOptions.loglevel_error(options)
    abort help(error) if error

    Log.level = options[:loglevel] if options[:loglevel]

    [options, remaining]
  rescue OptionParser::ParseError => e
    abort help(e.message)
  end

  # Checks that a command was not given more positional parameters than it takes.
  #
  # A command that is given more says so, prints its help, and exits. A path with a space
  # in it is one parameter, and has to be quoted.
  #
  # @param remaining [Array<String>] the positional parameters
  # @param count [Integer] the number of parameters the command takes
  # @return [void]
  def check_extra_parameters(remaining, count)
    return if remaining.length <= count

    abort help("Extra positional parameter(s): only #{count} expected.")
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
    raise NotImplementedError, "#{name} needs an option parser"
  end

  # The command help message.
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def help(msg = nil)
    raise NotImplementedError, "#{name} needs a help message"
  end

  private

  # Adds the options that every command has to a parser.
  #
  # Every command can be told how much to say: the log level is the level of the messages
  # that are written to the standard error, and it is one of the levels of the logger.
  #
  # @param parser [OptionParser] the parser of the command
  # @return [void]
  def add_common_options(parser)
    parser.on('-l', '--log LOGLEVEL', String, "Log level (#{LOG_LEVELS.join ', '})")
  end

  def help_help
    <<~END_MSG.chomp
      -h, --help
                Display this help message.
    END_MSG
  end

  # The line of the help that says what the log levels are.
  #
  # @return [String] the line
  def log_level_help
    <<~END_MSG.chomp
      -l LOGLEVEL, --log LOGLEVEL
                Set the log level. Allowable values are:
                #{LOG_LEVELS.join ', '}.
    END_MSG
  end
end
