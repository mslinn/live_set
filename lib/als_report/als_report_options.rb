require 'colorator'
require 'logger'
require 'optparse'
require_relative '../common/command'
require_relative '../common/log'

class AlsReport
  # Display help message for als_report
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      Als_report writes a report of an Ableton Live set in markdown, including but not
      limited to the groups, tracks, the devices, clips, take lanes, missing samples,
      and several cross-references.

      The report is written to stdout as markdown. Log output is written in plaintext
      to stderr.

      If the special folder called 'Ableton Project Info' is not present in the same
      folder as the .als file, a warning is generated. Similarly, if 'Ableton Project
      Info' is present in any parent folder, a warning is issued and the user is asked
      if the directory should be renamed.

      Syntax: als_report OPTIONS PATH_TO_ALS_FILE

      Environment variables used in PATH_TO_ALS_FILE are expanded.

      Options are:
        -h    Display this help message.
        -v    Show the version of this program.
        -z    The time zone to use in the report in, e.g. America/Chicago. The time zone
              of the computer the command ran on when this option is not specified.
        #{log_level_help}
        --show_midi_and_audio_tracks_separately
              Report the audio tracks and the MIDI tracks separately. By default, every
              track is displayed in the order found in the ALS file.


      Example:
        als_report \\
          -z America/Toronto \\
          --show_midi_and_audio_tracks_separately \\
          "$path_to_my_set/demo.als"
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # Whether a time zone is one this machine knows.
  #
  # @param zone [String] the name of the zone
  # @return [Boolean] true when the machine knows the zone
  def self.known_time_zone?(zone)
    return true if %w[UTC GMT].include? zone.upcase

    directory = '/usr/share/zoneinfo'
    return true unless File.directory? directory

    File.exist? File.join(directory, zone)
  end

  def self.parser
    OptionParser.new do |parser|
      parser.program_name = 'als_report'

      parser.on('-s', '--show', 'Display information about the Ableton Live set')
      parser.on('-v', '--version', 'Show the version of this program')
      parser.on('-z', '--time-zone ZONE', String, 'The time zone the times in the report are written in')
      parser.on('--show_midi_and_audio_tracks_separately',
                'Write the audio tracks and the MIDI tracks of the set in their own lists')
      add_common_options parser

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
