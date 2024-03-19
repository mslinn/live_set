class AlsDelta
  def initialize(set_name, **options)
    @loglevel  = "-loglevel #{options[:loglevel]}"
    @loglevel += ' -stats' unless options[:loglevel] == 'quiet'
    @set_name = set_name

    @backup_dir = File.dirname set_name
    backup_name_only = File.basename set_name, '.als'
    @backup_path = "#{@backup_dir}"
    backup_set

    @contents = Zlib::GzipReader.open(set_name, &:readlines)
  end

  def backup_set
    File.cp @set_name, @backup
  end

  def show
  end
end
