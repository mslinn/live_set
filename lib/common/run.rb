require 'open3'

module Run
  # Run command passed as a string. Die with a message if an error occurs.
  # @return String array containing lines resulting from running command
  def run_capture_stdout(command)
    # printf "Run #{command}\n".yellow
    stdout_str, status = Open3.capture2 command
    unless status.success?
      printf "Error: #{command} returned #{status}"
      exit status.to_i
    end
    stdout_str.strip.split
  end
end
