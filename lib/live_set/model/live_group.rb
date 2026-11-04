require_relative '../../common/xml'
require_relative 'live_device'
require_relative 'live_track'

# A group track in an Ableton Live set.
#
# A group track is a summing container, not a track that plays clips. It has no AudioClip and no
# MidiClip anywhere inside it, and its Slots are empty. It is therefore not reported alongside the
# tracks, and it contributes no clips to any total.
#
# It does have a mixer and a device chain, and its members' audio is routed through that chain: a
# member track's output is routed to AudioOut/GroupTrack. A third-party plugin in a group's chain
# therefore blocks a transfer to Push 3 Standalone just as much as one on a track.
#
# A group track cannot be frozen, because only tracks that hold clips can be frozen, and a group
# track holds no clips. See docs/als_notes.md, "The group tracks".
#
# live_set does not support experimental features, so a group track is always read as unfrozen,
# as though no Options.txt option had been specified. See docs/als_notes.md, "The `Options.txt`
# hidden option".
class LiveGroup
  include Xml

  attr_reader :id, :name, :members, :tracks, :color

  def initialize(group_track, tracks = [], set_directory = nil)
    @group_track = group_track
    @id          = @group_track['Id']
    @name        = name_of group_track
    @color       = @group_track.at('Color')&.[]('Value')&.to_i
    @members = member_tracks tracks
    @tracks = @members.map { |member| LiveTrack.new set_directory, member }
  end

  # Whether the group is a group track.
  #
  # @return [Boolean] true, always: a group is a group track
  def group?
    true
  end

  # The kind of the track.
  #
  # @return [String] the kind
  def kind
    'Group'
  end

  # The id of the group the group is in.
  #
  # A group can be in a group. See docs/als_notes.md, "A member track names its group".
  #
  # @return [String, nil] the id of the group, or nil when the group is in no group
  def group_id
    value = @group_track.at('TrackGroupId')&.[]('Value')
    value == '-1' ? nil : value
  end

  # The name of the group.
  #
  # The name the user typed is the name of the group. When there is none, the name Ableton
  # resolved is the name, without the number Ableton gives the groups that share a name.
  #
  # @param group_track [Nokogiri::XML::Element] the group
  # @return [String] the name of the group
  def name_of(group_track)
    user_name = group_track.at('Name/UserName')&.[]('Value')
    effective_name = group_track.at('Name/EffectiveName')&.[]('Value')
    return user_name unless user_name.nil? || user_name.empty?
    return '(unnamed)' if effective_name.nil? || effective_name.empty?

    effective_name.sub(/\A\d+[- ]/, '')
  end

  # The devices in the group's chain.
  #
  # The path is doubled: the track's DeviceChain contains a DeviceChain, which contains Devices.
  # A group can itself be in a group, so its chain can be nested too.
  #
  # @return [Array<LiveDevice>] the devices
  def devices
    @devices ||= LiveDevice.chain_devices(@group_track).map { |node| LiveDevice.new node }
  end

  # The group's devices that Push 3 Standalone cannot run.
  #
  # A group track cannot be frozen, so a blocking device in a group's chain cannot be rendered
  # away by freezing the group. The tracks inside the group have to be frozen individually.
  #
  # @return [Array<LiveDevice>] the blocking devices
  def blocking_devices
    devices.select(&:blocking?)
  end

  # The names of the group's devices.
  #
  # @return [String] a comma-separated list
  def device_summary
    devices.map(&:label).uniq.join(', ')
  end

  # The tracks in this group.
  #
  # A member track's TrackGroupId holds the Id of the group it belongs to, and -1 means the track
  # is at the top level. See docs/als_notes.md, "A member track names its group".
  #
  # @param tracks [Array<Nokogiri::XML::Element>] the track elements in the set
  # @return [Array<Nokogiri::XML::Element>] the member tracks
  def member_tracks(tracks)
    tracks.select { |track| track.at('TrackGroupId')&.[]('Value') == @id }
  end

  # The names of the tracks in this group.
  #
  # @return [Array<String>] the names
  def member_names
    @members.filter_map { |track| track_name track }
  end

  # The name of a track.
  #
  # @param track [Nokogiri::XML::Element] the track
  # @return [String, nil] the name, or nil if the track has no name
  def track_name(track)
    xml_first_value(track.at('Name/EffectiveName'), track.at('Name/UserName'))
  end
end
