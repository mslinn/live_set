require 'colorator'
require 'highline'

class LiveSet
  private

  def check_abelton_project_info
    set_directory = File.realpath(File.dirname(@set_name))
    api_path = File.join(set_directory, 'Ableton Project Info')
    puts "Warning: '#{api_path}' is not present".red unless File.exist? api_path
    puts "Warning: '#{api_path}' is not a directory".red unless Dir.exist? api_path

    cur_dir = Pathname.new(set_directory).parent
    while cur_dir
      project_info_path = File.join(cur_dir, 'Ableton Project Info')
      add_dash_suffix(project_info_path) if File.exist? project_info_path
      break if cur_dir.to_path == '/'

      cur_dir = cur_dir.parent
    end
  end

  def add_dash_suffix(cur_dir, path)
    puts "Warning: 'Ableton Project Info' exists in parent directory '#{cur_dir.to_path}'".red
    return unless HighLine.agree("\nDo you want the directory to be disabled by suffixing a dash to its name? ", character = true)

    File.rename path, "#{path}-"
  end
end
