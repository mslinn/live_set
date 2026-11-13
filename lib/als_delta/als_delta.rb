require 'date'
require 'fileutils'
require 'shellwords'
require_relative '../common/command'
require_relative '../common/run'
require_relative 'als_delta_options'

class AlsDelta
  extend Command
  include Run

  # Show the changes to a Live set each time it is saved.
  #
  # The command returns an error code, and it does not exit the process, so that it can
  # be called from other code.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Integer] the exit status: zero when the differences were shown
  def self.run(args)
    options, remaining = parse_options(args)

    abort help('An Ableton Live set name must be provided.') if remaining.empty?
    check_extra_parameters remaining, 1

    set_name = remaining.first.expand_env
    abort "Error: #{set_name} does not exist" unless File.exist? set_name
    abort "Error: #{set_name} is a directory" if File.directory? set_name

    trap('SIGINT') { throw :ctrl_c }

    als_delta = new set_name, **options
    catch :ctrl_c do
      als_delta.show
      als_delta.cleanup
      4
    rescue Exception => e # rubocop:disable Lint/RescueException
      als_delta.cleanup
      warn e.full_message
      2
    end
  end

  def initialize(set_name, **options)
    @options = options
    @loglevel  = "-loglevel #{@options[:loglevel]}"
    @loglevel += ' -stats' unless @options[:loglevel] == 'quiet'
    @set_name = set_name

    @set_dir = File.dirname set_name
    @set_name_only = File.basename set_name, '.als'
  end

  # Where the backups are stored.
  #
  # A backup is written beside the set it is a backup of: it is the file of the set with
  # `_backup` before the extension, e.g. `song_backup.als` beside `song.als`. The backup is
  # deleted when the command exits, unless the `-k` option is given: a kept backup is the
  # file of the set with the time it was made before the extension, e.g.
  # `song_2026-11-09_19:30:00.als`. The location of the backups is the directory of the set,
  # and there is no option that changes it.
  def backup_name
    @backup_name = if @options[:keep]
                     timestamp = Time.now.getutc.strftime '%Y-%m-%d_%H:%M:%S'
                     "#{@set_dir}/#{@set_name_only}_#{timestamp}.als"
                   else
                     "#{@set_dir}/#{@set_name_only}_backup.als"
                   end
  end

  def backup_set
    @backup_name = backup_name
    puts "Backing up Live set to '#{@backup_name}'"
    FileUtils.cp @set_name, @backup_name
  end

  def cleanup
    return if @options[:keep] || !@backup_name
    return unless File.exist? @backup_name

    puts "Deleting '#{@backup_name}'"
    File.delete @backup_name
  end

  # The changes to the set, since the backup of it was made.
  #
  # This is the library: it takes the set, and it returns the differences. It does not ask
  # for a key, and it does not parse a command line.
  #
  # @return [Array<String>] the lines of the differences
  def differences
    run_capture_stdout "GZIP=--no-name zdiff #{@set_name.shellescape} #{@backup_name.shellescape}",
                       success_statuses: [0, 1]
  end

  def show
    backup_set
    loop do
      puts 'Press any key to display the changes to the Live set XML file, or press Esc to exit.\n'
      character = $stdin.getch
      break if character.ord == 27

      output = differences
      if output.empty?
        puts 'There were no changes to the saved live set.'
      else
        puts output.join("\n")
        backup_set
      end
    rescue StandardError => e
      warn e.full_message
      exit 1
    end
  end
end
