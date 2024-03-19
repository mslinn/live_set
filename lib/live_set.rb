require_relative 'live_set_options'
require_directory "#{__dir__}/common"
require_directory "#{__dir__}/live_set"

def common(command)
  @options = parse_options command
  help_show 'Ableton Live set name must be provided.' if ARGV.empty?
end

help_show if ARGV.empty?

@options = parse_options

set_name = ARGV.join(' ').expand_env
help_show "#{set_name} does not exist" unless File.exist? set_name
help_show "#{set_name} is a directory" if File.directory? set_name

live_set = LiveSet.new set_name, **@options

if @options[:convert11]
  live_set.modify_als
else
  live_set.show
end
