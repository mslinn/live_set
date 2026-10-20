require 'bytesize'
require 'colorator'
require 'nokogiri'
require 'pathname'
require 'zlib'

# See https://www.ionos.ca/digitalguide/websites/web-development/xpath-tutorial/
# See https://www.scrapingbee.com/webscraping-questions/selenium/how-to-find-elements-by-xpath-selenium
# See https://nokogiri.org/tutorials/searching_a_xml_html_document.html#slop-1

class LiveSet
  def initialize(set_name, **options)
    # Can set with a string ('WARN') or an int (Logger::WARN is 2)
    Log.level = options[:loglevel] || Logger::WARN

    @set_directory = File.dirname(File.realpath(set_name))

    @overwrite = options[:force]
    @set_name = set_name

    @contents = Zlib::GzipReader.open(set_name, &:readlines)

    @xml_doc = Nokogiri::Slop @contents.join("\n")

    @ableton = @xml_doc.Ableton
    @minor_version = @ableton['MinorVersion']

    puts <<~TEXT
      Ableton version: #{@ableton['MajorVersion']}.#{@minor_version}
      Creator: #{@ableton['Creator']}
      SchemaChangeCount: #{@ableton['SchemaChangeCount']}
    TEXT

    @live_set = @ableton.LiveSet

    # Get AudioTrack elements safely - returns empty NodeSet if none exist
    audio_tracks = begin
      # Use XPath directly on the document to avoid Slop method_missing issues
      result = @xml_doc.xpath('//AudioTrack')
      result
    rescue StandardError => e
      puts "Error accessing AudioTrack elements: #{e.message}".red
      []
    end
    @tracks = AllTracks.new @set_directory, audio_tracks
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
  def modify_als
    if @minor_version.start_with? '11.'
      puts 'The Live set is already compatible with Live 11.'.yellow
      exit
    end

    @ableton['Creator'] = 'Ableton Live 11.3.21'
    @ableton['MajorVersion'] = '5'
    @ableton['MinorVersion'] = '11.0_11300'
    @ableton['Revision'] = '5ac24cad7c51ea0671d49e6b4885371f15b57c1e'
    @ableton['SchemaChangeCount'] = '3'

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
