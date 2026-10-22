require 'date'
require 'fileutils'
require 'shellwords'
require_relative '../common/run'

class AlsDelta
  include Run

  # Show the changes to a Live set each time it is saved.
  #
  # @param args [Array<String>] the command line arguments
  # @return [void]
  def self.run(args)
    options, remaining = parse_options(args)

    abort help('An Ableton Live set name must be provided.') if remaining.empty?

    set_name = remaining.join(' ').expand_env
    abort help("#{set_name} does not exist") unless File.exist? set_name
    abort help("#{set_name} is a directory") if File.directory? set_name

    trap('SIGINT') { throw :ctrl_c }

    als_delta = new set_name, **options
    catch :ctrl_c do
      als_delta.show
      als_delta.cleanup
    rescue Exception # rubocop:disable Lint/RescueException
      als_delta.cleanup
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

  def show
    backup_set
    loop do
      puts 'Press any key to display the changes to the Live set XML file, or press Esc to exit.'
      character = $stdin.getch
      exit if character.ord == 27
      output = run_capture_stdout "GZIP=--no-name zdiff #{@set_name.shellescape} #{@backup_name.shellescape}",
                                  success_statuses: [0, 1]
      if output.empty?
        puts 'There were no changes to the saved live set.'
      else
        puts output.join("\n")
        backup_set
      end
    rescue StandardError => e
      puts e
    end
  end
end
