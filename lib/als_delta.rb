require_relative 'als_delta_options'
require_directory "#{__dir__}/common"
require_directory "#{__dir__}/als_delta"

def common(command)
  @options = parse_options command
  help_show 'Ableton Live set name must be provided.' if ARGV.empty?
end

help_show if ARGV.empty?

@options = parse_options

set_name = ARGV.join(' ').expand_env
help_show "#{set_name} does not exist" unless File.exist? set_name
help_show "#{set_name} is a directory" if File.directory? set_name

trap('SIGINT') { throw :ctrl_c }

catch :ctrl_c do
  als_delta = AlsDelta.new set_name, **@options
  als_delta.show
rescue Exception # rubocop:disable Lint/RescueException
  als_delta.cleanup
end
