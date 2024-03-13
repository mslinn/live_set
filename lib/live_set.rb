require 'nokogiri'
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

contents = Zlib::GzipReader.open(set_name, &:readlines)
xml_doc = Nokogiri::Slop contents.join("\n")

ableton = xml_doc.Ableton
minor_version = ableton['MinorVersion']

puts "Version was #{minor_version}"

ableton['Creator'] = 'Ableton Live 11.3.21'
ableton['MajorVersion'] = '5'
ableton['MinorVersion'] = '11.0_11300'
ableton['Revision'] = '5ac24cad7c51ea0671d49e6b4885371f15b57c1e'
ableton['SchemaChangeCount'] = '3'
