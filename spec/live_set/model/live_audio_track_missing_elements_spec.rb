require 'spec_helper'
require 'live_set/model/live_audio_clip'
require 'live_set/model/live_audio_track'
require 'support/live_sets'

# A track is not always shaped the way the code expects. A track can have no DeviceChain at all.
#
# See docs/als_notes.md, "The sample references of a clip".
#
# No track in the corpus has no DeviceChain, so that case is made by removing the DeviceChain
# from a real track: the document is real, and only the one element differs.
RSpec.describe LiveAudioTrack, '#audio_clips' do
  around { |example| silence_output { example.run } }

  # The path of the set the tracks are in.
  def path
    LiveSets.suite
  end

  # The track whose DeviceChain is removed.
  def track_without_device_chain
    @track_without_device_chain ||= begin
      element = LiveSets.without LiveSets.node(path, '//AudioTrack[@Id="150"]'), './DeviceChain'
      described_class.new LiveSets.directory(path), element
    end
  end

  # The track whose DeviceChain and take lanes are removed.
  def track_without_device_chain_or_take_lanes
    @track_without_device_chain_or_take_lanes ||= begin
      element = LiveSets.without LiveSets.node(path, '//AudioTrack[@Id="150"]'),
                                 './DeviceChain | ./TakeLanes'
      described_class.new LiveSets.directory(path), element
    end
  end

  context 'when the track has no DeviceChain' do
    it 'reports no clips in the session view' do
      expect(track_without_device_chain.audio_clips.in_place('session view')).to be_empty
    end

    it 'reports no clips in the arrangement' do
      expect(track_without_device_chain.audio_clips.in_place('arrangement')).to be_empty
    end

    it 'still reports the clips in the take lanes' do
      # The take lanes are not part of the device chain, so their clips are still there.
      expect(track_without_device_chain.audio_clips.in_lanes.length).to eq(3)
    end

    it 'reports no clips when the take lanes are gone as well' do
      expect(track_without_device_chain_or_take_lanes.audio_clips.to_a).to be_empty
    end

    it 'reports no devices' do
      expect(track_without_device_chain.device_summary).to be_empty
    end
  end
end
