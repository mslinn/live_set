require 'open3'

module Run
  # @return true if the command succeeded
  def run(command)
    # printf "Run #{command}\n".yellow
    $stdout.sync = true
    system(*command)
  end

  # @return String array containing resulting lines of running command
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
