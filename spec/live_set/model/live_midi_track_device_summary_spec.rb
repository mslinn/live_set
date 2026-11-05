require 'spec_helper'
require 'live_set/model/live_device'
require 'live_set/model/live_midi_track'
require 'support/live_sets'

# A track's device chain can be nested. An AudioEffectGroupDevice holds a group's device chain in
# its branches, so a member track's real devices are several levels down. A reader that looks only
# at the top level misses them.
#
# See docs/als_notes.md, "The device chain, and the chains nested inside it", and "The device
# chain of a group".
#
# The tracks are real ones, from the checked-in set with return tracks and a third-party device.
# That set holds the only device chain in the corpus that is nested in a group branch, and the
# only plug-in in the corpus.
RSpec.describe LiveMidiTrack, '#device_summary' do
  around { |example| silence_output { example.run } }

  # The path of the set the tracks are in.
  def path
    LiveSets.fascination
  end

  # The track whose chain holds a plug-in.
  #
  # The only plug-in in the corpus is on a MIDI track.
  def track_with_plugin
    @track_with_plugin ||= described_class.new LiveSets.directory(path),
                                               LiveSets.node(path, '//MidiTrack[@Id="16"]')
  end

  it 'finds a plug-in in the chain' do
    expect(track_with_plugin.device_summary).to include('Kontakt 7')
  end

  it 'reports a plug-in as blocking' do
    expect(track_with_plugin.blocking_devices.length).to eq(1)
  end
end
