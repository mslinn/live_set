require 'spec_helper'
require 'live_set/live_set_track'
require 'live_set/live_set_audio_clip'

# A track is not always shaped the way the code expects. A group track has a DeviceChain but no
# MainSequencer, and a clip is not always an audio clip with a sample behind it.
#
# See docs/als_notes.md, "A group track holds no clips", and "The sample references of a clip".

# Builds a track element with the given body.
def track_element(body)
  Nokogiri::Slop("<AudioTrack Id=\"1\">#{body}</AudioTrack>").xpath('//AudioTrack').first
end

# Builds a clip element with no SampleRef.
def clip_element
  xml = '<AudioClip Id="0" Time="0"><LomId Value="0"/><Name Value="MIDI clip"/></AudioClip>'
  Nokogiri::Slop(xml).xpath('//AudioClip').first
end

RSpec.describe LiveTrack, '#audio_clips' do
  context 'when the track has no DeviceChain' do
    it 'reports no clips' do
      track = described_class.new '/tmp', track_element('<Freeze Value="false"/>')

      expect(track.audio_clips.values.flatten).to be_empty
    end

    it 'reports no devices' do
      track = described_class.new '/tmp', track_element('<Freeze Value="false"/>')

      expect(track.device_summary).to be_empty
    end
  end

  context 'when the track has no MainSequencer' do
    it 'reports no clips' do
      track = described_class.new '/tmp', track_element('<Freeze Value="false"/><DeviceChain><Mixer/></DeviceChain>')

      expect(track.audio_clips.values.flatten).to be_empty
    end
  end

  context 'when the track is a group track' do
    it 'reports no clips' do
      track = described_class.new '/tmp', group_track_element(devices: plugin_device_xml)

      expect(track.audio_clips.values.flatten).to be_empty
    end
  end
end
