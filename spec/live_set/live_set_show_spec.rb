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
    expect(report(LiveSets.fascination)).to include('|Written by|Ableton Live 11.3.13|')
  end

  it 'gives the computer the set is on, and where it is' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to match(/^\|On computer\|\w+ \([0-9A-Fa-f-]+\)\|$/)
    expect(markdown).to match(%r{^\|Directory\|<code>/.*projects_and_als</code>\|$})
  end

  it 'gives the times of the set and of the folder it is in' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to match(/^\|Set created\|\d{4}-\d{2}-\d{2} /)
    expect(markdown).to match(/^\|Set last modified\|\d{4}-\d{2}-\d{2} /)
    expect(markdown).to match(/^\|Project created\|\d{4}-\d{2}-\d{2} /)
    expect(markdown).to match(%r{^\|Project last modified\|<code>.*</code><br>\d{4}-\d{2}-\d{2} })
  end

  it 'numbers the tracks of the set, and names each of them' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to match(%r{^- Track 1  .*<code[^>]*>Pink Noise - EDMtips\.com</code>})
    expect(markdown).to match(%r{- Group track 1  .*<code[^>]*># Drums</code>})
    expect(markdown).to match(%r{- Group track 2  .*<code[^>]*># Main</code>})
  end

  it 'numbers the devices of a track, and of a group' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to match(/^ {2}- Group Track Device 1a  .*Max for Live  ⚠ not usable on Push 3$/)
    expect(markdown).to match(%r{^ {2}- Group Track Device 1b  <code>DrumBuss</code>  Live$})
  end

  it 'says nothing about devices a track does not have' do
    expect(report(LiveSets.fascination)).not_to include('--none--')
  end

  it 'numbers the tracks in a group, and their clips' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to match(%r{^ {2}- Track 1\.1  🎹 MIDI  .*<code[^>]*>Kontakt 7</code>})
    expect(markdown).to match(%r{^ {2}- Track 1\.2  🎵 Audio  .*<code[^>]*>Tambo and Timbales Loop 90bpm</code>})
    expect(markdown).to match(%r{^\s*\* Clip 1\.1\.\d+ \(×\d+\)  .*<code[^>]*>Kontakt 7 1</code>})
  end

  it 'puts the take lanes of a track under the track' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to match(/^ {2}- Take lane 1\.\d+  /)
  end

  it 'puts the clips of a take lane under the lane' do
    expect(report(LiveSets.fascination)).to match(/^ {4}\* Clip 1\.\d+\.\d+ \(×\d+\)/)
  end

  it 'gives the color of each track, on the name of the track' do
    expect(report(LiveSets.fascination)).to match(
      /background-color:#[0-9A-F]{6};color:#[0-9A-F]{6};vertical-align:middle" title="color \d+">/
    )
  end

  it 'counts the references to a clip' do
    expect(report(LiveSets.fascination)).to match(/^\s*\* Clip \d+\.\d+ \(×\d+\)/)
  end

  it 'gives the settings of a reference on the reference' do
    expect(report(LiveSets.fascination)).to match(/^\s*\* References \(×\d+\): launch: /)
  end

  it 'gives the file of a clip' do
    expect(report(LiveSets.fascination)).to include('`Samples/Pink Noise - EDMtips.com.wav`')
  end

  it 'says that a sample is not in the project' do
    expect(report(LiveSets.fascination)).to include('⚠ not in project')
  end

  it 'summarizes the samples that are not in the project, by the pack they are in' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to include('## Missing Samples')
    expect(markdown).to include('|Drive and Glow|`Tambourine 16th 84 bpm.aif`|')
    expect(markdown).to include('|User Library|`Pink Noise - EDMtips.com.wav`|')
  end

  it 'links the clips that are not collected to the missing samples' do
    expect(report(LiveSets.fascination)).to include('[2 clips have not been collected.](#missing-samples)')
  end

  it 'crosses the devices with the tracks they are on' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to include('## Device/Track Cross-Reference')
    expect(markdown).to include('|Device|Kind|Tracks With This Device|')
    expect(markdown).to match(/\|.*Kontakt 7.*\|VST3\|.*Kontakt 7.*\|/)
  end

  it 'marks the devices that Push 3 cannot use with a dark background' do
    expect(report(LiveSets.fascination)).to include(
      'background-color:#212121;color:#FFFFFF;vertical-align:middle">Filter</code>'
    )
  end

  it 'names the time zone the times are written in' do
    expect(report(LiveSets.fascination)).to match(/^\|Time zone\|.+\|$/)
  end

  it 'says when the report was made, and by what version' do
    expect(report(LiveSets.fascination)).to match(
      /^\|Report generated\|\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} by live_set v\d+\.\d+\.\d+\|$/
    )
  end

  it 'writes the times of the set without a time zone of their own' do
    expect(report(LiveSets.fascination)).to match(/^\|Set created\|\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\|$/)
  end

  it 'gives the warp mode of a sample' do
    expect(report(LiveSets.fascination)).to include('warp: Beats')
  end

  it 'marks the tracks that Push 3 cannot use with a dark background' do
    markdown = report(LiveSets.fascination)

    expect(markdown).to include('background-color:#212121;color:#FFFFFF;vertical-align:middle"># Drums</code>')
    expect(markdown).to include('background-color:#212121;color:#FFFFFF;vertical-align:middle">Kontakt 7</code>')
  end

  it 'explains the marks on a clip' do
    expect(report(LiveSets.fascination)).to include('`⚠ not in project` means the sample is not in the folder')
  end

  it 'gives the effects on a track' do
    expect(report(LiveSets.fascination)).to include('Kontakt 7</code>  VST3  ⚠ not usable on Push 3')
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
end
