require 'spec_helper'
require 'live_set/live_set_class'
require 'support/live_sets'

# The report of a set.
#
# The report names every track of the set, with the state of each one, the effects on it, and
# the clips of it. The members of a group are under the group, and the clips of a track are
# under the track.
#
# See docs/ab_test_plan.md for the program, and analysis/ for the reports themselves.
RSpec.describe LiveSet, '#show' do
  # The report of a set.
  #
  # @param path [String] the path of the set
  # @return [String] the report
  def report(path)
    silence_output { described_class.new(path, loglevel: 'ERROR').show }
  end

  it 'names the set in monospaced type' do
    expect(report(LiveSets.fascination)).to start_with("# `Fascination.als`\n")
  end

  it 'gives the version of Live that wrote the set' do
    expect(report(LiveSets.fascination)).to include('| Written by | Ableton Live 11.3.13 |')
  end

  it 'gives the machine the set is on, and where it is' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to match(/^\| Machine \| \w+ \|$/)
    expect(markdown).to match(%r{^\| Directory \| `.*sets/live_11` \|$})
  end

  it 'gives the times of the set and of the folder it is in' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to match(/^\| Set created \| \d{4}-\d{2}-\d{2} /)
    expect(markdown).to match(/^\| Set modified \| \d{4}-\d{2}-\d{2} /)
    expect(markdown).to match(/^\| Folder created \| \d{4}-\d{2}-\d{2} /)
    expect(markdown).to match(/^\| Folder modified \| \d{4}-\d{2}-\d{2} /)
  end

  it 'names every track of the set' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to include('<code>1-Pink Noise - EDMtips.com</code>')
    expect(markdown).to include('<code>2 Drums</code>')
    expect(markdown).to include('<code>Master</code>')
  end

  it 'gives the kind of each track, with an icon' do
    expect(report(LiveSets.fascination)).to include('<td>🎹 MIDI</td>')
  end

  it 'lists the members of a group under their group' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to include('<code>&nbsp;3-Kontakt 7</code>')
    expect(markdown).to include('<code>&nbsp;4-Tambo and Timbales Loop 90bpm</code>')
  end

  it 'gives the state of each track' do
    expect(report(LiveSets.fascination)).to include(
      '<th>Frozen</th><th>Off</th><th>Solo</th><th>Armed</th>'
    )
  end

  it 'fills the cell of the color with the color' do
    expect(report(LiveSets.fascination)).to match(
      %r{<td style="background-color:#[0-9A-F]{6};color:#[0-9A-F]{6}">\d+</td>}
    )
  end

  it 'gives the clips of each track' do
    expect(report(LiveSets.fascination)).to include('<td>11</td>')
  end

  it 'puts the clips of a track under the track' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to match(/^\s+- 🎹 `3-Kontakt 7` — MIDI$/)
    expect(markdown).to match(/^\s+- 🎹 `3-Kontakt 7 1`/)
  end

  it 'gives the effects on a track' do
    expect(report(LiveSets.fascination)).to include('- Effects: Kontakt 7 (plug-in)')
  end

  it 'crosses the clips with the tracks that use them' do
    expect(report(LiveSets.fascination)).to include('## Track / Clip Cross Reference')
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
