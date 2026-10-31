require 'spec_helper'
require 'live_set/live_set_class'
require 'support/live_sets'

# The report of a set, in markdown.
#
# The report that is written for the terminal is about the tracks that hold clips, because that
# is what a transfer to Push 3 Standalone is about. A set of the A/B program holds tracks that
# hold no clips at all, so the report of the set names every track of it, with the state of each
# one and the members of a group under the group they belong to.
#
# See docs/ab_test_plan.md for the program, and analysis/ for the reports themselves.
RSpec.describe LiveSet, '#show' do
  # The report of a set, in markdown.
  #
  # @param path [String] the path of the set
  # @return [String] the report
  def report(path)
    silence_output { described_class.new(path, loglevel: 'ERROR').show }
  end

  it 'names the set' do
    expect(report(LiveSets.fascination)).to start_with("# Fascination.als\n")
  end

  it 'gives the version of Live that wrote the set' do
    expect(report(LiveSets.fascination)).to include('| Created by | Ableton Live 11.3.13 |')
  end

  it 'gives the times of the set' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to match(/^\| Created \| \d{4}-\d{2}-\d{2} /)
    expect(markdown).to match(/^\| Modified \| \d{4}-\d{2}-\d{2} /)
  end

  it 'names every track of the set' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to match(/^\| 1-Pink Noise - EDMtips\.com \| Audio \|/)
    expect(markdown).to match(/^\| 2 Drums \| Group \|/)
    expect(markdown).to match(/^\| Master \| Master \|/)
  end

  it 'lists the members of a group under their group' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to match(/^\| ↳ 3-Kontakt 7 \| MIDI \|/)
    expect(markdown).to match(/^\| ↳ 4-Tambo and Timbales Loop 90bpm \| Audio \|/)
  end

  it 'gives the state of each track' do
    expect(report(LiveSets.fascination)).to include('| Track | Kind | Frozen | Off | Solo | Armed | Color | Clips |')
  end

  it 'gives the color of each track as the number Live writes for it' do
    expect(report(LiveSets.fascination)).to match(/^\| ↳ 3-Kontakt 7 \| MIDI \|.*\| \d+ \|/)
  end

  it 'gives the clips of each track' do
    expect(report(LiveSets.fascination)).to match(/^\| ↳ 3-Kontakt 7 \| MIDI \|.*\| 8 MIDI \|$/)
  end

  it 'escapes the pipe in the name of a track' do
    # Live writes the name of a return track with the name of its device, joined by a pipe.
    expect(report(LiveSets.fascination)).to include('| A-Fresh Room \| EQ Eight |')
  end

  it 'says that a set that cannot be transferred is not ready' do
    expect(report(LiveSets.fascination)).to include(
      '❌ Warning: This set should not be transferred to Push 3 Standalone.'
    )
  end

  it 'writes the errors of the verdict as a list' do
    expect(report(LiveSets.fascination)).to match(/^- Group '2 Drums' uses Filter/)
  end

  it 'has no color in it' do
    expect(report(LiveSets.fascination)).not_to match(/\e\[/)
  end
end
