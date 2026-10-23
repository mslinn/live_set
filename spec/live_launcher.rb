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
  #
  # It is written as a here-string so the Ruby and the PowerShell do not drift apart.
  SCRIPT = <<~POWERSHELL
    param(
      [Parameter(Mandatory=$true)][string]$Exe,
      [Parameter(Mandatory=$true)][string]$Set,
      [string]$Log = '',
      [int]$TimeoutSeconds = 120
    )

    $ErrorActionPreference = 'Stop'
    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes

    Add-Type @'
    using System;
    using System.Text;
    using System.Runtime.InteropServices;
    public class Live {
      [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc cb, IntPtr l);
      public delegate bool EnumWindowsProc(IntPtr h, IntPtr l);
      [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
      [DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr h);
      [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
      [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
      [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    }
    '@

    # Reads the part of the log that this run wrote.
    function Read-Log([long]$Start) {
      if (-not $Log -or -not (Test-Path $Log)) { return '' }
      $stream = [System.IO.File]::Open($Log, 'Open', 'Read', 'ReadWrite')
      $stream.Seek($Start, 'Begin') | Out-Null
      $reader = New-Object System.IO.StreamReader($stream)
      $text = $reader.ReadToEnd()
      $reader.Close()
      return $text
    }

    function Get-Windows([int]$ProcessId) {
      $found = New-Object System.Collections.ArrayList
      [Live]::EnumWindows({
        param($handle, $lparam)
        $owner = 0
        [void][Live]::GetWindowThreadProcessId($handle, [ref]$owner)
        if ($owner -eq $ProcessId -and [Live]::IsWindowVisible($handle)) {
          $class = New-Object System.Text.StringBuilder 256
          [void][Live]::GetClassName($handle, $class, 256)
          $title = New-Object System.Text.StringBuilder 1024
          [void][Live]::GetWindowText($handle, $title, 1024)
          [void]$found.Add([pscustomobject]@{
            Handle = $handle
            Class = $class.ToString()
            Title = $title.ToString()
          })
        }
        return $true
      }, [IntPtr]::Zero) | Out-Null
      return $found
    }

    function Get-DialogText([IntPtr]$Handle) {
      $root = [System.Windows.Automation.AutomationElement]::FromHandle($Handle)
      if ($null -eq $root) { return $null }
      $all = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants,
                           [System.Windows.Automation.Condition]::TrueCondition)
      $text = @()
      foreach ($element in $all) {
        $name = $element.Current.Name
        if ($name -and $name.Length -gt 3) { $text += $name }
      }
      if ($text.Count -eq 0) { return $null }
      return ($text -join ' | ')
    }

    function Click-Button([IntPtr]$Handle, [string]$Label) {
      $root = [System.Windows.Automation.AutomationElement]::FromHandle($Handle)
      if ($null -eq $root) { return $false }
      $condition = New-Object System.Windows.Automation.AndCondition(
        (New-Object System.Windows.Automation.PropertyCondition(
          [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
          [System.Windows.Automation.ControlType]::Button)),
        (New-Object System.Windows.Automation.PropertyCondition(
          [System.Windows.Automation.AutomationElement]::NameProperty, $Label)))
      $button = $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $condition)
      if ($null -eq $button) { return $false }
      try {
        $button.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
        return $true
      } catch { return $false }
    }

    # Live must not already be running, or the file is handed to the running instance
    # instead of being opened by a new one.
    Get-Process -Name 'Ableton Live*' -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2

    $logStart = 0
    if ($Log -and (Test-Path $Log)) { $logStart = (Get-Item $Log).Length }

    $process = Start-Process -FilePath $Exe -ArgumentList "`"$Set`"" -PassThru

    $dialog = $null
    $recovered = $false
    $crashed = $false
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $deadline) {
      Start-Sleep -Milliseconds 500
      $running = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
      if ($null -eq $running) { break }

      $text = Read-Log $logStart

      # Live logs the message it puts up, which is more reliable than reading the dialog.
      if (-not $dialog -and $text -match 'Message Box: (.*)') {
        $message = $Matches[1].Trim()
        if ($message -notmatch 'recover your work') { $dialog = $message }
      }
      if ($text -match 'Exception: Fatal Error') { $crashed = $true }
      if ($text -match 'End ExchangeDocument') { break }

      # Answer the recovery prompt that a previous crash leaves behind, so that the
      # set is opened as it should be rather than the recovery taking precedence.
      foreach ($window in Get-Windows $process.Id) {
        $shown = Get-DialogText $window.Handle
        if ($shown -and $shown -match 'recover your work') {
          if (Click-Button $window.Handle 'No') { $recovered = $true }
        }
      }
    }

    # Dismiss whatever is on screen, so that Live is not left with a modal dialog.
    foreach ($window in Get-Windows $process.Id) {
      $shown = Get-DialogText $window.Handle
      if ($shown) {
        if (Click-Button $window.Handle 'OK') { }
        elseif (Click-Button $window.Handle 'No') { }
        elseif (Click-Button $window.Handle 'Yes') { }
      }
    }

    Start-Sleep -Seconds 2
    $running = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
    if ($running) { $running.CloseMainWindow() | Out-Null }
    Start-Sleep -Seconds 3
    Get-Process -Id $process.Id -ErrorAction SilentlyContinue | Stop-Process -Force

    if ($dialog) { Write-Output ('DIALOG: ' + $dialog) } else { Write-Output 'DIALOG: none' }
    if ($crashed) { Write-Output 'CRASHED: yes' } else { Write-Output 'CRASHED: no' }
    if ($recovered) { Write-Output 'RECOVERED: yes' } else { Write-Output 'RECOVERED: no' }

    Write-Output '--- LOG ---'
    Write-Output (Read-Log $logStart)
  POWERSHELL
           .freeze

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
