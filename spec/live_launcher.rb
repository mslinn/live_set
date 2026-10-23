require 'open3'
require 'tmpdir'

# Launches Ableton Live with a set, watches it, and shuts it down.
#
# Live is a GUI program, and the Ruby here runs under WSL, so the program is launched on the
# Windows side with PowerShell. PowerShell is reached through the WSL interop, and it does the
# things that cannot be done from Ruby here:
#
# - start the program and watch the process,
# - read the text of a dialog Live puts up, through UI Automation,
# - dismiss the dialog and close the program.
#
# **Live is a single-instance program.** A second launch hands the file to the running instance
# rather than opening it in a new one, so the launcher closes any running instance before it
# starts one. That also means the launcher has to leave Live closed, or the next run cannot
# start.
#
# **Live writes a log of what it did**, and it is the most reliable way to tell a clean load
# from a failed one:
#
#   ~/AppData/Roaming/Ableton/Live <version>/Preferences/Log.txt
#
# A clean load runs from "Loading document" through "Begin ExchangeDocument" to
# "End ExchangeDocument". A failed one reaches "Begin ExchangeDocument" and then logs an
# exception, or logs that the document could not be loaded.
module LiveLauncher
  # The outcome of launching Live.
  #
  # @!attribute exit_code
  #   @return [Integer] the exit code of the launcher
  # @!attribute output
  #   @return [String] everything the launcher wrote
  # @!attribute dialog
  #   @return [String, nil] the text of the dialog Live put up, if it put one up
  # @!attribute log
  #   @return [String] the part of Live's log written by this run
  # @!attribute loaded
  #   @return [Boolean] whether Live finished loading the set
  # @!attribute crashed
  #   @return [Boolean] whether Live reported a fatal error
  Result = Struct.new(:exit_code, :output, :dialog, :log, :loaded, :crashed, keyword_init: true) do
    # @return [Boolean] whether Live loaded the set without complaint
    def success?
      exit_code.zero? && dialog.nil? && loaded
    end
  end

  # The PowerShell script that launches Live, watches it, and reports what happened.
  SCRIPT = File.read(File.expand_path('support/live_harness/live_launcher.ps1', __dir__))

  class << self
    # Launches Live with a set, and reports what happened.
    #
    # @param executable [String] the path of the Live executable
    # @param set [String] the path of the set to open
    # @param log [String, nil] the path of Live's log
    # @param timeout [Integer] how long to wait, in seconds
    # @return [Result] what happened
    def launch(executable, set, log: nil, timeout: 120)
      script = write_script
      args = ['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', windows_path(script),
              '-Exe', windows_path(executable), '-Set', windows_path(set),
              '-TimeoutSeconds', timeout.to_s]
      args += ['-Log', windows_path(log)] unless log.nil?
      output, status = Open3.capture2e(*args)
      parse output, status
    end

    # Whether Live can be launched at all on this machine.
    #
    # @param executable [String, nil] the path of the Live executable
    # @return [Boolean] true if PowerShell and the executable are both there
    def available?(executable)
      return false if executable.nil?
      return false unless File.exist? executable

      _, status = Open3.capture2e 'powershell.exe', '-NoProfile', '-Command', 'exit 0'
      status.success?
    rescue Errno::ENOENT
      false
    end

    # Translates a path into one that PowerShell can use.
    #
    # The Ruby here runs under WSL, and PowerShell runs on the Windows side, so a path such as
    # /mnt/c/Program Files/... means nothing to PowerShell. It has to be C:\Program Files\....
    # wslpath does this, and does it correctly.
    #
    # @param path [String] the path to translate
    # @return [String] the path PowerShell can use
    def windows_path(path)
      return path unless path.start_with? '/'

      out, status = Open3.capture2e 'wslpath', '-w', path
      status.success? ? out.strip : path
    end

    private

    # Writes the PowerShell script to a file PowerShell can read, and returns its path.
    #
    # The script has to be somewhere the Windows side can see. /tmp is not, so it goes in the
    # Windows temporary directory, which is under /mnt/c from here.
    #
    # @return [String] the path of the script
    def write_script
      path = File.join windows_directory, 'live_launcher.ps1'
      File.write path, SCRIPT
      path
    end

    # The Windows temporary directory, as seen from here.
    #
    # @return [String] the path
    def windows_directory
      @windows_directory ||= begin
        dir = ENV['TEMP'] || ENV['TMP'] || 'C:\\Windows\\Temp'
        wsl = windows_path dir
        # A Windows path that is not on a mounted drive cannot be reached from here.
        wsl.start_with?('/mnt/') ? wsl : '/mnt/c/Windows/Temp'
      end
    end

    # Reads the launcher's output.
    #
    # @param output [String] everything the launcher wrote
    # @param status [Process::Status] how the launcher finished
    # @return [Result] what happened
    def parse(output, status)
      clean = output.gsub("\r\n", "\n")
      dialog = clean[/^DIALOG: (.*)$/, 1]
      dialog = nil if dialog.nil? || dialog.strip == 'none'
      crashed = clean[/^CRASHED: (.*)$/, 1].to_s.strip == 'yes'
      log = clean[/--- LOG ---\s*(.*)\z/m, 1].to_s
      loaded = log.include? 'End ExchangeDocument'
      Result.new exit_code: status.exitstatus, output: clean, dialog: dialog, log: log,
                 loaded: loaded, crashed: crashed
    end
  end
end
