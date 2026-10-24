require 'open3'
require_relative 'log'

module Run
  # Run command passed as a string. Die with a message if an error occurs.
  # @param command [String] the command to run
  # @param success_statuses [Array<Integer>] exit statuses that do not indicate an error
  # @return String array containing lines resulting from running command
  def run_capture_stdout(command, success_statuses: [0])
    # printf "Run #{command}\n".yellow
    stdout_str, stderr_str, status = Open3.capture3 command
    unless success_statuses.include? status.exitstatus
      detail = stderr_str.strip
      detail = ": #{detail}" unless detail.empty?
      Log.error "Error: #{command} returned #{status}#{detail}"
      exit status.exitstatus
    end
    stdout_str.split("\n")
  end
end
