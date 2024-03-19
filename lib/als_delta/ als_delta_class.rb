require 'date'
require 'fileutils'
require_relative '../common/run'

class AlsDelta
  include Run

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
    FileUtils.cp @set_name, @backup_name
  end

  def cleanup
    return if @options[:keep] || !@backup_name
    return unless File.exist? @backup_name

    puts "Deleting #{@backup_name}"
    File.delete @backup_name
  end

  def show
    output = run_capture_stdout "zdiff '#{@backup_name}' '#{@set_name}'"
    if output.empty?
      puts 'There were no changes to the saved live set.'
    else
      puts output.join("\n")
    end
  end
end
