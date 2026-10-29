require 'spec_helper'
require 'live_set/live_set_audio_clip'
require 'support/live_sets'

# Where a clip's sample is, and how big it is.
#
# The clip is a real one, from the Live 11 Suite demo set. No clip in the corpus has no
# SampleRef, so that case is made by removing the SampleRef from a real clip: the clip is real,
# and only the one element differs.
RSpec.describe LiveAudioClip, '#absolute_path' do
  around { |example| silence_output { example.run } }

  # The path of the set the clip is in.
  def path
    LiveSets.suite
  end

  # A clip of the "Lead" track.
  def clip_element
    @clip_element ||= LiveSets.node(path, '//AudioTrack[@Id="150"]//AudioClip')
  end

  # The clip.
  def clip
    @clip ||= described_class.new LiveSets.directory(path), clip_element
  end

  # The clip with its SampleRef removed.
  def clip_without_sample_ref
    @clip_without_sample_ref ||= begin
      element = LiveSets.without clip_element, './SampleRef'
      described_class.new LiveSets.directory(path), element
    end
  end

  context 'when the clip refers to a sample' do
    it 'reads the path relative to the set' do
      expect(clip.relative_path).to eq('Samples/Loops/Tonal/Vocal/Vocal Demo Lead Takes.aif')
    end

    it 'builds the absolute path from the set directory' do
      expect(clip.absolute_path)
        .to eq File.join(LiveSets.directory(path), 'Samples/Loops/Tonal/Vocal/Vocal Demo Lead Takes.aif')
    end

    it 'reads the size of the sample' do
      expect(clip.file_size).to eq(38_102_454)
    end

    it 'reads the time the sample was last modified' do
      expect(clip.last_modified.to_s).to eq('2024-01-19T16:31:07+00:00')
    end
  end

  context 'when the clip has no SampleRef' do
    it 'reports no path' do
      expect(clip_without_sample_ref.absolute_path).to be_nil
    end

    it 'reports a size of zero' do
      expect(clip_without_sample_ref.file_size).to eq(0)
    end

    it 'reports no modification date' do
      expect(clip_without_sample_ref.last_modified).to be_nil
    end
  end
end
