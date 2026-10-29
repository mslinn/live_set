require 'spec_helper'
require 'live_set/live_set_audio_clip'
require 'support/live_sets'

# How a clip is shown in a report.
#
# The clip is a real one, from the Live 11 Suite demo set. No clip in the corpus has a
# LastModDate of zero or no LastModDate at all, so those two cases are made from the real clip:
# the value of the element is changed, or the element is removed. The clip is real, and only the
# one value differs.
RSpec.describe LiveAudioClip, '#show_clip' do
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

  # The clip with a LastModDate of zero.
  def clip_with_zero_last_mod_date
    @clip_with_zero_last_mod_date ||= begin
      element = LiveSets.with_attribute clip_element, 'Id', '999'
      element.at_xpath('./SampleRef/LastModDate')['Value'] = '0'
      described_class.new LiveSets.directory(path), element
    end
  end

  # The clip with no LastModDate.
  def clip_without_last_mod_date
    @clip_without_last_mod_date ||= begin
      element = LiveSets.without clip_element, './SampleRef/LastModDate'
      described_class.new LiveSets.directory(path), element
    end
  end

  context 'when the clip has a LastModDate' do
    it 'reports the time' do
      expect(clip.last_modified.strftime('%Y-%m-%d %H:%M:%S')).to eq('2024-01-19 16:31:07')
    end

    it 'shows the path, the size and the time' do
      expect(clip.show_clip).to eq(['    Samples/Loops/Tonal/Vocal/Vocal Demo Lead Takes.aif',
                                    ' 38.1 MB',
                                    '2024-01-19 16:31:07'])
    end
  end

  context 'when the LastModDate is zero' do
    it 'has no time rather than the epoch' do
      expect(clip_with_zero_last_mod_date.last_modified).to be_nil
    end

    it 'still shows the clip' do
      expect(clip_with_zero_last_mod_date.show_clip.first).to include('Vocal Demo Lead Takes.aif')
    end
  end

  context 'when the clip has no LastModDate' do
    it 'has no time rather than the epoch' do
      expect(clip_without_last_mod_date.last_modified).to be_nil
    end

    it 'still shows the clip' do
      expect(clip_without_last_mod_date.show_clip.first).to include('Vocal Demo Lead Takes.aif')
    end
  end
end
