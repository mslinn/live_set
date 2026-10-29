require 'colorator'
require 'highline'

class LiveSet
  private

  # Verify that the Ableton Live project is valid
  def check_ableton_project_info
    set_directory = File.realpath(File.dirname(@set_name))
    Log.debug "Set directory: #{set_directory}"
    api_path = File.join(set_directory, 'Ableton Project Info')
    Log.warn "Warning: '#{api_path}' is not present" unless File.exist? api_path
    Log.warn "Warning: '#{api_path}' is not a directory" unless Dir.exist? api_path

    Log.debug "Checking parent directories for 'Ableton Project Info'"
    cur_dir = Pathname.new(set_directory).parent
    while cur_dir
      project_info_path = File.join(cur_dir, 'Ableton Project Info')
      if File.exist? project_info_path
        Log.debug "Found 'Ableton Project Info' in parent: #{cur_dir}"
        add_dash_suffix(cur_dir, project_info_path)
      end
      # Break if we've reached the root directory
      if cur_dir.to_path == '/' || cur_dir.root?
        Log.debug 'Reached root directory, stopping search'
        break
      end

      cur_dir = cur_dir.parent
    end
  end

  # Ask user if they want to disable an extra 'Ableton Project Info' directory in a parent.
  # These directories can mess up Ableton Live.
  def add_dash_suffix(cur_dir, path)
    Log.warn "Warning: 'Ableton Project Info' exists in parent directory '#{cur_dir.to_path}'"
    return unless HighLine.agree("\nDo you want the directory to be disabled by suffixing a dash to its name? ")

    Log.debug "Renaming #{path} to #{path}-"
    File.rename path, "#{path}-"
    Log.debug 'Rename complete'
  end
end
