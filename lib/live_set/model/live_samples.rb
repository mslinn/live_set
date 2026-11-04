require_relative 'live_sample'
require_relative 'missing_samples'

# The samples of a set: every file the set plays.
#
# A file can be played by several clips, and it is one sample.
class LiveSamples
  include Enumerable

  attr_reader :clips

  # @param clips [Array<LiveClip>] the clips of the set
  def initialize(clips)
    @clips = clips
  end

  # Every sample of the set, once.
  #
  # @return [Array<LiveSample>] the samples
  def samples
    @samples ||= clips.filter_map { |clip| sample_of clip }.uniq(&:path)
  end

  # The samples of the set that are not in the project.
  #
  # @return [MissingSamples] the samples that are not in the project
  def missing
    MissingSamples.new samples.reject(&:collected?)
  end

  # @yieldparam sample [LiveSample] a sample
  # @return [Enumerator, LiveSamples] the samples
  def each(&)
    return enum_for(:each) unless block_given?

    samples.each(&)
    self
  end

  private

  # The sample a clip plays.
  #
  # @param clip [LiveClip] the clip
  # @return [LiveSample, nil] the sample, or nil when the clip plays no file
  def sample_of(clip)
    return nil if clip.absolute_path.nil?

    LiveSample.new clip.absolute_path, clip.file
  end
end
