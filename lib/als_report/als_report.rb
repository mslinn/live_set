require 'bytesize'
require 'colorator'
require 'fileutils'
require 'nokogiri'
require 'pathname'
require 'time'
require 'zlib'
require_relative '../common/command'
require_relative '../common/log'
require_relative '../common/util'
require_relative '../live_set/als_file'
require_relative '../live_set/model/als_model'
require_relative '../live_set/model/header_block'
require_relative '../live_set/model/live_scene'
require_relative '../live_set/report_context'
require_relative '../live_set/serializer/als_model_serializer'
require_relative '../live_set/serializer/live_project_serializer'
require_relative 'als_report_options'
require_relative 'als_report_private'

# See https://www.ionos.ca/digitalguide/websites/web-development/xpath-tutorial/
# See https://www.scrapingbee.com/webscraping-questions/selenium/how-to-find-elements-by-xpath-selenium
# See https://nokogiri.org/tutorials/searching_a_xml_html_document.html#slop-1

# Reports a Live set.
#
# The conversion of a set to another version of the format is the work of the
# `als_to_version` command, and this command does not do it.
class AlsReport
  extend Command

  # Report on a Live set, or on the sets of a Live project.
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

    abort help('A path must be provided.') if remaining.empty?

    path = remaining.join(' ').expand_env
    abort help("#{path} does not exist") unless File.exist? path

    return report_project(path, options) if File.directory? path

    report_set path, options
  end

  # Reports a set.
  #
  # @param path [String] the path of the set
  # @param options [Hash] the options
  # @return [Integer] the exit status of the command
  def self.report_set(path, options)
    context = ReportContext.new machine: options[:report_machine]
    puts new(path, **options, context: context).show
    0
  end

  # Reports the sets of a project.
  #
  # @param path [String] the path of the project
  # @param options [Hash] the options
  # @return [Integer] the exit status of the command
  def self.report_project(path, options)
    sets = sets_of path, options[:als]
    missing = options[:als].reject { |name| sets.any? { |set| named? set, path, name } }
    abort help("No set named #{missing.join ', '} was found in #{path}") unless missing.empty?
    abort help("No set was found in #{path}") if sets.empty?

    context = ReportContext.new project_path: path, machine: options[:report_machine], sets: sets.length
    models = sets.map { |set| new(set, **options, context: context).als_model }
    puts LiveProjectSerializer.new(path, models, context).to_markdown
    0
  end

  # The sets of a project.
  #
  # The sets of a project are the `.als` files it holds. The names are the sets to report:
  # each of them is the name of a file in the project, or the path of one relative to the
  # project.
  #
  # @param path [String] the path of the project
  # @param names [Array<String>] the names of the sets to report, empty for all of them
  # @return [Array<String>] the paths of the sets
  def self.sets_of(path, names)
    sets = Dir.glob(File.join(path, '**', '*.als')).reject { |set| in_samples? set }.sort
    return sets if names.empty?

    sets.select { |set| names.any? { |name| named? set, path, name } }
  end

  # Whether a name is the set.
  #
  # @param set [String] the path of the set
  # @param project [String] the path of the project
  # @param name [String] the name of the set
  # @return [Boolean] true when the name is the set
  def self.named?(set, project, name)
    relative = set.delete_prefix("#{project}#{File::SEPARATOR}")
    relative == name || File.basename(set) == name
  end

  # Whether a set is in a folder of samples, which holds audio and not sets.
  #
  # @param set [String] the path of the set
  # @return [Boolean] true when the set is in a folder of samples
  def self.in_samples?(set)
    set.split(File::SEPARATOR).include? 'Samples'
  end

  def initialize(set_name, context: ReportContext.new, **options)
    @set_directory = File.dirname(File.realpath(set_name))

    @set_name = set_name

    @context = context

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
      separate = @show_midi_and_audio_tracks_separately
      AlsModel.new @set_name, @xml_doc, header, context: @context, show_midi_and_audio_tracks_separately: separate
    end
  end
end
