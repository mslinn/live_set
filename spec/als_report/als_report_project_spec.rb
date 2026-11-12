require 'spec_helper'
require 'als_report/als_report'
require 'support/live_sets'

# The report of a project.
#
# The report of a project is the facts that are common to the sets of it, and a report for
# each of the sets.
RSpec.describe AlsReport, 'the report of a project' do # rubocop:disable RSpec/DescribeMethod
  # The report of a project, as the command writes it.
  #
  # @param path [String] the path of the project
  # @param args [Array<String>] the arguments of the command
  # @return [String] the report
  def report_of(path, *args)
    original_out = $stdout
    original_err = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    described_class.run([*args, path])
    $stdout.string
  ensure
    $stdout = original_out
    $stderr = original_err
  end

  it 'writes the facts that are common to the sets of the project' do
    markdown = report_of LiveSets.project11

    expect(markdown).to include(
      '|Context|This report pertains to the Live sets contained in "one_midi_track_only_11 Project" folder.|'
    )
    expect(markdown).to include('|Project created|')
  end

  it 'writes a report for each set of the project' do
    markdown = report_of LiveSets.project11

    expect(markdown).to include('# `factory_default_11.als`')
    expect(markdown).to include('# `one_midi_track_only_11.als`')
  end

  it 'writes the facts of a set in the report of the set' do
    markdown = report_of LiveSets.project11

    expect(markdown).to include('|Written by|Ableton Live 11.3.43|')
  end

  it 'reports only the set that is named' do
    markdown = report_of LiveSets.project11, '--als', 'one_midi_track_only_11.als'

    expect(markdown).to include('# `one_midi_track_only_11.als`')
    expect(markdown).not_to include('# `factory_default_11.als`')
  end

  it 'says so when a set that is named is not there' do
    expect { report_of LiveSets.project11, '--als', 'nope.als' }.to raise_error(SystemExit)
  end
end
