require 'open3'
require 'support/gui_harness'

# Sends a keypress to a Windows program.
#
# Live's dialogs are modal, and a modal dialog stops everything behind it, so the harness has to answer them. A keypress
# is the simplest way to do that: Live's "Save changes?" prompt and its crash-recovery prompt both answer to a key.
#
# The key is sent with WScript.Shell, which this program writes to a Windows directory. This approach does not require
# installing any other software.
#
# Live must have the focus before its dialogs can be examined, so `AppActivate` brings it forward.
#
# See docs/live_control_plan.md.
class LiveKeys
  # The Windows program that sends keys.
  #
  # WScript.Shell is part of Windows, so this needs nothing installed.
  SCRIPT = <<~POWERSHELL.freeze
    param(
      [Parameter(Mandatory=$true)][string]$Process,
      [Parameter(Mandatory=$true)][string]$Keys
    )
    $ErrorActionPreference = 'Stop'
    $shell = New-Object -ComObject WScript.Shell
    if (-not $shell.AppActivate([int]$Process)) {
      Write-Output 'NOT ACTIVATED'
      exit 1
    }
    Start-Sleep -Milliseconds 300
    $shell.SendKeys($Keys)
    Write-Output 'SENT'
  POWERSHELL

  # Send a key to a process.
  #
  # @param process_id [Integer] the process to send the key to
  # @param keys [String] the keys to send, in WScript.Shell syntax
  # @return [Boolean] whether the key was sent successfully
  def press?(process_id, keys)
    return false unless File.writable?(windows_directory)

    script = write_powershell_keypress_script
    output, status = Open3.capture2e 'powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                                     '-File', GuiHarness::Live::Launcher.windows_path(script),
                                     '-Process', process_id.to_s, '-Keys', keys
    status.success? && output.include?('SENT')
  rescue Errno::EACCES, Errno::ENOENT, Errno::EROFS
    false
  end

  private

  # Writes the keypress PowerShell script (live_keys.ps1) to a file in the Windows
  # temporary directory.
  #
  # @return [String] the path of the script
  def write_powershell_keypress_script
    path = File.join windows_directory, 'live_keys.ps1'
    File.write path, SCRIPT
    path
  end

  # The location Windows temporary directory, as seen from WSL.
  #
  # @return [String] the path
  def windows_directory
    @windows_directory ||= begin
      dir = ENV['TEMP'] || ENV['TMP'] || 'C:\\Windows\\Temp'
      wsl = GuiHarness::Live::Launcher.windows_path dir
      # A Windows path that is not on a mounted drive cannot be reached from WSL.
      wsl.start_with?('/mnt/') ? wsl : '/mnt/c/Windows/Temp'
    end
  end
end
