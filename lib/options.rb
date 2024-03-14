require 'colorator'
require 'optparse'

VERBOSITY = %w[trace debug verbose info warning error fatal panic quiet].freeze

def help(msg = nil)
  printf "Error: #{msg}\n\n".yellow unless msg.nil?
  printf 'Commands are: flip, rotate and stabilize'
  exit 1
end

def help_show(msg = nil)
  printf "Error: #{msg}\n\n".yellow unless msg.nil?
  msg = <<~END_HELP
    show: Displays information about a Live set.

    Syntax: show PATH_TO_ALS_FILE
  END_HELP
  printf msg.cyan
  exit 1
end

def parse_options(command)
  options = option_defaults command
  opts = do_parse command
  opts.order!(into: options)

  help_stabilize "Invalid verbosity value (#{options[:verbose]}), must be one of one of: #{VERBOSITY.join ', '}." \
    if options[:verbose] && !options[:verbose] in VERBOSITY

  help_stabilize "Invalid shake value (#{options[:shake]})." \
    if command == :stabilize && (options[:shake].negative? || options[:shake] > 10)

  options
end

private

def option_defaults(_command)
  { loglevel: 'warning' }
end

def do_parse(command)
  OptionParser.new do |parser|
    parser.program_name = File.basename __FILE__
    @parser = parser

    parser.on('-s', '--show', 'Display information about the Ableton Live set')
    parser.on('-l', '--loglevel LOGLEVEL', Integer, "Logging level (#{VERBOSITY.join ', '})")
    parser.on('-v', '--verbose VERBOSE', 'Zoom percentage')

    parser.on_tail('-h', '--help', 'Show this message') do
      command == :stabilize ? help_stabilize : help_rotate
    end
  end
end
