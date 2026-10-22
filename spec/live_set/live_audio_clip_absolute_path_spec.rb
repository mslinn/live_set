require 'spec_helper'
require 'live_set/live_set_audio_clip'

RSpec.describe LiveAudioClip, '#absolute_path' do
  context 'when the clip has no SampleRef' do
    it 'reports no path' do
      clip = described_class.new '/tmp', clip_element

      expect(clip.absolute_path).to be_nil
    end

    it 'reports a size of zero' do
      clip = described_class.new '/tmp', clip_element

      expect(clip.file_size).to eq(0)
    end

    it 'reports no modification date' do
      clip = described_class.new '/tmp', clip_element

      expect(clip.last_modified).to be_nil
    end
  end
end
