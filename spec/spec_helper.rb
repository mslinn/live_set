require 'bytesize'
require 'fileutils'
require 'nokogiri'
require 'ostruct'
require 'stringio'
require 'tmpdir'

# Require the code in this repository, not an installed gem of the same name.
#
# The repository's version and the installed gem's version can be the same, so a plain
# `require 'live_set'` may pick up the installed one. `rake install` installs this repository's
# code, so the two are the same; but the spec should test this repository either way.
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'live_set'

# The development library: the helpers that find the demo sets on the machine.
$LOAD_PATH.unshift File.expand_path('../dev', __dir__)

# A fixture the examples need is missing.
#
# The examples do not skip when a fixture is missing. A skipped example proves nothing, and a
# suite that skips quietly reports success without having proved anything. The suite stops
# instead, and says what is missing and where it was expected.
#
# @param description [String] what the fixture is
# @param path [String, nil] the path of the fixture
# @return [String] the path of the fixture
# @raise [SystemExit] when the fixture is missing
def require_fixture(description, path)
  return path if path && File.exist?(path)

  abort <<~WARNING

    ═════════════════════════════════════════════════════════════════════════════
    A FIXTURE IS MISSING: #{description}
    ═════════════════════════════════════════════════════════════════════════════

    Expected it here: #{path || '(no path was found)'}

    The examples that need it are not skipped. A skipped example proves nothing, and
    a suite that skips quietly reports success without having proved anything.

    Install what is missing, or put it where the suite expects it, and run the
    suite again.

  WARNING
end

# Whether the suite is running under the Windows Subsystem for Linux.
#
# The project was developed for WSL, which implies Windows 10 or 11. The examples that launch
# Ableton Live need it.
#
# @return [Boolean] true when the suite is running under WSL
def running_in_wsl?
  ENV['WSL_DISTRO_NAME'] || ENV['WSL_INTEROP'] ||
    (File.exist?('/proc/version') && File.read('/proc/version').downcase.include?('microsoft'))
end

# The examples need a machine this project was developed on.
#
# The suite does not skip when the machine is not the right one. A skipped example proves
# nothing, and a suite that skips quietly reports success without having proved anything. The
# suite stops instead, and says what it needs.
#
# @raise [SystemExit] when the machine is not the right one
def require_wsl
  return if running_in_wsl?

  abort <<~WARNING

    ═════════════════════════════════════════════════════════════════════════════
    THE EXAMPLES NEED WSL
    ═════════════════════════════════════════════════════════════════════════════

    This project was developed for WSL, which implies Windows 10 or 11. The examples
    that launch Ableton Live need it, and the examples that do not need it are worth
    nothing on their own.

    Run the suite under WSL.

  WARNING
end

# The fixture sets reference sample files that are intentionally not present. Keep their
# diagnostic output out of the specs that only inspect clip metadata.
#
# The diagnostics are written to stderr, so both streams are captured: a spec that silences the
# output has to silence all of it.
def silence_output
  original_stdout = $stdout
  original_stderr = $stderr
  $stdout = StringIO.new
  $stderr = StringIO.new
  yield
ensure
  $stdout = original_stdout
  $stderr = original_stderr
end
