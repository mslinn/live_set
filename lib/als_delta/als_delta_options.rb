require 'colorator'
require 'optparse'

VERBOSITY = %w[trace debug verbose info warning error fatal panic quiet].freeze

def common(command)
  @options = parse_options command
  help_als_delta 'Ableton Live set name must be provided.' if ARGV.empty?
end

def help_als_delta(msg = nil)
  printf "Error: #{msg}\n\n".yellow unless msg.nil?
  msg = <<~END_HELP
    ls_delta: Shows changes to .als file.
    Press enter to compare with previous version.

    Syntax: ls_delta OPTIONS PATH_TO_ALS_FILE

    Environment variables used in PATH_TO_ALS_FILE are expanded.

    Options are:
      -k Keep each backup (default is to delete them)
      -h Display this help message.

    Example:
    ls_delta $path/to/my_v12_set.als
  END_HELP
  printf msg.cyan
  exit 1
end

def parse_options
  options = { keep: false, loglevel: 'warning' }
  opts = do_parse
  opts.order!(into: options)

  help_als_delta "Invalid verbosity value (#{options[:verbose]}), must be one of one of: #{VERBOSITY.join ', '}." \
    if options[:verbose] && !options[:verbose] in VERBOSITY

  options
end

private

def do_parse
  OptionParser.new do |parser|
    parser.program_name = File.basename __FILE__
    @parser = parser

    parser.on('-k', '--keep', 'Keep all backups')
    parser.on('-l', '--loglevel LOGLEVEL', Integer, "Logging level (#{VERBOSITY.join ', '})")
    parser.on('-v', '--verbose VERBOSE', 'Verbosity')

    parser.on_tail('-h', '--help', 'Show this message') do
      help_als_delta
    end
  end
end
