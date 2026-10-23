require 'open3'

# Sends a keypress to a Windows program.
#
# Live's dialogs are modal, and a modal dialog stops everything behind it, so the harness
# has to answer them. A keypress is the simplest way to do that: Live's "Save changes?"
# prompt and its crash-recovery prompt both answer to a key.
#
# The key is sent with WScript.Shell, which is in Windows itself, so nothing has to be
# installed. The program has to have the focus first, so AppActivate brings it forward.
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

  # Sends a key to a process.
  #
  # @param process_id [Integer] the process to send the key to
  # @param keys [String] the keys to send, in WScript.Shell syntax
  # @return [Boolean] whether the key was sent
  def press?(process_id, keys)
    script = write_script
    output, status = Open3.capture2e 'powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                                     '-File', windows_path(script),
                                     '-Process', process_id.to_s, '-Keys', keys
    status.success? && output.include?('SENT')
  end

  private

  # Writes the PowerShell script to a file PowerShell can read.
  #
  # The script has to be somewhere the Windows side can see, so it goes in the Windows
  # temporary directory rather than /tmp.
  #
  # @return [String] the path of the script
  def write_script
    path = File.join windows_directory, 'live_keys.ps1'
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

  # Translates a path into one that PowerShell can use.
  #
  # The Ruby here runs under WSL, and PowerShell runs on the Windows side, so a path such
  # as /mnt/c/Windows/Temp means nothing to PowerShell. wslpath does the translation.
  #
  # @param path [String] the path to translate
  # @return [String] the path PowerShell can use
  def windows_path(path)
    return path unless path.start_with? '/'

    out, status = Open3.capture2e 'wslpath', '-w', path
    status.success? ? out.strip : path
  end
end
