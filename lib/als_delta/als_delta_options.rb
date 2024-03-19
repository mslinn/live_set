require 'colorator'
require 'optparse'

VERBOSITY = %w[trace debug verbose info warning error fatal panic quiet].freeze

def help_show(msg = nil)
  printf "Error: #{msg}\n\n".yellow unless msg.nil?
  msg = <<~END_HELP
    ls_delta: Shows changes to .als file.
    Press enter to compare with previous version.

    Syntax: ls_delta OPTIONS PATH_TO_ALS_FILE

    Environment variables used in PATH_TO_ALS_FILE are expanded.

    Options are:
      -h Display this help message.

    Example:
    ls_delta $path/to/my_v12_set.als
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

    parser.on('-l', '--loglevel LOGLEVEL', Integer, "Logging level (#{VERBOSITY.join ', '})")
    parser.on('-v', '--verbose VERBOSE', 'Zoom percentage')

    parser.on_tail('-h', '--help', 'Show this message') do
      help_show
    end
  end
end