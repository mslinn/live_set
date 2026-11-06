require_relative 'live_pack'

# The packs the set refers to.
#
# A set refers to a pack when it plays a file of the pack. The packs of a set are the packs
# of its samples: the path Live wrote for a sample says which pack the sample came from.
class LivePacks
  include Enumerable

  attr_reader :packs

  # @param samples [LiveSamples] the samples of the set
  def initialize(samples)
    @packs = samples.filter_map { |sample| pack_of sample }.uniq(&:name)
  end

  # The packs that are on this machine.
  #
  # @return [Array<LivePack>] the packs
  def located
    packs.select(&:located?)
  end

  # The packs that are not on this machine.
  #
  # A missing pack is not a fault of the set: the set names the file, and the pack holds it.
  #
  # @return [Array<LivePack>] the packs
  def missing
    packs.reject(&:located?)
  end

  # @yieldparam pack [LivePack] a pack
  # @return [Enumerator, LivePacks] the packs
  def each(&)
    return enum_for(:each) unless block_given?

    packs.each(&)
    self
  end

  # @return [Boolean] true when the set refers to no pack
  def empty?
    packs.empty?
  end

  private

  # The pack a sample came from.
  #
  # @param sample [LiveSample] the sample
  # @return [LivePack, nil] the pack, or nil when the sample is not in one
  def pack_of(sample)
    name = sample.pack
    return nil if name.nil?

    LivePack.new name, sample.pack_path
  end
end
