require_relative 'live_set/live_set_options'
require_relative 'common/util'
require_directory "#{__dir__}/common"

def common(command)
  @options = parse_options command
  help_live_set 'Ableton Live set name must be provided.' if ARGV.empty?
end

def als_delta
  require_directory "#{__dir__}/als_delta"

  help_als_delta if ARGV.empty?

  @options = parse_options

  set_name = ARGV.join(' ').expand_env
  help_als_delta "#{set_name} does not exist" unless File.exist? set_name
  help_als_delta "#{set_name} is a directory" if File.directory? set_name

  trap('SIGINT') { throw :ctrl_c }

  als_delta = AlsDelta.new set_name, **@options
  catch :ctrl_c do
    als_delta.show
    als_delta.cleanup
  rescue Exception # rubocop:disable Lint/RescueException
    als_delta.cleanup
  end
end

def live_set
  require_directory "#{__dir__}/live_set"

  help_live_set if ARGV.empty?

  @options = parse_options

  set_name = ARGV.join(' ').expand_env
  help_live_set "#{set_name} does not exist" unless File.exist? set_name
  help_live_set "#{set_name} is a directory" if File.directory? set_name

  live_set = LiveSet.new set_name, **@options

  if @options[:convert11]
    live_set.modify_als
  else
    live_set.show
  end
end
