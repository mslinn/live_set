require 'colorator'
require_relative '../common/command'
require_relative '../live_set/als_file'
require_relative '../live_set/demo_sets'
require_relative '../live_set/tx/live_versions'
require_relative 'als_to_version_options'
require_relative 'live_set_converter'

# Converts a Live set to another version of the format.
#
# The conversion is done by the bridges of the versions, which are in the `tx` subdirectory of
# the `live_set` directory, and which are composed by the registry of them. See
# docs/cpfir.md, "The Lifecycle of a Conversion", and docs/conversion.md.
class AlsToVersion
  extend Command

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
end
