require 'colorator'
require 'optparse'

VERBOSITY = %w[trace debug verbose info warning error fatal panic quiet].freeze unless defined? VERBOSITY

def live_set(msg = nil)
  printf "Error: #{msg}\n\n".yellow unless msg.nil?
  msg = <<~END_HELP
    Live_sete displays information about an Ableton Live set or converts a Live 12 set to Live 11 format.
    If the special folder called 'Ableton Project Info' is not present in the same folder as the .als file, a warning is generated.
    Similarly, if 'Ableton Project Info' is present in any parent folder, a warning is issued.

    Syntax: live_set OPTIONS PATH_TO_ALS_FILE

    Environment variables used in PATH_TO_ALS_FILE are expanded.

    Options are:
      -11 Convert the Live 12 set to Live 11 format.
      -f If -11 is specified, overwrite any existing Live 11 set.
      -h Display this help message.

    Example:
      live_set -11 -f $path/to/my_v12_set.als
  END_HELP
  printf msg.cyan
  exit 1
end

def parse_options
  options = { loglevel: 'warning' }
  opts = do_parse
  opts.order!(into: options)

  live_set "Invalid verbosity value (#{options[:verbose]}), must be one of one of: #{VERBOSITY.join ', '}." \
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
    parser.on('-v', '--verbose VERBOSE', 'Verbosity')

    parser.on_tail('-h', '--help', 'Show this message') do
      live_set
    end
  end
end
