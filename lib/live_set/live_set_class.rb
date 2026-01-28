require 'bytesize'
require 'nokogiri'
require 'pathname'
require 'zlib'

# See https://www.ionos.ca/digitalguide/websites/web-development/xpath-tutorial/
# See https://www.scrapingbee.com/webscraping-questions/selenium/how-to-find-elements-by-xpath-selenium
# See https://nokogiri.org/tutorials/searching_a_xml_html_document.html#slop-1

class LiveSet
  VERBOSITY_LEVELS = %w[trace debug verbose info warning error fatal panic quiet].freeze

  def initialize(set_name, **options)
    @loglevel = options[:loglevel] || 'warning'
    @debug_enabled = debug_level?('debug')
    @verbose_enabled = debug_level?('verbose')
    @trace_enabled = debug_level?('trace')

    debug "Initializing LiveSet for: #{set_name}"
    debug "Log level: #{@loglevel}"

    @set_directory = File.dirname(File.realpath(set_name))
    debug "Set directory: #{@set_directory}"

    @overwrite = options[:force]
    @set_name = set_name

    debug "Reading ALS file..."
    @contents = Zlib::GzipReader.open(set_name, &:readlines)
    debug "File read, #{@contents.length} lines"

    debug "Parsing XML..."
    @xml_doc = Nokogiri::Slop @contents.join("\n")
    debug "XML parsed successfully"

    @ableton = @xml_doc.Ableton
    @minor_version = @ableton['MinorVersion']
    debug "Ableton version: #{@ableton['MajorVersion']}.#{@minor_version}"
    debug "Creator: #{@ableton['Creator']}"
    debug "SchemaChangeCount: #{@ableton['SchemaChangeCount']}"

    @live_set = @ableton.LiveSet
    debug "LiveSet element found"

    # Get AudioTrack elements safely - returns empty NodeSet if none exist
    debug "Searching for AudioTrack elements..."
    audio_tracks = begin
                     # Use XPath directly on the document to avoid Slop method_missing issues
                     result = @xml_doc.xpath('//AudioTrack')
                     debug "Found #{result.length} AudioTrack element(s)"
                     result
                   rescue StandardError => e
                     debug "Error accessing AudioTrack elements: #{e.message}"
                     []
                   end
    @tracks = AllTracks.new @set_directory, audio_tracks
    debug "AllTracks initialized with #{audio_tracks.length} track(s)"

    debug "Processing scenes..."
    @scenes = @live_set.Scenes.map { |scene| LiveScene.new scene }
    debug "Found #{@scenes.length} scene(s)"
    verbose "Initialization complete"
  end

  def show
    debug "Starting show method"
    check_abelton_project_info
    debug "Project info checked"
    debug "Generating output..."
    puts <<~END_SHOW
      #{@set_name}
        Created by #{@ableton['Creator']}
        Major version #{@ableton['MajorVersion']}
        Minor version v#{@minor_version}
        SchemaChangeCount #{@ableton['SchemaChangeCount']}
        Revision #{@ableton['Revision']}
      #{@tracks.message}
    END_SHOW
    debug "Show method complete"
  end

  def modify_als
    debug "Starting modify_als method"
    if @minor_version.start_with? '11.'
      debug "Set is already Live 11 compatible"
      puts 'The Live set is already compatible with Live 11.'
      exit
    end

    debug "Converting Live 12 set to Live 11 format"
    @ableton['Creator'] = 'Ableton Live 11.3.21'
    @ableton['MajorVersion'] = '5'
    @ableton['MinorVersion'] = '11.0_11300'
    @ableton['Revision'] = '5ac24cad7c51ea0671d49e6b4885371f15b57c1e'
    @ableton['SchemaChangeCount'] = '3'
    debug "Updated Ableton version attributes"

    debug "Removing Live 12 specific elements..."
    ['//ContentLanes', '//ExpressionLanes', '//InstrumentMeld', '//Roar', '//MxPatchRef', '//Oversampling'].each do |element|
      count = @xml_doc.xpath(element).length
      @xml_doc.xpath(element).remove
      debug "Removed #{count} element(s) matching #{element}" if count > 0
    end

    debug "Converting XML to string..."
    new_contents = @xml_doc.to_xml.to_s
    debug "Replacing AudioOut/Main with AudioOut/Master..."
    new_contents.gsub! 'AudioOut/Main', 'AudioOut/Master'
    debug "Replacement complete"

    set_path = File.dirname @set_name
    new_set_name = File.basename @set_name, '.als'
    new_set_path = File.join set_path, "#{new_set_name}_11.als"
    debug "Output path: #{new_set_path}"

    if @overwrite
      puts "Overwriting existing #{new_set_path}"
      File.delete new_set_path if File.exist?(new_set_path)
      debug "Deleted existing file"
    else
      puts "Writing #{new_set_path}"
    end

    debug "Writing compressed ALS file..."
    Zlib::GzipWriter.open(new_set_path) { |gz| gz.write new_contents }
    debug "File written successfully: #{new_set_path}"
    verbose "Conversion complete"
  end

  private

  def debug_level?(level)
    return false if @loglevel == 'quiet'
    return true if @loglevel == level

    current_index = VERBOSITY_LEVELS.index(@loglevel.to_s)
    level_index = VERBOSITY_LEVELS.index(level.to_s)
    return false if current_index.nil? || level_index.nil?

    # Lower index = more verbose (trace=0, quiet=7)
    current_index <= level_index
  end

  def debug(msg)
    return unless @debug_enabled || @trace_enabled

    puts "[DEBUG] #{msg}"
  end

  def verbose(msg)
    return unless @verbose_enabled || @trace_enabled

    puts "[VERBOSE] #{msg}"
  end

  def trace(msg)
    return unless @trace_enabled

    puts "[TRACE] #{msg}"
  end
end
