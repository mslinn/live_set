require_relative '../../common/xml'
require_relative 'live_device'
require_relative 'live_take_lanes'

# The facts that every track element of a set holds.
#
# A set holds four kinds of track element: a `<MidiTrack>`, an `<AudioTrack>`, a
# `<ReturnTrack>` and the `<MasterTrack>` (the `<MainTrack>` in Live 12). Each of them has a
# model class of its own, and each of them reads the facts below from its own element.
#
# The module holds no state of its own and is never instantiated: the class that includes
# it holds the element, and these methods read that element.
#
# What is left to the classes themselves is what makes the kinds different: the kind of the
# track, and the clips it holds.
module LiveTrackFacts
  # The id Live gave the track.
  #
  # @return [String, nil] the id
  def id
    @element['Id']
  end

  # Whether the track is a group track.
  #
  # A group track is `LiveGroup`, and it is the only kind of track that is one.
  #
  # @return [Boolean] false, always
  def group?
    false
  end

  # The clips of the track.
  #
  # A return track and the master track hold no clips.
  #
  # @return [Array<LiveMidiClip>] the clips
  def clips
    []
  end

  # The clips of the audio side of the track.
  #
  # A MIDI track plays no file, and a return track and the master track hold no clips.
  #
  # @return [Array<LiveAudioClip>] the clips
  def audio_clips
    []
  end

  # The name Live resolved for the track.
  #
  # EffectiveName is the name Ableton resolved, which accounts for renames and for the
  # numbering it adds to duplicate tracks. UserName is the raw name the user typed, and is
  # the only one present in Live 8. Annotation and MemorizedFirstClipName are not names of
  # the track.
  #
  # @return [String] the name
  def name
    xml_first_value(
      @element.at('Name/EffectiveName'),
      @element.at('Name/UserName')
    ) || "##{id}"
  end

  # The name the user typed for the track.
  #
  # @return [String, nil] the name, or nil when the user has not named the track
  def user_name
    @element.at('Name/UserName')&.[]('Value')
  end

  # The colour Live gave the track.
  #
  # @return [Integer, nil] the number Live writes for the colour
  def color
    @element.at('Color')&.[]('Value')&.to_i
  end

  # The devices of the track itself.
  #
  # The chain of the group the track is in holds the group's own devices, and those belong
  # to the group. See docs/als_notes.md, "The device chain, and the chains nested inside
  # it", and "The device chain of a group".
  #
  # @return [Array<LiveDevice>] the devices
  def devices
    @devices ||= LiveDevice.own_devices(@element).map { |node| LiveDevice.new node }
  end

  # Every device in the chain of the track, at any depth.
  #
  # A track in a group holds the group's chain in an AudioEffectGroupDevice, several levels
  # down.
  #
  # @return [Array<LiveDevice>] the devices
  def chain_devices
    @chain_devices ||= LiveDevice.chain_devices(@element).map { |node| LiveDevice.new node }
  end

  # The take lanes of the track.
  #
  # @return [LiveTakeLanes] the lanes
  def take_lanes
    @take_lanes ||= LiveTakeLanes.new @element
  end

  # Whether the track is frozen.
  #
  # @return [Boolean] true when the track is frozen
  def frozen?
    @frozen
  end

  # Whether the track is soloed.
  #
  # @return [Boolean] true when the track is soloed
  def soloed?
    value_of(@element, 'IsSoloed') == 'true'
  end

  # Whether the track is armed for recording.
  #
  # @return [Boolean] true when the track is armed
  def armed?
    value_of(@element, 'IsArmed') == 'true'
  end

  # Whether the track is switched off.
  #
  # The on/off state of a track is in the mixer of the track: the Manual value of the On
  # element is false when the track is off.
  #
  # @return [Boolean] true when the track is off
  def off?
    @element.at_xpath('./Mixer/On/Manual | ./On/Manual')&.[]('Value') == 'false'
  end

  # The group of tracks this track is linked to.
  #
  # The Link Tracks command locks the editing of several tracks together. See TODO N56.
  #
  # @return [String, nil] the id of the group, or nil when the track is linked to no other
  def linked_group
    value = @element.at('LinkedTrackGroupId')&.[]('Value')
    value == '-1' ? nil : value
  end

  # The id of the group the track is in.
  #
  # A member track's TrackGroupId holds the id of the group it belongs to, and -1 means the
  # track is at the top level. See docs/als_notes.md, "A member track names its group".
  #
  # @return [String, nil] the id of the group, or nil when the track is in no group
  def group_id
    value = @element.at('TrackGroupId')&.[]('Value')
    value == '-1' ? nil : value
  end

  # Whether the track cannot be transferred to Push 3 Standalone.
  #
  # A track that is not frozen and that has a device Push 3 cannot run cannot be transferred:
  # the device has to be rendered away by freezing the track.
  #
  # @return [Boolean] true when the track is a problem
  def problem?
    !frozen? && devices.any?(&:blocking?)
  end

  # The group's devices that Push 3 Standalone cannot run.
  #
  # Only unfrozen tracks can be blocked by their devices. The devices of the chain of the
  # track are the devices of the group the track is in, and they are counted here as well:
  # TODO N41.
  #
  # @return [Array<LiveDevice>] the blocking devices
  def blocking_devices
    frozen? ? [] : chain_devices.select(&:blocking?)
  end

  # The names of the devices of the track.
  #
  # @return [String] a comma-separated list
  def device_summary
    chain_devices.map(&:label).uniq.join(', ')
  end

  # The value of an element of the track.
  #
  # @param element [Nokogiri::XML::Element] the track
  # @param name [String] the name of the element
  # @return [String, nil] the value of the element, or nil when there is no such element
  def value_of(element, name)
    element.at_xpath(".//#{name}")&.[]('Value')
  end

  private

  # Reads the facts of the track element that the module holds.
  #
  # @param kind [String] the kind of the track, for the log
  # @return [void]
  def read_track_facts(kind)
    @frozen = xml_bool?(@element.at('Freeze'), description: "#{kind} '#{id}' Freeze")
  end
end
