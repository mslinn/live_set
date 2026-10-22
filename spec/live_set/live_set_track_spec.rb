require 'spec_helper'
require 'live_set/live_set_track'

RSpec.describe LiveTrack do
  describe '#frozen?' do
    it 'is true when the track has <Freeze Value="true"/>' do
      track = described_class.allocate
      track.instance_variable_set(:@frozen, true)

      expect(track.frozen?).to be true
    end

    it 'is false when the track has <Freeze Value="false"/>' do
      track = described_class.allocate
      track.instance_variable_set(:@frozen, false)

      expect(track.frozen?).to be false
    end
  end
end
