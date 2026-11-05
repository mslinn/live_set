require 'bytesize'
require 'colorator'
require 'fileutils'
require 'nokogiri'
require 'pathname'
require 'time'
require 'zlib'
require_relative '../common/command'
require_relative '../common/log'
require_relative '../live_set/als_file'
require_relative '../live_set/model/als_model'
require_relative '../live_set/model/header_block'
require_relative '../live_set/model/live_scene'
require_relative '../live_set/serializer/als_model_serializer'

# See https://www.ionos.ca/digitalguide/websites/web-development/xpath-tutorial/
# See https://www.scrapingbee.com/webscraping-questions/selenium/how-to-find-elements-by-xpath-selenium
# See https://nokogiri.org/tutorials/searching_a_xml_html_document.html#slop-1

# Reports a Live set.
#
# The conversion of a set to another version of the format is the work of the
# `als_to_version` command, and this command does not do it.
class AlsReport
  extend Command

  # Report on a Live set.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Integer] the exit status of the command
  def self.run(args)
    options, remaining = parse_options(args)

    if options[:version]
      puts LiveSetVersion::VERSION
      return 0
    end

    abort help("Unknown time zone: #{options[:time_zone]}") if options[:time_zone] &&
                                                               !known_time_zone?(options[:time_zone])

    abort help('An Ableton Live set name must be provided.') if remaining.empty?

    set_name = remaining.join(' ').expand_env
    abort help("#{set_name} does not exist") unless File.exist? set_name
    abort help("#{set_name} is a directory") if File.directory? set_name

    puts new(set_name, **options).show
    0
  end

  def initialize(set_name, **options)
    # Can set with a string ('WARN') or an int (Logger::WARN is 2)
    Log.level = options[:loglevel] || Logger::WARN

    @set_directory = File.dirname(File.realpath(set_name))

    @set_name = set_name

    @contents = AlsFile.read_text(set_name)

    @xml_doc = Nokogiri::Slop @contents

    @ableton = @xml_doc.Ableton

    @live_set = @ableton.LiveSet

    # A set of Live 8 or Live 9 has no scenes at all.
    scenes = @live_set.at('Scenes')
    @scenes = scenes ? scenes.map { |scene| LiveScene.new scene } : []
    @time_zone = options[:time_zone]
    @show_midi_and_audio_tracks_separately = options[:show_midi_and_audio_tracks_separately]
  end

  # Generates the complete report for a Live set.
  #
  # The report is generated in markdown format. It is written to stdout, and the log is written to stderr.
  #
  # The report is the model of the set written as markdown: the model holds the facts, and the serializer of the model
  # writes them.
  #
  # @return [String] the report
  def show
    check_ableton_project_info
    AlsModelSerializer.new(als_model).to_markdown
  end

  # The model of the set.
  #
  # Every XML element of the set shall be stored in the model: groups, MIDI tracks, audio tracks, return tracks, etc.,
  # in the order Live wrote them.
  #
  # @return [AlsModel] the model
  def als_model
    @als_model ||= begin
      header = HeaderBlock.new @set_name, @xml_doc, @time_zone
      AlsModel.new @set_name, @xml_doc, header,
                   show_midi_and_audio_tracks_separately: @show_midi_and_audio_tracks_separately
    end
  end
end
