require 'colorator'
require 'logger'

# The valid logging levels, in increasing order of severity.
LOG_LEVELS = Logger::Severity.constants.sort_by { |name| Logger::Severity.const_get(name) }.freeze

# Define singleton for logging. Logs are color-coded by severity.
#
# The log goes to stderr, so that the output a program writes to stdout is only what the program
# was asked to produce.
unless Object.const_defined?(:Log, false)
  Log = Logger.new($stderr)
  Log.level = Logger::WARN # Can set with a string ('WARN') or an int (Logger::WARN is 2)
  Log.formatter = proc do |severity, _time, _progname, message|
    line = "[#{severity}] #{message}\n"

    case severity
    when 'WARN'
      line.yellow
    when 'FATAL', 'UNKNOWN'
      line.red
    else
      line.green
    end
  end
end
