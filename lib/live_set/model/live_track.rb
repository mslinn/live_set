require_relative '../../common/log'
require_relative '../../common/xml'
require_relative 'live_audio_clip'
require_relative 'live_clip'
require_relative 'live_device'
require_relative 'live_take_lanes'

# A track of a set: a MIDI track, an audio track, a group track, a return track or the master
# track.
#
# A group track is a track that holds other tracks, and it is different in three ways: it
# holds no clips of its own, it cannot be frozen, and its device chain is nested one level
# deeper than a track's. See docs/als_notes.md, "The group tracks".
#
# The model holds no number: the XML has no notion of a track number, and the serializer
# generates the numbers of the report.
#
# not implemented: parsing of elements AutomationEnvelopes, AutomationLane and the
# arrangement of a track
class LiveTrack
  include Xml

  # The kinds of track, and the element that holds each of them.
  KINDS = {
    'MidiTrack' => 'MIDI', 'AudioTrack' => 'Audio', 'GroupTrack' => 'Group',
    'ReturnTrack' => 'Return', 'MasterTrack' => 'Master', 'MainTrack' => 'Main'
  }.freeze

  attr_reader :audio_clips, :id, :kind, :color, :clips, :take_lanes, :devices, :chain_devices

  # The two sequencers a track can have.
  #
  # A track that is frozen keeps both. The MainSequencer holds the editable material, and the
  # FreezeSequencer holds the rendered audio cache that replaces it during playback. A frozen
  # track's clips can be in either, and some are only in the FreezeSequencer, so both have to be
  # searched. See docs/als_notes.md, "The two sequencers of a track, and the frozen track that
  # keeps both".
  SEQUENCERS = %w[MainSequencer FreezeSequencer].freeze

  def initialize(set_directory, audio_track)
    @audio_track = audio_track
    @id          = @audio_track['Id']
    @frozen      = xml_bool?(@audio_track.at('Freeze'), description: "AudioTrack '#{@id}' Freeze")

    device_chain = @audio_track.at('DeviceChain')

    Log.debug "Track #{@id}:"
    Log.debug "  DeviceChain exists: #{!device_chain.nil?}"
    SEQUENCERS.each do |sequencer|
      Log.debug "  #{sequencer} exists: #{!device_chain&.at(sequencer).nil?}"
    end

    # The devices of the track itself. The chain of the group the track is in holds the
    # group's own devices, and those belong to the group. See docs/als_notes.md, "The device
    # chain, and the chains nested inside it", and "The device chain of a group".
    @devices = LiveDevice.own_devices(@audio_track).map { |node| LiveDevice.new node }

    # Every device in the chain of the track, at any depth. A track in a group holds the
    # group's chain in an AudioEffectGroupDevice, several levels down.
    @chain_devices = LiveDevice.chain_devices(@audio_track).map { |node| LiveDevice.new node }

    @audio_clips = define_audio_clips set_directory
    @kind = KINDS.fetch(@audio_track.name, @audio_track.name)
    @color = @audio_track.at('Color')&.[]('Value')&.to_i
    @clips = clips_of_track
    @take_lanes = LiveTakeLanes.new @audio_track
  end

  # The clips of the track, and the place each of them is in.
  #
  # A track's audio can be in the session view, in the arrangement, and in the take lanes.
  # The clips of the take lanes are in the lanes, which are subordinate to the track.
  #
  # @return [Array<LiveClip>] the clips
  def clips_of_track
    places = {
      'session view' => ['DeviceChain/MainSequencer/ClipSlotList/ClipSlot/ClipSlot/Value/AudioClip',
                         'DeviceChain/MainSequencer/ClipSlotList/ClipSlot/ClipSlot/Value/MidiClip'],
      'arrangement'  => ['DeviceChain/MainSequencer/Sample/ArrangerAutomation/Events/AudioClip',
                         'DeviceChain/MainSequencer/ClipTimeable/ArrangerAutomation/Events/MidiClip'],
    }

    places.flat_map do |place, paths|
      @audio_track.xpath(paths.join(' | ')).map { |node| LiveClip.new node, place: place }
    end
  end

  # Whether the track is a group track.
  #
  # @return [Boolean] true for a group track
  def group?
    kind == 'Group'
  end

  # Whether the track is soloed.
  #
  # @return [Boolean] true when the track is soloed
  def soloed?
    value_of(@audio_track, 'IsSoloed') == 'true'
  end

  # Whether the track is armed for recording.
  #
  # @return [Boolean] true when the track is armed
  def armed?
    value_of(@audio_track, 'IsArmed') == 'true'
  end

  # Whether the track is switched off.
  #
  # The on/off state of a track is in the mixer of the track: the Manual value of the On
  # element is false when the track is off.
  #
  # @return [Boolean] true when the track is off
  def off?
    @audio_track.at_xpath('./Mixer/On/Manual | ./On/Manual')&.[]('Value') == 'false'
  end

  # The group of tracks this track is linked to.
  #
  # The Link Tracks command locks the editing of several tracks together. See TODO N56.
  #
  # @return [String, nil] the id of the group, or nil when the track is linked to no other
  def linked_group
    value = @audio_track.at('LinkedTrackGroupId')&.[]('Value')
    value == '-1' ? nil : value
  end

  # Whether the track cannot be transferred to Push 3 Standalone.
  #
  # A track that is not frozen and that has a device Push 3 cannot run cannot be transferred:
  # the device has to be rendered away by freezing the track.
  #
  # @return [Boolean] true when the track is a problem
  def problem?
    !frozen? && @devices.any?(&:blocking?)
  end

  # The clips in this track, grouped by where they come from.
  #
  # A track's audio can be in the session view, in the arrangement, and in the take lanes. They are
  # separate clips with separate ids, and the same file can be referenced from more than one of
  # them. See docs/als_notes.md, "Where a track's audio is".
  #
  # A frozen track's audio may be in the FreezeSequencer rather than the MainSequencer, so each
  # source is searched in both sequencers. See docs/als_notes.md, "The two sequencers of a
  # track, and the frozen track that keeps both".
  def define_audio_clips(set_directory)
    {
      'Session view' => session_view_clips(set_directory),
      'Arrangement'  => arrangement_clips(set_directory),
      'Take lanes'   => take_lane_clips(set_directory),
    }
  end

  # The clips in the track's row of session-view slots.
  def session_view_clips(set_directory)
    sequencer_clips('ClipSlotList/ClipSlot/ClipSlot/Value/AudioClip')
      .map { |node| LiveAudioClip.new(set_directory, node) }
  end

  # The clips on the arrangement timeline.
  def arrangement_clips(set_directory)
    sequencer_clips('Sample/ArrangerAutomation/Events/AudioClip')
      .map { |node| LiveAudioClip.new(set_directory, node) }
  end

  # The clips recorded onto the take lanes.
  def take_lane_clips(set_directory)
    @audio_track.xpath('./TakeLanes/TakeLanes/TakeLane/ClipAutomation/Events/AudioClip')
                .map { |node| LiveAudioClip.new(set_directory, node) }
  end

  # The clips at the given path within a sequencer.
  #
  # @param path [String] the path to the clips, relative to the sequencer
  # @return [Array<Nokogiri::XML::Element>] the clips
  def sequencer_clips(path)
    SEQUENCERS.flat_map { |sequencer| @audio_track.xpath("./DeviceChain/#{sequencer}/#{path}").to_a }
  end

  # The name Live resolved for this track.
  #
  # EffectiveName is the name Ableton resolved, which accounts for renames and for the numbering
  # it adds to duplicate tracks. UserName is the raw name the user typed, and is the only one
  # present in Live 8. Annotation and MemorizedFirstClipName are not names of the track.
  #
  # @return [String] the name
  def name
    xml_first_value(
      @audio_track.at('Name/EffectiveName'),
      @audio_track.at('Name/UserName')
    ) || "##{@id}"
  end

  # The name the user typed for this track.
  #
  # @return [String, nil] the name, or nil when the user has not named the track
  def user_name
    @audio_track.at('Name/UserName')&.[]('Value')
  end

  # The value of an element of the track.
  #
  # @param element [Nokogiri::XML::Element] the track
  # @param name [String] the name of the element
  # @return [String, nil] the value, or nil when there is no such element
  def value_of(element, name)
    element.at_xpath(".//#{name}")&.[]('Value')
  end

  def frozen?
    @frozen
  end

  # Only unfrozen tracks can be blocked by their devices.
  #
  # The devices of the chain of the track are the devices of the group the track is in, and
  # they are counted here as well: TODO N41.
  def blocking_devices
    frozen? ? [] : @chain_devices.select(&:blocking?)
  end

  def device_summary
    @chain_devices.map(&:label).uniq.join(', ')
  end

  # The id of the group the track is in.
  #
  # A member track's TrackGroupId holds the id of the group it belongs to, and -1 means the
  # track is at the top level. See docs/als_notes.md, "A member track names its group".
  #
  # @return [String, nil] the id of the group, or nil when the track is in no group
  def group_id
    value = @audio_track.at('TrackGroupId')&.[]('Value')
    value == '-1' ? nil : value
  end

  def clips_collected?
    distinct_clips.all?(&:collected?)
  end

  # The number of distinct files the track's clips refer to.
  #
  # @return [Integer] the number of distinct files
  def distinct_file_count
    distinct_clips.length
  end

  # The size of the track's audio, counting each file once.
  #
  # The same file can be referenced from the session view, the arrangement and the take lanes at the same time. It
  # occupies space once, so it is counted once. See docs/als_notes.md, "Where a track's audio is".
  #
  # @return [Integer] the size in bytes
  def track_size
    distinct_clips.sum(&:file_size)
  end

  # The track's clips, with each file counted once.
  #
  # @return [Array<LiveAudioClip>] the distinct clips
  def distinct_clips
    @audio_clips.values.flatten.uniq(&:absolute_path)
  end
end
