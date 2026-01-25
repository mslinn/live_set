require 'colorator'
require 'highline'

class LiveSet
  private

  def check_abelton_project_info
    debug "Checking Ableton Project Info directory"
    set_directory = File.realpath(File.dirname(@set_name))
    debug "Set directory: #{set_directory}"
    api_path = File.join(set_directory, 'Ableton Project Info')
    debug "Checking for: #{api_path}"
    puts "Warning: '#{api_path}' is not present".red unless File.exist? api_path
    puts "Warning: '#{api_path}' is not a directory".red unless Dir.exist? api_path

    debug "Checking parent directories for 'Ableton Project Info'"
    cur_dir = Pathname.new(set_directory).parent
    prev_dir = nil
    iteration = 0
    while cur_dir && cur_dir != prev_dir
      iteration += 1
      trace "Checking parent directory #{iteration}: #{cur_dir}"
      project_info_path = File.join(cur_dir, 'Ableton Project Info')
      if File.exist? project_info_path
        debug "Found 'Ableton Project Info' in parent: #{cur_dir}"
        add_dash_suffix(cur_dir, project_info_path)
      end
      # Break if we've reached the root directory
      if cur_dir.to_path == '/' || cur_dir.root?
        debug "Reached root directory, stopping search"
        break
      end

      prev_dir = cur_dir
      cur_dir = cur_dir.parent
    end
    debug "Finished checking parent directories (#{iteration} iterations)"
  end

  def add_dash_suffix(cur_dir, path)
    debug "add_dash_suffix called for: #{path}"
    puts "Warning: 'Ableton Project Info' exists in parent directory '#{cur_dir.to_path}'".red
    return unless HighLine.agree("\nDo you want the directory to be disabled by suffixing a dash to its name? ", character = true)

    debug "Renaming #{path} to #{path}-"
    File.rename path, "#{path}-"
    debug "Rename complete"
  end
end
