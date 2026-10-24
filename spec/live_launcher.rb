require 'open3'
require 'tmpdir'

# TODO
#
# Live is a GUI program, and the Ruby here runs under WSL, so the program is launched on the Windows side with
# PowerShell. PowerShell is reached through the WSL interop, and it does the things that cannot be done from Ruby here:
#
# - start the program and watch the process,
# - read the text of a dialog Live puts up, through UI Automation,
# - dismiss the dialog and close the program.
#
# **Live is a single-instance program.** A second launch hands the file to the running instance rather than opening it
# in a new one, so the launcher closes any running instance before it starts one. That also means the launcher has to
# leave Live closed, or the next run cannot start.
#
# **Live writes a log of what it did**, and it is the most reliable way to tell a clean load from a failed one:
#
#   ~/AppData/Roaming/Ableton/Live <version>/Preferences/Log.txt
#
# A clean load runs from "Loading document" through "Begin ExchangeDocument" to "End ExchangeDocument". A failed one
# reaches "Begin ExchangeDocument" and then logs an exception, or logs that the document could not be loaded.
module LiveLauncher
  # Define recognized dialog families. This allows the harness to classify the top-level dialog by visible text and
  # then dismiss it by performing the appropriate action.
  DIALOG_RULES = [
    {
      action:  { type: 'button', value: 'OK' },
      id:      'fatal',
      pattern: /A serious program error has occurred\.|fatal error/i,
      type:    :fatal,
    },
    {
      action:  { type: 'button', value: 'No' },
      id:      'recover',
      pattern: /Would you like to recover your work\?/i,
      type:    :recovery,
    },
    {
      action:  { type: 'button', value: 'No' },
      id:      'save',
      pattern: /Save changes\?/i,
      type:    :save_changes,
    },
    {
      action:  { type: 'button', value: 'OK' },
      id:      'shutdown',
      pattern: /Live will shut down after this message box is closed\./i,
      type:    :fatal,
    }
  ].freeze

  # The PowerShell script that launches Live, watches it, and reports what happened.
  SCRIPT = File.read(File.expand_path('support/live_harness/live_launcher.ps1', __dir__))

  # The outcome of launching Live.
  #
  # @!attribute exit_code
  #   @return [Integer] the exit code of the launcher
  # @!attribute output
  #   @return [String] everything the launcher wrote
  # @!attribute dialog
  #   @return [String, nil] the text of the dialog Live put up, if it put one up
  # @!attribute dialog_type
  #   @return [Symbol, nil] the dialog family, such as :fatal, :recovery, :save_changes, :unknown
  # @!attribute dismiss_action
  #   @return [Hash, nil] the action needed to dismiss the dialog, e.g. { key: 'n' } or { button: 'No' }
  # @!attribute log
  #   @return [String] the part of Live's log written by this run
  # @!attribute loaded
  #   @return [Boolean] whether Live finished loading the set
  # @!attribute crashed
  #   @return [Boolean] whether Live reported a fatal error
  Result = Struct.new(:exit_code, :output, :dialog, :dialog_type, :dismiss_action, :log, :loaded, :crashed, keyword_init: true) do
    # @return [Boolean] whether Live loaded the set without complaint
    def success?
      exit_code.zero? && dialog.nil? && loaded
    end

    # @return [Symbol] the harness-level outcome for the run
    def outcome
      return :loaded if loaded && !crashed && dialog.nil?
      return :crashed if crashed || dialog_type == :fatal
      return :unknown if dialog_type == :unknown
      return :blocked if dialog_type && dialog_type != :fatal

      :unknown
    end
  end

  class << self
    # Maps the text extracted from a top-level Ableton Live dialog to the recognized Live dialog family and the action
    # the harness should take to dismiss it.
    #
    # @param text [String, nil] the dialog text, as read from the top-level window
    #
    # @return [Hash, nil] { type: :fatal, action: { button: 'OK' } } or similar
    def classify_dialog(text)
      return nil if text.nil? || text.strip.empty?

      rule = DIALOG_RULES.find { |candidate| text.match?(candidate[:pattern]) }
      return { type: :unknown, action: nil } if rule.nil?

      { type: rule[:type], action: rule[:action].dup }
    end

    # Launches Live with a set using a PowerShell script, and reports what happened.
    #
    # @param executable [String] the path of the Live executable
    # @param set [String] the path of the set to open
    # @param log [String, nil] the path of Live's log
    # @param timeout [Integer] how long to wait, in seconds
    # @return [Result] what happened
    def launch(executable, set, log: nil, timeout: 120)
      script = write_powershell_live_launcher_script
      args = ['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', windows_path(script),
              '-Exe', windows_path(executable), '-Set', windows_path(set),
              '-TimeoutSeconds', timeout.to_s]
      args += ['-Log', windows_path(log)] unless log.nil?

      # capture2e obtains stdout from powershell, because Live is a GUI program.
      output, status = Open3.capture2e(*args)

      # FIXME: the Ableton Live top-level window must be discovered, categorized, and examined.

      # FIXME: Just returning the an analysis of the PowerShell script output is INSUFFICIENT
      parse output, status
    end

    # Indicates if a program can be launched on this machine.
    #
    # FIXME this method is bogus because it does not use the `executable` parameter ; instead it runs powershell for no
    # reason, which proves nothing.
    #
    # @param executable [String, nil] the path of the Live executable
    # @return [Boolean]
    def available?(executable)
      return false if executable.nil?
      return false unless File.exist? executable

      # FIXME: This does not try to run the executable. There is no reason to run powershell
      _, status = Open3.capture2e 'powershell.exe', '-NoProfile', '-Command', 'exit 0'
      status.success?
    rescue Errno::ENOENT
      false
    end

    # Translate a Linux path into WSL path.
    # Implemented as a wrapper around the WSL wslpath command.
    #
    # @param path [String] the path to translate
    # @return [String] the path PowerShell can use
    def windows_path(path)
      return path unless path.start_with? '/'

      out, status = Open3.capture2e 'wslpath', '-w', path
      status.success? ? out.strip : path
    end

    private

    # Writes the PowerShell script to a Windows file in the Windows temporary directory and returns its path.
    #
    # @return [String] the path of the script
    def write_powershell_live_launcher_script
      path = File.join windows_directory, 'live_launcher.ps1'
      File.write path, SCRIPT
      path
    end

    # The Windows temporary directory, as seen from WSL.
    #
    # @return [String] the path
    def windows_directory
      @windows_directory ||= begin
        dir = ENV['TEMP'] || ENV['TMP'] || 'C:\\Windows\\Temp'
        wsl = windows_path dir
        # A Windows path that is not on a mounted drive cannot be reached from WSL.
        wsl.start_with?('/mnt/') ? wsl : '/mnt/c/Windows/Temp'
      end
    end

    DISMISS_ACTIONS = { # rubocop: disable Lint/UselessConstantScoping
      'button=OK' => { type: 'button', value: 'OK' },
      'button=No' => { type: 'button', value: 'No' },
      'key=n'     => { type: 'key', value: 'n' },
    }.freeze

    # Examines the contents of the top-level Ableton Live window and looks for problems by reading the launcher output.
    #
    # @param output [String] everything the launcher wrote @param status [Process::Status] how the launcher finished
    # @return [Result] what happened
    def parse(output, status)
      clean_output = output.gsub("\r\n", "\n")
      dialog = clean_output[/^DIALOG: (.*)$/, 1]
      dialog = nil if dialog.nil? || dialog.strip == 'none'

      dialog_type = clean_output[/^DIALOG_TYPE: (.*)$/, 1]&.strip&.to_sym
      dismiss_action = clean_output[/^DISMISS_ACTION: (.*)$/, 1]
      dismiss_action = DISMISS_ACTIONS[dismiss_action] if dismiss_action

      dialog_info = classify_dialog(dialog)
      dialog_type    ||= dialog_info && dialog_info[:type]
      dismiss_action ||= dialog_info && dialog_info[:action]

      crashed = clean_output[/^CRASHED: (.*)$/, 1].to_s.strip == 'yes'
      log = clean_output[/--- LOG ---\s*(.*)\z/m, 1].to_s
      loaded = log.include? 'End ExchangeDocument'
      Result.new crashed:        crashed,
                 dialog:         dialog,
                 dialog_type:    dialog_type,
                 dismiss_action: dismiss_action,
                 exit_code:      status.exitstatus,
                 loaded:         loaded,
                 log:            log,
                 output:         clean_output
    end
  end
end
