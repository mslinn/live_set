require_relative 'live_device'

# The devices of a set, and the tracks they are on.
#
# A device of a group is on the group and on the tracks in the group, because the chain of
# the group processes the audio of the tracks in it.
class LiveDevices
  include Enumerable

  attr_reader :tracks

  # @param tracks [Array<LiveTrack, LiveGroup>] the tracks of the set
  def initialize(tracks)
    @tracks = tracks
  end

  # Every device of the set, with the tracks it is on.
  #
  # @yieldparam device [LiveDevice] a device
  # @yieldparam tracks [Array<LiveTrack, LiveGroup>] the tracks it is on
  # @return [void]
  def each_with_its_tracks
    tracks.each do |track|
      if track.group?
        track.devices.each { |device| yield device, [track, *track.tracks] }
        track.tracks.each do |member|
          member.devices.each { |device| yield device, [member] }
        end
      else
        track.devices.each { |device| yield device, [track] }
      end
    end
  end

  # Every device of the set.
  #
  # @yieldparam device [LiveDevice] a device
  # @return [Enumerator, LiveDevices] the devices
  def each(&)
    return enum_for(:each) unless block_given?

    each_with_its_tracks { |device, _tracks| yield device }
    self
  end
end
