require 'zlib'
require_relative 'live_set/version'

# Require all Ruby files in 'lib/', except this file
Dir[File.join(__dir__, '*.rb')].sort.each do |file|
  require file unless file.end_with?('/live_set.rb')
end

def help(msg = nil)
  puts "Error: #{msg}" if msg
  puts 'List files in ableton set'
  exit 1
end

help if ARGV.empty?

set_name = ARGV.join ' '
help "#{set_name} does not exist" unless File.exist? set_name
help "#{set_name} is a directory" if File.directory? set_name

contents = Zlib::GzipReader.open(set_name) { |gz| gz.readlines }
xml_header = puts contents[1]
puts xml_header
