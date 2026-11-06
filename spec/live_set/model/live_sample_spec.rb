require 'spec_helper'
require 'live_set/model/live_sample'

# A sample of a set: a file the set plays.
#
# The samples are the ones of the Live 11 reference set, which is checked in.
RSpec.describe LiveSample do
  # A sample with the given paths.
  #
  # @param path [String, nil] the path Live wrote for the file
  # @param relative_path [String, nil] the path of the file relative to the project
  # @return [LiveSample] the sample
  def sample(path, relative_path = nil)
    described_class.new path, relative_path, '/projects/set'
  end

  it 'holds the name of the file' do
    expect(sample('/Users/owen/Music/Ableton/User Library/Samples/Pink Noise.wav').name).to eq(
      'Pink Noise.wav'
    )
  end

  it 'holds the path of the file relative to the project' do
    expect(sample('/Users/owen/Pink Noise.wav', 'Samples/Pink Noise.wav').relative_path).to eq(
      'Samples/Pink Noise.wav'
    )
  end

  it 'holds the pack the file came from' do
    subject = sample '/Volumes/Music SSD/Music/Packs/Drive and Glow/Samples/Loops/Tambourine.aif'

    expect(subject.pack).to eq 'Drive and Glow'
    expect(subject.pack_path).to eq '/Volumes/Music SSD/Music/Packs/Drive and Glow'
    expect(subject).to be_from_pack
  end

  it 'holds the library the file came from, and does not call it a pack' do
    subject = sample '/Users/owen/Music/Ableton/User Library/Samples/Pink Noise.wav'

    expect(subject.library).to eq 'User Library'
    expect(subject.pack).to be_nil
    expect(subject).not_to be_from_pack
  end

  it 'says that a file of the Core Library comes from the Core Library' do
    subject = sample '/Volumes/data/tmp/trunk/Core Library/Samples/Loops/Vocal Hum.wav'

    expect(subject).to be_from_core_library
    expect(subject.pack).to be_nil
  end

  it 'does not call a file of the project a pack' do
    subject = sample '/projects/set/Samples/Imported/Song.wav'

    expect(subject.pack).to be_nil
    expect(subject.source).to eq 'the project'
  end

  it 'names the source of the sample: the pack, the library, or the project' do
    expect(sample('/Volumes/Packs/Drive and Glow/Samples/Tambourine.aif').source).to eq 'Drive and Glow'
    expect(sample('/Users/owen/User Library/Samples/Pink Noise.wav').source).to eq 'User Library'
  end
end
