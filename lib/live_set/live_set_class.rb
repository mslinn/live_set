require 'bytesize'
require 'colorator'
require 'fileutils'
require 'nokogiri'
require 'pathname'
require 'zlib'
require_relative '../common/log'

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

    @contents = Zlib::GzipReader.open(set_name, &:read)

    @xml_doc = Nokogiri::Slop @contents

    @ableton = @xml_doc.Ableton
    @minor_version = @ableton['MinorVersion']

    @live_set = @ableton.LiveSet

    # Get AudioTrack elements safely - returns empty NodeSet if none exist
    #
    # Only the tracks that play clips are reported. A group track is a summing container and
    # holds no clips, so it is not one of these. See docs/als_format.md section 9.1.
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
    # chain, so its devices are checked. See docs/als_format.md section 9.
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
  # The version strings below are the Live 11.3.21 schema, and they are fixed rather than
  # configurable. A user can ask for "Live 11 format", but cannot ask for a particular
  # sub-version, so every set this command writes uses the same schema.
  def modify_als
    if @minor_version.start_with? '11.'
      puts 'The Live set is already compatible with Live 11.'.yellow
      exit 0
    end

    @ableton['Creator'] = 'Ableton Live 11.3.21'
    @ableton['MajorVersion'] = '5'
    @ableton['MinorVersion'] = '11.0_11300'
    @ableton['Revision'] = '5ac24cad7c51ea0671d49e6b4885371f15b57c1e'
    @ableton['SchemaChangeCount'] = '3'

    # These are Live 12 constructs that Live 11 does not have. Group tracks are not among them:
    # Live 11 has group tracks, so they are kept. See docs/als_format.md section 9.2.
    #
    # The conversion is a selective removal, not a rewrite. Anything else in the document —
    # including an element this list has never heard of — is copied through unchanged. See
    # docs/als_format.md section 2.2.
    ['//ContentLanes', '//ExpressionLanes', '//InstrumentMeld', '//Roar', '//MxPatchRef', '//Oversampling'].each do |element|
      count = @xml_doc.xpath(element).length
      @xml_doc.xpath(element).remove
      Log.debug "Removed #{count} element(s) matching #{element}" if count.positive?
    end

    new_contents = @xml_doc.to_xml.to_s
    new_contents.gsub! 'AudioOut/Main', 'AudioOut/Master'

    set_path = File.dirname @set_name
    new_set_name = File.basename @set_name, '.als'
    new_set_path = File.join set_path, "#{new_set_name}_11.als"

    if @overwrite
      puts "Overwriting existing #{new_set_path}".green
      FileUtils.rm_f new_set_path
    else
      puts "Writing #{new_set_path}".green
    end

    Zlib::GzipWriter.open(new_set_path) { |gz| gz.write new_contents }
    puts 'Conversion complete'.green
  end
end
