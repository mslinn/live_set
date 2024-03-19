require 'date'

class AlsDelta
  extend Run

  def initialize(set_name, **options)
    @loglevel  = "-loglevel #{options[:loglevel]}"
    @loglevel += ' -stats' unless options[:loglevel] == 'quiet'
    @set_name = set_name

    @set_dir = File.dirname set_name
    @set_name_only = File.basename set_name, '.als'
    backup_set

    @contents = Zlib::GzipReader.open(set_name, &:readlines)

    at_exit { cleanup }
  end

  def backup_name
    @backup_name = if options[:keep]
                     timestamp = Time.now.getutc.strftime '%Y-%m-%d_%H:%M:%S'
                     "#{@backup_dir}/#{backup_name_only}_#{timestamp}.als"
                   else
                     "#{@backup_dir}/#{backup_name_only}_backup.als"
                   end
  end

  def backup_set
    File.cp @set_name, @backup
  end

  def cleanup
    return if options[:keep]
    return unless File.exist? @backup_name

    puts "Deleting #{@backup_name}"
    File.delete @backup_name
  end

  def show
    run "zdiff '#{@set_name}' '#{@backup_name}'"
  end
end
