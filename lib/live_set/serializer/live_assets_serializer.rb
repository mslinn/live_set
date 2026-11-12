require 'bytesize'
require_relative '../model/live_assets'
require_relative 'live_markup'

# Writes the assets of a set: the samples it plays that it owns.
#
# The section is a list, and not a table: a reader wants to know what the set needs, and the
# order of the needs does not matter. The devices of Ableton are not in it: they have no
# location, and they come with Live.
#
# A sample that is in the set is compatible with P3S Standalone when it is there. A sample
# that is outside the set is not compatible with it, whether it is there or not: the file has
# to be in the set for the Push to play it.
#
# Sample usage:
# markdown = LiveAssetsSerializer.new(assets).to_markdown
class LiveAssetsSerializer
  # The markers of a sample.
  NOT_COMPATIBLE = '❌ not P3S compatible'.freeze
  MISSING = '❌ missing'.freeze

  # Creates a serializer for the assets of a set.
  #
  # @param assets [LiveAssets] the assets of the set
  # @param machine [Boolean] whether the facts of the machine are written
  def initialize(assets, machine: false)
    @assets = assets
    @machine = machine
  end

  # Returns the section as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = ['## Set Assets', '']
    samples = @assets.samples_of_the_set
    if samples.empty?
      lines << 'The set has no samples of its own.'
      return lines.join("\n")
    end

    samples.each_with_index do |asset, index|
      lines << "#{index + 1}. #{entry_of asset}"
    end
    lines.join("\n")
  end

  private

  # One sample of the set, as a line of the list.
  #
  # The information that is not known is not written: a sample that is not on disk has no
  # date, and a sample whose size Live did not record has no size.
  #
  # @param asset [LiveAsset] the sample
  # @return [String] the line
  def entry_of(asset)
    parts = ["<code>#{path_of asset}</code>"]
    size = size_of asset
    parts << "(#{ByteSize.new size})" unless size.nil?
    marker = marker_of asset
    parts << marker unless marker.nil?
    date = date_of asset
    parts << date unless date.nil?
    parts.join(' ')
  end

  # The path of the sample, as the set writes it.
  #
  # @param asset [LiveAsset] the sample
  # @return [String] the path
  def path_of(asset)
    LiveMarkup.escape(asset.path).gsub('/', '/<wbr/>')
  end

  # The size of the sample.
  #
  # The size on disk is the size of the file, and it is a fact of the machine. The size Live
  # recorded is the size of the file as Live saw it, and it is a fact of the set.
  #
  # @param asset [LiveAsset] the sample
  # @return [Integer, nil] the size in bytes, or nil when it is not known
  def size_of(asset)
    size = asset.size_on_disk
    return size if @machine && !size.nil?

    recorded = asset.recorded_size
    recorded.zero? ? nil : recorded
  end

  # What is said about the sample.
  #
  # A sample that is not in the set is not compatible with the P3S Standalone: the file has to
  # be in the set for the Push to play it. A sample that is in the set and is not on this
  # machine is missing, and that is a fact of the machine.
  #
  # @param asset [LiveAsset] the sample
  # @return [String, nil] the marker, or nil when the sample is in the set and is there
  def marker_of(asset)
    return LiveMarkup.warning_span(NOT_COMPATIBLE) unless asset.in_project?
    return nil unless @machine

    asset.there? ? nil : LiveMarkup.warning_span(MISSING)
  end

  # When the file was last changed.
  #
  # The date is a fact of the machine.
  #
  # @param asset [LiveAsset] the sample
  # @return [String, nil] the date, or nil when it is not known
  def date_of(asset)
    return nil unless @machine

    time = asset.last_modified_on_disk
    return nil if time.nil?

    time.strftime '%Y-%m-%d'
  end
end
