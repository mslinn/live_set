require_relative 'live_device'

# The devices of a set, and the tracks they are on.
#
# A device of a group is on the group and on the tracks in the group, because the chain of
# the group processes the audio of the tracks in it.
class LiveDeviceCrossReference
  include Enumerable

  attr_reader :devices

  # @param devices [LiveDevices] the devices of the set
  def initialize(devices)
    @devices = devices
  end

  # Each device of the set, with the tracks it is on.
  #
  # @yieldparam device [LiveDevice] a device
  # @yieldparam tracks [Array<LiveTrack, LiveGroup>] the tracks it is on
  # @return [void]
  def each(&)
    return enum_for(:each) unless block_given?

    devices.each_with_its_tracks(&)
    self
  end

  # The devices of the set, grouped by their name, their kind, and whether P3S
  # can run them, with the tracks each of them is on.
  #
  # Two devices with the same name and the same kind are one row of the cross-reference,
  # whether P3S can run them or not.
  #
  # @return [Array] each group of devices, and the tracks they are on
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
