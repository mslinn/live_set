require 'colorator'
require 'logger'

unless Object.const_defined?(:Log, false)
  Log = Logger.new($stdout)
  Log.level = Logger::WARN # Can set with a string ('WARN') or an int (Logger::WARN is 2)
  Log.formatter = proc do |severity, _time, _progname, message|
    line = "[#{severity}] #{message}\n"

    case severity
    when 'WARN'
      line.yellow
    when 'FATAL' || 'UNKNOWN'
      line.red
    else
      line.green
    end
  end
end
