require 'colorator'
require 'logger'
require 'optparse'
require_relative '../common/command_options'
require_relative '../common/log'

class AlsReport
  # Display help message for als_report
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      Als_report writes a report of an Ableton Live set in markdown: the tracks of the set and
      the groups they are in, the devices of each of them, the clips and the take lanes, the
      samples that are not in the project, and a cross-reference of the tracks and the clips.

      If the special folder called 'Ableton Project Info' is not present in the same folder as the .als file, a warning is generated.
      Similarly, if 'Ableton Project Info' is present in any parent folder, a warning is issued and the user is asked if the directory should be renamed.

      Syntax: als_report OPTIONS PATH_TO_ALS_FILE

      Environment variables used in PATH_TO_ALS_FILE are expanded.

      Options are:
        -v Show the version of this program.
        -z The time zone the times in the report are written in, e.g. America/Chicago. The
           times are written in the time zone of the computer when it is not given.
        --show_midi_and_audio_tracks_separately Write the audio tracks and the MIDI tracks
           of the set in their own lists. By default, every track is written in the order
           Live saved it in.
        -h Display this help message.

      The report of a set is markdown. It is written to stdout, and the log is written to
      stderr, where it is never markdown.

      To convert a set to another version of the format, use the als_to_version command.

      Example:
        als_report $path/to/my_set.als
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # Parse options for the als_report command
  #
  # @param args [Array<String>] the command line arguments
  # @return [Array(Hash, Array<String>)] the options and the remaining arguments
  def self.parse_options(args)
    options = { loglevel: 'WARN' }
    remaining = do_parse.order!(args, into: options)

    # OptionParser keeps the dash of a long option in the key it uses.
    options[:time_zone] = options.delete(:'time-zone') if options.key?(:'time-zone')

    error = CommandOptions.loglevel_error(options)
    abort help(error) if error
    [options, remaining]
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

  def self.do_parse
    OptionParser.new do |parser|
      parser.program_name = 'als_report'

      parser.on('-l', '--loglevel LOGLEVEL', String, "Logging level (#{LOG_LEVELS.join ', '})")
      parser.on('-s', '--show', 'Display information about the Ableton Live set')
      parser.on('-v', '--version', 'Show the version of this program')
      parser.on('-z', '--time-zone ZONE', String, 'The time zone the times in the report are written in')
      parser.on('--show_midi_and_audio_tracks_separately',
                'Write the audio tracks and the MIDI tracks of the set in their own lists')

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
