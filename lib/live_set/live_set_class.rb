require 'bytesize'
require 'colorator'
require 'fileutils'
require 'nokogiri'
require 'pathname'
require 'zlib'
require_relative '../common/log'
require_relative 'als_file'

# See https://www.ionos.ca/digitalguide/websites/web-development/xpath-tutorial/
# See https://www.scrapingbee.com/webscraping-questions/selenium/how-to-find-elements-by-xpath-selenium
# See https://nokogiri.org/tutorials/searching_a_xml_html_document.html#slop-1

class LiveSet
  # Report on a Live set, or convert it to the Live 11 format.
  #
  # @param args [Array<String>] the command line arguments
  # @return [void]
  def self.run(args)
    options, remaining = parse_options(args)

    abort help('An Ableton Live set name must be provided.') if remaining.empty?

    set_name = remaining.join(' ').expand_env
    abort help("#{set_name} does not exist") unless File.exist? set_name
    abort help("#{set_name} is a directory") if File.directory? set_name

    live_set = new set_name, **options

    if options[:convert11]
      live_set.modify_als
    else
      live_set.show
    end
  end

  def initialize(set_name, **options)
    # Can set with a string ('WARN') or an int (Logger::WARN is 2)
    Log.level = options[:loglevel] || Logger::WARN

    @set_directory = File.dirname(File.realpath(set_name))

    @overwrite = options[:force]
    @set_name = set_name

    @contents = AlsFile.read_text(set_name)

    @xml_doc = Nokogiri::Slop @contents

    @ableton = @xml_doc.Ableton
    @minor_version = @ableton['MinorVersion']

    @live_set = @ableton.LiveSet

    # Get AudioTrack elements safely - returns empty NodeSet if none exist
    #
    # Only the tracks that play clips are reported. A group track is a summing container and
    # holds no clips, so it is not one of these. See docs/als_notes.md, "A group track holds no
    # clips".
    audio_tracks = begin
      # Use XPath directly on the document to avoid Slop method_missing issues
      result = @xml_doc.xpath('//AudioTrack')
      result
    rescue StandardError => e
      puts "Error accessing AudioTrack elements: #{e.message}".red
      []
    end

    # A group track is a summing container, not a track that plays clips. It holds no clips, so it
    # is not reported alongside the tracks, but its members' audio is routed through its device
    # chain, so its devices are checked. See docs/als_notes.md, "The group tracks".
    group_tracks = @xml_doc.xpath('//GroupTrack')

    @tracks = LiveTracks.new @set_directory, audio_tracks, group_tracks
    @scenes = @live_set.Scenes.map { |scene| LiveScene.new scene }
  end

  # @return multiline string containing Live session metadata
  def show
    check_ableton_project_info
    puts <<~END_SHOW
      #{@set_name}
        Created by #{@ableton['Creator']}
        Major version #{@ableton['MajorVersion']}
        Minor version v#{@minor_version}
        SchemaChangeCount #{@ableton['SchemaChangeCount']}
        Revision #{@ableton['Revision']}
      #{@tracks.message}
    END_SHOW
  end

  # Writes out a Live 11 session
  #
  # The conversion itself is done by LiveSetConverter.
  def modify_als
    if @minor_version.start_with? '11.'
      puts 'The Live set is already compatible with Live 11.'.yellow
      exit 0
    end

    LiveSetConverter.new(@set_name, @xml_doc, overwrite: @overwrite).convert
  end
end
