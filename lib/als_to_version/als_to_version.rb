require 'colorator'
require 'optparse'
require_relative '../live_set/als_file'
require_relative '../live_set/demo_sets'
require_relative '../live_set/live_set_converter'
require_relative '../live_set/live_set_transformer'

# Converts a Live set to another version of the format.
#
# The conversion is done by the bridges of the versions, which are in the `tx` subdirectory of
# the `live_set` directory, and which are composed by the registry of them. See
# docs/cpfir.md, "The Lifecycle of a Conversion", and docs/conversion.md.
class AlsToVersion
  # Display help message for als_to_version
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      Als_to_version converts a Live set to another version of the Live format.

      The direction of the conversion is given: the set is converted to the version named on
      the command line. The set is written the way Live writes it, so that the converted set is
      a set of that version and not merely XML that happens to mean the same thing.

      Syntax: als_to_version [-f] VERSION SRC [DST]

      VERSION is the Ableton Live version to be converted to, e.g. 11.
      SRC is the set to convert: the path of the file, or a selector of a demo set, e.g.
        demo:11:suite  the Live 11 Suite demo set
        demo:12        the demo set of Live 12
      DST is where the converted set is written. Without it, the set is written next to the set
      that was converted, with the version as a suffix, e.g. set_11.als.

      Options are:
        -f Overwrite the destination when it already exists.
        -h Display this help message.

      If SRC is already at the version it is converted to, the program says so and stops.

      Example:
        als_to_version 11 $path/to/my_v12_set.als
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
    LiveSetTransformer.version_of(document).split('.').first.to_i
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

  # Parse the options of the command.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Array(Hash, Array<String>)] the options and the remaining arguments
  def self.parse_options(args)
    options = {}
    remaining = do_parse.order!(args, into: options)
    [options, remaining]
  end

  def self.do_parse
    OptionParser.new do |parser|
      parser.program_name = 'als_to_version'

      parser.on('-f', '--force', 'Overwrite the destination when it already exists')

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
