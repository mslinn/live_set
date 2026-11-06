require 'colorator'
require 'optparse'
require_relative '../common/command'
require_relative '../live_set/als_file'
require_relative '../live_set/demo_sets'
require_relative '../live_set/tx/live_versions'
require_relative 'live_set_converter'

# Converts a Live set to another version of the format.
#
# The conversion is done by the bridges of the versions, which are in the `tx` subdirectory of
# the `live_set` directory, and which are composed by the registry of them. See
# docs/cpfir.md, "The Lifecycle of a Conversion", and docs/conversion.md.
class AlsToVersion
  extend Command

  # Display help message for als_to_version
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      als_to_version converts a Live set to another version of the Live format.
      If SRC is already at the version it is converted to, the program says so and stops.

      Syntax: als_to_version [OPTIONS] VERSION SRC [DST]

      Where:
        VERSION  is the Ableton Live version to be converted to, e.g. 11.
        SRC      is the path of of the set to be converted
        DST      is the optional path to write the converted set to. Without it, the
                 converted set is written to the same directory as SRC, with the version
                 as a suffix. For example, if SRC is set.als, and VERSION is 11, the default
                 destination path would be set_11.als.

      OPTIONS can be specified anywhere on the command line:
        -f    Overwrite the destination if it already exists.
        -h    Display this help message.
        #{log_level_help}

      Example:
        als_to_version 11 "$path/to/sample_set.als"  # writes to "$path/to/sample_set_11.als"
        als_to_version 12 "$path/to/sample_set.als" "live_12_test_conversion.als" -f
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # Converts a set, and writes the converted set.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Integer] the exit status of the command
  def self.run(args)
    options, remaining = parse_options(args)

    if remaining.length < 2
      warn help
      return 1
    end

    version = remaining.shift.to_i
    source = DemoSets.path_of remaining.shift
    destination = remaining.shift

    abort help("No such file: #{source}") unless File.exist?(source)

    document = AlsFile.read source
    if version_of(document) == version
      puts "The set is already a Live #{version} set."
      return 0
    end

    result = convert source, to: version, destination: destination, overwrite: options[:force]
    puts "Writing #{result.path}"
    0
  rescue LiveSetConverter::AlreadyExists => e
    puts e.message.red
    1
  end

  # The version of a set.
  #
  # @param document [Nokogiri::XML::Document] the set
  # @return [Integer] the version of Live the set is written in
  def self.version_of(document)
    LiveVersions.version_number_of document
  end

  # Converts a set, and writes the converted set.
  #
  # @param set_name [String] the path of the set to convert
  # @param to [Integer] the version of Live to convert the set to
  # @param destination [String, nil] where the converted set is written
  # @param overwrite [Boolean] whether an existing set may be overwritten
  # @return [LiveSetConverter::Result] what the conversion did
  def self.convert(set_name, to:, destination: nil, overwrite: false)
    document = AlsFile.read set_name
    return LiveSetConverter::Result.new status: :already_compatible, path: nil, overwritten: false if version_of(document) == to

    LiveSetConverter.new(set_name, document, version: to, destination: destination,
                                              overwrite: overwrite).convert
  end

  def self.parser
    OptionParser.new do |parser|
      parser.program_name = 'als_to_version'

      parser.on('-f', '--force', 'Overwrite the destination when it already exists')
      add_common_options parser

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
