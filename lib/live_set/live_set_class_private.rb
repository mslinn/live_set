class LiveSet
  private

  def check_abelton_project_info
    set_directory = File.realpath(File.dirname(@set_name))
    api_path = File.join(set_directory, 'Ableton Project Info')
    puts "Warning: '#{api_path}' is not present".red unless File.exist? api_path
    puts "Warning: '#{api_path}' is not a directory".red unless Dir.exist? api_path

    cur_dir = Pathname.new(set_directory).parent
    while cur_dir
      if File.exist? File.join(cur_dir, 'Ableton Project Info')
        puts "Warning: 'Ableton Project Info' exists in parent directory '#{cur_dir.to_path}'".red
      end
      break if cur_dir.to_path == '/'

      cur_dir = cur_dir.parent
    end
  end
end
