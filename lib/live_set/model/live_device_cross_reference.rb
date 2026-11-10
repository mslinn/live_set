require_relative 'live_device'

# Cross-reference of the devices in a Live set by the tracks and groups that use them.
#
# A group device is present in two places:
# 1. on the group
# 2. on each the track of the group.
#
# FIXME: search for comments in code and docs that claim devices on a group track are replicated on its child tracks.
# THIS IS FALSE
#
# Devices on a group track are NOT replicated on its child tracks.
class LiveDeviceCrossReference
  include Enumerable

  attr_reader :devices

  # @param devices [LiveDevices] the devices of the set
  def initialize(devices)
    @devices = devices
  end

  # Iterates over the devices, yielding each device and its associated tracks.
  #
  # The unnamed `&` parameter accepts the caller's block without assigning it to a
  # local variable. The `&` in `devices.each_with_its_tracks(&)` forwards that block
  # unchanged, so this method's caller receives the yielded values.
  # This anonymous block-forwarding syntax requires Ruby 3.1 or later.
  #
  # Without a block, returns an Enumerator.
  #
  # @yieldparam device [LiveDevice] a device in the set
  # @yieldparam tracks [Array<LiveTrack, LiveGroup>] tracks associated with the device
  # @return [Enumerator, LiveDeviceCrossReference]
  def each(&)
    return enum_for(:each) unless block_given?

    devices.each_with_its_tracks(&)
    self
  end

  # Groups devices by label, kind, and P3S compatibility.
  #
  # Each hash key is `[label, kind, unusable]`; its value is the tracks associated
  # with devices in that group. Devices with matching keys share one entry.
  #
  # @return [Hash<Array, Array<LiveTrack, LiveGroup>>] device attributes mapped to associated tracks
  def uses
    @uses ||= begin
      groups = {}
      each do |device, tracks|
        unusable = device.blocking? && !tracks.first.frozen?
        key = [device.label, device.kind, unusable]
        groups[key] ||= []
        tracks.each { |track| groups[key] << track }
      end
      groups
    end
  end
end
