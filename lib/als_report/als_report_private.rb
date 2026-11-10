require 'colorator'
require 'highline'
require_relative '../live_set/model/live_project_info'

class AlsReport
  private

  # Verify that the Ableton Live project is valid.
  #
  # The 'Ableton Project Info' folders around the set are a fact about the machine the report
  # is made on, and not about the set. The report says what was found: the warnings are in
  # the report, and they are not logged as well, because the report is what the program was
  # asked to produce.
  def check_ableton_project_info
    project_info = LiveProjectInfo.new File.realpath(File.dirname(@set_name))

    project_info.in_parents.each { |parent| add_dash_suffix parent }
  end

  # Ask user if they want to disable an extra 'Ableton Project Info' directory in a parent.
  # These directories can mess up Ableton Live.
  #
  # The question is asked on stderr, so that the report a program writes to stdout is only what
  # the program was asked to produce. It is asked only when there is a terminal to ask at: a
  # program that reads a set without one is left to warn and to go on.
  def add_dash_suffix(parent)
    path = File.join parent, LiveProjectInfo::FOLDER
    return unless $stdin.tty?

    return unless HighLine.new($stdin, $stderr).agree("\nDo you want the directory to be disabled by suffixing a dash to its name? ")

    Log.debug "Renaming #{path} to #{path}-"
    File.rename path, "#{path}-"
    Log.debug 'Rename complete'
  end
end
