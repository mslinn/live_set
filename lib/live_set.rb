# Require all Ruby files in 'lib/', except this file
def require_directory(dir)
  Dir[File.join(dir, '*.rb')].sort.each do |file|
    # puts "Requiring #{file}"
    require file unless file.end_with? File.basename __FILE__
  end
end

require_directory __dir__
require_directory "#{__dir__}/live_set"

def help(msg = nil)
  puts "Error: #{msg}" if msg
  puts 'List files in ableton set'
  exit 1
end

help_show if ARGV.empty?

@options = parse_options

set_name = expand_env ARGV.join(' ')
help_show "#{set_name} does not exist" unless File.exist? set_name
help_show "#{set_name} is a directory" if File.directory? set_name

live_set = LiveSet.new set_name, **@options

if @options[:convert11]
  live_set.modify_als
else
  live_set.show
end
