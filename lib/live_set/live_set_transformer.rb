require 'nokogiri'
require_relative 'tx/live_versions'

# Converts a live set to another version of the Live format.
#
# A bridge converts between two versions of the format, and it handles moving both ways: the
# direction is not passed in. The bridge reads the version of the document it is handed, and
# converts to the other version of its version_diff. A transform is not directional; the direction is a
# property of the document. See docs/cpfir.md, "The Lifecycle of a Conversion".
#
# The bridges are in the tx subdirectory of this directory, one for each version_diff, and the
# registry of them is `lib/live_set/tx/live_versions.rb`: it is keyed by the version a bridge
# leads to, and a conversion from one version to another is the composition of the bridges
# between them. The transformations of a bridge are the differences between the two versions it
# bridges, and how they are found is in docs/conversion.md, "The kinds of difference" and "The
# differences must be sorted by kind, and the non-obvious ones hand-written".
class LiveSetTransformer
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
    LiveVersions.bridge_for(self.class.version_of(@document)).call(@document)
  end
end
