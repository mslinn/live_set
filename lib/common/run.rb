require 'open3'
require_relative 'log'

module Run
  # The error raised when a command fails.
  #
  # The command and its status are kept, so that the caller can decide what to print and what
  # status to exit with. A module that runs commands does not decide the fate of the program.
  class Failed < StandardError
    attr_reader :command, :status, :detail

    # @param command [String] the command that failed
    # @param status [Integer] the exit status of the command
    # @param detail [String] what the command wrote to stderr
    def initialize(command, status, detail = '')
      @command = command
      @status = status
      @detail = detail
      message = "Error: #{command} returned #{status}"
      message += ": #{detail}" unless detail.empty?
      super(message)
    end
  end

  # Run a command, and return what it wrote to stdout.
  #
  # @param command [String] the command to run
  # @param success_statuses [Array<Integer>] exit statuses that do not indicate an error
  # @return [Array<String>] the lines the command wrote to stdout
  # @raise [Failed] when the command exited with a status that is not a success status
  def run_capture_stdout(command, success_statuses: [0])
    stdout_str, stderr_str, status = Open3.capture3 command
    raise Failed.new(command, status.exitstatus, stderr_str.strip) unless success_statuses.include? status.exitstatus

    stdout_str.split("\n")
  end
end
