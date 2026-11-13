require_relative 'hierarchical_number_serializer'
require_relative 'live_devices_serializer'
require_relative 'live_markup'

# Serializes a `LiveMasterTrack` model as markdown.
#
# It writes the line of the track, and then the devices under it. The master track holds no
# clips.
#
# Sample usage:
# track = LiveMasterTrack.new(...)
# markdown = LiveMasterTrackSerializer.new(track, number).to_markdown
class LiveMasterTrackSerializer
  # Creates a serializer for the given track.
  #
  # @param track [LiveMasterTrack] the track to be serialized
  # @param hierarchical_number [HierarchicalNumber] the number of the track in the report
  def initialize(track, hierarchical_number)
    @track = track
    @hierarchical_number = hierarchical_number
  end

  # Returns the track as markdown.
  #
  # The section of the master track is the heading of the section, and the line of the track.
  # The word "Master" is in the heading, and it is not repeated in the line of the track:
  # there is one master track, and its name is the word that is in the heading.
  #
  # @return [String] the serialized markdown
  def to_markdown
    item.to_markdown markdown_children
  end

  # Returns the track as HTML.
  #
  # @return [String] the serialized HTML
  def to_html
    item.to_html html_children
  end

  private

  # The item of the track: its number.
  #
  # @return [HierarchicalNumberSerializer] the item
  def item
    @item ||= HierarchicalNumberSerializer.new @hierarchical_number, "Track #{@hierarchical_number}"
  end

  # The nodes under the track, as markdown.
  #
  # @return [Array<String>] the nodes under the track
  def markdown_children
    [devices.to_markdown].reject(&:empty?)
  end

  # The nodes under the track, as HTML.
  #
  # @return [Array<String>] the nodes under the track
  def html_children
    [devices.to_html].reject(&:empty?)
  end

  # The serializer of the devices of the track.
  #
  # @return [LiveDevicesSerializer] the devices
  def devices
    @devices ||= LiveDevicesSerializer.new(@track.devices, @hierarchical_number, slot_label:   'Track Device',
                                                                                 track_frozen: @track.frozen?)
  end
end
