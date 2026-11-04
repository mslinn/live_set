require_relative 'live_sample'

# The samples of a set that are not in the project, by the pack they are in.
#
# The clips that are not collected are counted and not named in the verdict: a demo set holds
# dozens of them, and the list of them says nothing that the count does not.
class MissingSamples
  include Enumerable

  attr_reader :samples

  # @param samples [Array<LiveSample>] the samples that are not in the project
  def initialize(samples)
    @samples = samples
  end

  # The samples, by the pack they are in.
  #
  # @return [Hash] each pack, and the names of the samples in it
  def packs
    @packs ||= samples.group_by(&:pack).transform_values do |in_pack|
      in_pack.map(&:name).uniq.sort
    end
  end

  # @yieldparam sample [LiveSample] a sample
  # @return [Enumerator, MissingSamples] the samples
  def each(&)
    return enum_for(:each) unless block_given?

    samples.each(&)
    self
  end

  # @return [Boolean] true when every sample of the set is in the project
  def empty?
    samples.empty?
  end
end
