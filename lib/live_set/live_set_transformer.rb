require 'nokogiri'
require_relative 'tx/live_11_and_12'
require_relative 'tx/live_version_converter'

# Converts a live set to another version of the Live format.
#
# A bridge converts between two versions of the format, and it handles moving both ways: the
# direction is not passed in. The bridge reads the version of the document it is handed, and
# converts to the other version of its pair.
#
# The bridges are in the tx subdirectory of this directory, one for each pair of versions.
class LiveSetTransformer
  # The bridges, each of which converts between two versions of the format.
  BRIDGES = [Live11And12].freeze

  # The bridge that converts a document.
  #
  # @param document [Nokogiri::XML::Document] the document to convert
  # @return [Class] the bridge
  # @raise [ArgumentError] when no bridge converts the document
  def self.bridge_for(document)
    version = version_of(document)
    bridge = BRIDGES.find { |candidate| candidate.versions.include?(version) }
    raise ArgumentError, "no bridge converts a set of version #{version.inspect}" if bridge.nil?

    bridge
  end

  # The version of a document.
  #
  # The version is the minor version of the set, e.g. "12.0_12402". The major version is no help:
  # Live 10, 11 and 12 all write MajorVersion="5".
  #
  # @param document [Nokogiri::XML::Document] the document
  # @return [String] the version
  def self.version_of(document)
    document.at_xpath('/Ableton')&.[]('MinorVersion').to_s
  end

  # @param document [Nokogiri::XML::Document] the set to convert
  def initialize(document)
    @document = document
  end

  # Converts the set.
  #
  # @return [Nokogiri::XML::Document] the converted set
  def transform
    self.class.bridge_for(@document).new(@document).convert
  end
end
