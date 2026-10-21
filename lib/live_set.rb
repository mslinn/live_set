require 'colorator'
require_relative 'common/util'
require_relative 'live_set/live_set_options'
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

def generate_xsd
  require_directory "#{__dir__}/generate_xsd"

  help_generate_xsd if ARGV.empty?

  @options = parse_options

  @als_files = @als_files.map do |file|
    expanded_file = file.expand_env
    help_generate_xsd("ALS file does not exist: #{expanded_file}") unless File.exist?(expanded_file)
    help_generate_xsd "#{expanded_file} is a directory" if File.directory? expanded_file
    expanded_file
  end

  trap('SIGINT') { throw :ctrl_c }

  generate_xsd = XsdFromXml.new @xsd_file, @als_files, **@options
  catch :ctrl_c do
    content = generate_xsd.generate
    File.write(@xsd_file, content)
    puts "Wrote '#{File.expand_path @xsd_file}'".green
  rescue Exception => e # rubocop:disable Lint/RescueException
    puts e.full_message
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
