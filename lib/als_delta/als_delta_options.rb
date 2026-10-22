require 'colorator'
require 'logger'
require 'optparse'

@loglevels = Logger::Severity.constants.sort_by { |name| Logger::Severity.const_get(name) } unless defined?(@loglevels)

def common(command)
  @options = parse_options command
  help_als_delta 'An Ableton Live set name must be provided.' if ARGV.empty?
end

def help_als_delta(msg = nil)
  printf "Error: #{msg}\n\n".yellow unless msg.nil?
  msg = <<~END_HELP
    als_delta: Shows changes to an .als file each time a session file is saved.
    Press any key to compare with previous version.

    Syntax: als_delta OPTIONS PATH_TO_ALS_FILE

    Environment variables used in PATH_TO_ALS_FILE are expanded.

    Options are:
      -k Keep each backup (default is to delete them)
      -h Display this help message.

    Example (references an environment variable called `path`):
    als_delta $path/to/my_v12_set.als
  END_HELP
  printf msg.cyan
  exit 1
end

def parse_options
  options = { keep: false, loglevel: 'WARN' }
  opts = do_parse
  opts.order!(into: options)

  # Normalize loglevel to uppercase string
  options[:loglevel] = options[:loglevel].to_s.upcase if options[:loglevel]
  @loglevel = options[:loglevel]

  msg = "Invalid verbosity value (#{@loglevel}), must be one of one of: #{@loglevels.join ', '}."
  help_als_delta msg if @loglevel && !@loglevels.include?(@loglevel.upcase.to_sym)

  options
end

def do_parse
  OptionParser.new do |parser|
    parser.program_name = File.basename __FILE__
    @parser = parser

    parser.on('-k', '--keep', 'Keep all backups')
    parser.on('-l', '--loglevel LOGLEVEL', Integer, "Log level (#{@loglevels.join ', '})")
    parser.on_tail('-h', '--help', 'Show this message') do
      help_als_delta
    end
  end
end
