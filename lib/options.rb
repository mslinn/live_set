require 'colorator'
require 'optparse'

VERBOSITY = %w[trace debug verbose info warning error fatal panic quiet].freeze

def help_show(msg = nil)
  printf "Error: #{msg}\n\n".yellow unless msg.nil?
  msg = <<~END_HELP
    show: Displays information about a Live set.

    Syntax: live_set PATH_TO_ALS_FILE
  END_HELP
  printf msg.cyan
  exit 1
end

def parse_options
  options = { loglevel: 'warning' }
  opts = do_parse
  opts.order!(into: options)

  help_show "Invalid verbosity value (#{options[:verbose]}), must be one of one of: #{VERBOSITY.join ', '}." \
    if options[:verbose] && !options[:verbose] in VERBOSITY

  options
end


private

def do_parse
  OptionParser.new do |parser|
    parser.program_name = File.basename __FILE__
    @parser = parser

    parser.on('-11', '--convert11', 'Make a copy of the set that is compatible with Live 11')
    parser.on('-f', '--force', 'Overwrite the output set if it already exists')
    parser.on('-s', '--show', 'Display information about the Ableton Live set')
    parser.on('-l', '--loglevel LOGLEVEL', Integer, "Logging level (#{VERBOSITY.join ', '})")
    parser.on('-v', '--verbose VERBOSE', 'Zoom percentage')

    parser.on_tail('-h', '--help', 'Show this message') do
      help_show
    end
  end
end
