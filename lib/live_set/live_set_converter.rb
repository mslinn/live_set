require 'colorator'
require_relative '../common/log'
require_relative 'als_file'
require_relative 'live_set_transformer'
require_relative 'tx/live_versions'

# Converts a Live set to another version of the format.
#
# The conversion itself is done by the bridges of the versions, which the registry of them
# composes. This class reads the set, hands the document to the registry, and writes the result.
#
# See docs/live_11_12_diff.md for the differences between the versions, and docs/cpfir.md,
# "The Lifecycle of a Conversion", for the architecture.
class LiveSetConverter
  # The error raised when the set the conversion would write is already there, and the user did
  # not ask for it to be overwritten.
  class AlreadyExists < StandardError
    # @return [String] the path of the set that is already there
    attr_reader :path

    # @param path [String] the path of the set that is already there
    def initialize(path)
      @path = path
      super("Error: #{path} already exists. Use -f to overwrite it.")
    end
  end

  # The outcome of a conversion.
  #
  # @!attribute status
  #   @return [Symbol] :converted when a set was written
  # @!attribute path
  #   @return [String, nil] the path of the set that was written
  # @!attribute overwritten
  #   @return [Boolean] whether the set that was written was already there
  Result = Struct.new(:status, :path, :overwritten, keyword_init: true)

  # @param set_name [String] the path of the set to convert
  # @param xml_doc [Nokogiri::XML::Document] the set to convert
  # @param version [Integer] the version of Live to convert the set to
  # @param destination [String, nil] where the converted set is written
  # @param overwrite [Boolean] whether an existing converted set may be overwritten
  def initialize(set_name, xml_doc, version: 11, destination: nil, overwrite: false)
    @set_name = set_name
    @xml_doc = xml_doc
    @version = version
    @destination = destination
    @overwrite = overwrite
  end

  # Converts the set, and writes the converted set next to the set that was converted.
  #
  # @return [Result] what the conversion did
  # @raise [AlreadyExists] when the set is already there and may not be overwritten
  def convert
    document = transform
    path = converted_path
    overwritten = File.exist? path
    raise AlreadyExists, path if overwritten && !@overwrite

    # The set is written the way Live writes it, so that the converted set is a set of the
    # version it was converted to, and not merely XML that happens to mean the same thing.
    AlsFile.write(path, document, File.mtime(@set_name))
    Result.new status: :converted, path: path, overwritten: overwritten
  end

  # The path of the set the conversion writes.
  #
  # The converted set is written where it was asked for, and otherwise next to the set that was
  # converted.
  #
  # @return [String] the path of the converted set
  def converted_path
    return @destination unless @destination.nil?

    set_path = File.dirname @set_name
    new_set_name = File.basename @set_name, '.als'
    File.join set_path, "#{new_set_name}_#{@version}.als"
  end

  private

  # Converts the set.
  #
  # @return [Nokogiri::XML::Document] the converted set
  def transform
    from = LiveSetTransformer.version_of(@xml_doc).split('.').first.to_i
    LiveVersions.convert(@xml_doc, from: from, to: @version)
  end
end
