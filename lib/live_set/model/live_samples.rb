require_relative 'live_packs'
require_relative 'live_sample'
require_relative 'missing_samples'

# The samples of a set: every file the set plays.
#
# A file can be played by several clips, and it is one sample.
class LiveSamples
  include Enumerable

  attr_reader :clips, :project_directory

  # @param clips [Array<LiveClip>] the clips of the set
  # @param project_directory [String, nil] the directory of the project
  def initialize(clips, project_directory = nil)
    @clips = clips
    @project_directory = project_directory
  end

  # Every sample of the set, once.
  #
  # @return [Array<LiveSample>] the samples
  def samples
    @samples ||= clips.filter_map { |clip| sample_of clip }.uniq { |sample| [sample.path, sample.relative_path] }
  end

  # The samples that are not missing.
  #
  # A sample is not missing when it is collected into the project, or when it comes from a
  # pack or from the Live core library: a pack that is not installed is a missing pack,
  # and not a missing sample.
  #
  # @return [Array<LiveSample>] the samples
  def located
    @located ||= samples.reject { |sample| missing? sample }
  end

  # The samples of the set that are not in the project.
  #
  # The samples that come from a pack or from the Live core library are not among them:
  # they are not missing from the set, and the packs of the set are reported on their own.
  #
  # @return [MissingSamples] the samples that are not in the project
  def missing
    @missing ||= MissingSamples.new(samples.select { |sample| missing? sample })
  end

  # The packs the set refers to.
  #
  # @return [LivePacks] the packs
  def packs
    @packs ||= LivePacks.new samples
  end

  # @yieldparam sample [LiveSample] a sample
  # @return [Enumerator, LiveSamples] the samples
  def each(&)
    return enum_for(:each) unless block_given?

    samples.each(&)
    self
  end

  private

  # Whether the sample is missing from the set.
  #
  # A sample that has not been collected into the project is missing from it, unless it comes
  # from a pack or from the Live core library: those come with Live and with the pack.
  #
  # @param sample [LiveSample] the sample
  # @return [Boolean] true when the sample is missing
  def missing?(sample)
    return false if sample.collected? || sample.from_pack? || sample.from_core_library?

    true
  end

  # The sample a clip plays.
  #
  # The path Live wrote is the one that says which pack the file is in: the path of the file
  # relative to the project says nothing about it.
  #
  # @param clip [LiveAudioClip] the clip
  # @return [LiveSample, nil] the sample, or nil when the clip plays no file
  def sample_of(clip)
    path = clip.path
    relative_path = clip.relative_path
    return nil if path.nil? && relative_path.nil?

    LiveSample.new path, relative_path, @project_directory
  end
end
