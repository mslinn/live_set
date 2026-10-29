require_relative 'live_11_and_12'

# The bridges of the Live versions, and the conversions they make.
#
# The registry is keyed by the version a bridge leads to: the entry for 12 is the bridge that
# stands between Live 11 and Live 12. An entry is a function of a document — it takes a document
# and returns the converted document — and the direction is not a parameter of it: the bridge
# reads the version out of the document it is handed and converts it to the other of the two
# versions.
#
# A conversion from one version to another is the composition of the bridges between them:
#
#   LiveVersions.convert(document, from: 11, to: 12)
#
# The terms used here are defined in docs/glossary.md. The architecture is in docs/cpfir.md,
# "Defining a Single Source of Truth: The Target End-State" and "Dynamically Slicing the
# Pipeline Intervals".
module LiveVersions
  # The bridges, keyed by the version they lead to.
  #
  # The bridge for a version stands between that version and the one before it.
  BRIDGES = {
    12 => Live11And12,
  }.freeze

  # The bridge that converts a set of a version.
  #
  # @param version [String] the minor version of the set, e.g. "12.0_12402"
  # @return [Class] the bridge
  # @raise [ArgumentError] when no bridge converts a set of that version
  def self.bridge_for(version)
    bridge = BRIDGES.values.find { |candidate| candidate.versions.include?(version) }
    raise ArgumentError, "no bridge converts a set of version #{version.inspect}" if bridge.nil?

    bridge
  end

  # The bridges between two versions, in the order they are applied.
  #
  # Going up, the bridges are the versions from the one after the version the set comes from to
  # the version it goes to. Going down, they are the same bridges in the other order.
  #
  # @param from [Integer] the version the set comes from
  # @param to [Integer] the version the set goes to
  # @return [Array<Method>] the bridges, as functions of a document
  # @raise [ArgumentError] when a version has no bridge
  def self.bridges_between(from:, to:)
    keys = to > from ? ((from + 1)..to).to_a : ((to + 1)..from).to_a.reverse
    keys.map { |version| bridge_for_version(version).method(:call) }
  end

  # Converts a document from one version to another.
  #
  # @param document [Nokogiri::XML::Document] the set to convert
  # @param from [Integer] the version the set comes from
  # @param to [Integer] the version the set goes to
  # @return [Nokogiri::XML::Document] the converted set
  def self.convert(document, from:, to:)
    bridges_between(from: from, to: to).reduce(:>>).call(document)
  end

  # The bridge that leads to a version.
  #
  # @param version [Integer] the version the bridge leads to
  # @return [Class] the bridge
  # @raise [ArgumentError] when no bridge leads to that version
  def self.bridge_for_version(version)
    BRIDGES.fetch(version) { raise ArgumentError, "no bridge leads to Live #{version}" }
  end
end
