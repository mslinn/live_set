require 'spec_helper'
require 'live_set/model/live_sample'
require 'live_set/serializer/live_sample_serializer'

# A sample of a set: a file the set plays.
#
# The expected values are the lines of the report of the Live 11 reference set, which is
# checked in.
RSpec.describe LiveSampleSerializer, '#to_markdown' do
  it 'writes the name of the sample in code type' do
    sample = LiveSample.new '/Users/owen/Music/Ableton/User Library/Samples/Pink Noise - EDMtips.com.wav',
                            'Samples/Imported/Pink Noise - EDMtips.com.wav'

    expect(described_class.new(sample).to_markdown).to eq '`Pink Noise - EDMtips.com.wav`'
  end

  it 'writes the name of a sample that is not in the project, and says nothing more' do
    sample = LiveSample.new '/Users/owen/Music/Ableton/User Library/Samples/Pink Noise - EDMtips.com.wav'

    expect(described_class.new(sample).to_markdown).to eq '`Pink Noise - EDMtips.com.wav`'
  end

  it 'writes the name of a sample that is in the project, and says nothing more' do
    sample = LiveSample.new '/set/Samples/Imported/Song.wav', 'Samples/Imported/Song.wav'

    expect(described_class.new(sample).to_markdown).to eq '`Song.wav`'
  end
end
