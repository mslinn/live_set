require 'logger'
require 'optparse'
require_relative '../common/command'
require_relative '../common/log'

class AlsReport
  extend Command

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

      PATH_TO_ALS_FILE is the path of a set, or the path of a Live project directory. A
      project holds one or more sets, and each of them is reported.

      Environment variables used in PATH_TO_ALS_FILE are expanded.

      OPTIONS may be specified anywhere on the command line:
        -a, --als NAME
                Report only the `.als` file specifed by NAME and ignore all other `.als` files
                in the project. This option may be provided more than once.
        -c, --computer
                Report the facts of the computer the report was made on: the packs that are
                installed, the folders around the set, and the files that are there. They are
                true of the machine and not of the set.
        #{help_help}
        #{log_level_help}
        -s, --show_midi_and_audio_tracks_separately
                Report the audio tracks and the MIDI tracks separately. By default, every
                track is displayed in the order found in the ALS file.
        -v      Show the version of this program and exit. This is the highest priority option.
        -z      The time zone to use in the report in, e.g. America/Chicago. The default
                is America/Toronto, unless the TZ environment variable is set. This option
                overrides the TZ environment variable.

      Examples:
        als_report \\
          -z Europe/Berlin \\
          --show_midi_and_audio_tracks_separately \\
          "$path_to_my_set/demo.als"

         TZ=Europe/Berlin als_report \\
          --show_midi_and_audio_tracks_separately \\
          "$path_to_my_set/demo.als"
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # The options the command starts with.
  #
  # @return [Hash] the options
  def self.default_options
    super.merge(version: false, time_zone: default_time_zone, show_midi_and_audio_tracks_separately: false,
                als: [], report_machine: false)
  end

  # The time zone the report is written in.
  #
  # The TZ environment variable gives the time zone when it is set, and the time zone of
  # Toronto is used when it is not.
  #
  # @return [String] the name of the time
  # TODO accept other common values for timezone, e.g.: CET, UTC-5
  def self.default_time_zone
    zone = ENV.fetch('TZ', nil)
    zone.nil? || zone.empty? ? 'America/Toronto' : zone
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

      # The option may be given more than once, and the names are collected in the order the
      # options were given.
      names = []
      parser.on('-a NAME', '--als NAME', 'Report only the named set of the project') do |name|
        names << name
        names
      end

      parser.on('-c', '--computer', 'Report facts about the computer the report was made on')
      parser.on('-s', '--show_midi_and_audio_tracks_separately',
                'Write the audio tracks and the MIDI tracks of the set in their own lists')
      parser.on('-v', '--version', 'Show the version of this program and exit')
      parser.on('-z', '--time_zone ZONE', String, 'The time zone the times in the report are written in')

      add_common_options parser

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
