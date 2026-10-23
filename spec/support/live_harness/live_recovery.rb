# Reads Live's crash-recovery state.
#
# When Live crashes, it leaves a recovery point behind, in
#
#   %APPDATA%\Ableton\Live <version>\Preferences\CrashRecoveryInfo.cfg
#
# The file is a binary Ableton "RemoteableString", but the interesting parts are UTF-16LE
# strings, and they name the set Live was working on:
#
#   C:/ProgramData/Ableton/Live 11 Suite/.../Ninajirachi - In The Rain (Live 11 Suite Demo).als
#
# That is the best evidence available of which set caused a crash: the log says only that
# Live fell over.
#
# The file also drives Live's recovery prompt, which is modal and intercepts the next
# launch. Live tidies up after itself once the prompt has been answered — see
# docs/live_control_plan.md.
class LiveRecovery
  # The name of the file that holds the recovery point.
  INFO_FILE = 'CrashRecoveryInfo.cfg'.freeze

  # The name of the folder Live moves the recovery files into.
  CRASH_FOLDER = 'Crash'.freeze

  # The name of the folder that holds the recovery point's copy of the set.
  BASE_FILES_FOLDER = 'BaseFiles'.freeze

  # A path that looks like a Windows path to a set.
  #
  # There are three such paths in the file: the set that was open, its copy in the
  # recovery point's BaseFiles folder, and the copy in Live's Preferences folder. The
  # first is the one that was being worked on.
  SET_PATH = %r{\A[A-Za-z]:/.*\.als\z}

  # @param preferences [String] the path of Live's Preferences folder
  def initialize(preferences)
    @preferences = preferences
  end

  # The path of Live's Preferences folder.
  #
  # @return [String] the path
  attr_reader :preferences

  # The path of the crash-recovery file.
  #
  # @return [String] the path
  def info_path
    File.join @preferences, INFO_FILE
  end

  # The path of the folder Live moves the recovery files into.
  #
  # @return [String] the path
  def crash_folder
    File.join @preferences, CRASH_FOLDER
  end

  # Whether there is a recovery point to report.
  #
  # @return [Boolean] true if the file is there
  def pending?
    File.exist? info_path
  end

  # The set Live was working on when it crashed.
  #
  # The recovery file names three sets: the one that was open, and the two copies of it
  # in the recovery point. The one that was open is the first, and it is the only one that
  # is not in Live's own folders.
  #
  # @return [String, nil] the path, or nil if there is no recovery point
  def set_path
    return nil unless pending?

    sets = utf16_strings(info_path).grep(SET_PATH)
    original = sets.find { |path| !path.include? 'Preferences/BaseFiles' }
    original&.tr('\\', '/')
  end

  # The UTF-16LE strings in a file.
  #
  # Live writes its configuration files in a mix of encodings. The paths in the recovery
  # file are UTF-16LE, so a plain read of the bytes gives them as null-separated
  # characters.
  #
  # The strings are found by scanning for runs of printable ASCII bytes, each followed by
  # a null. The alignment is not fixed: the field names begin on an even byte and the
  # paths on an odd one, so the scan looks at every offset.
  #
  # @param path [String] the path of the file
  # @return [Array<String>] the strings
  def utf16_strings(path)
    return [] unless File.exist? path

    bytes = File.binread path
    strings = []
    index = 0
    while index < bytes.bytesize - 1
      length = utf16_run_length(bytes, index)
      if length.zero?
        index += 1
      else
        strings << bytes[index, length].force_encoding('UTF-16LE')
                                       .encode('UTF-8', invalid: :replace, undef: :replace)
        index += length
      end
    end
    strings
  end

  private

  # The length in bytes of the UTF-16LE string at an offset.
  #
  # @param bytes [String] the bytes of the file
  # @param index [Integer] the offset to look at
  # @return [Integer] the length, or zero if there is no string there
  def utf16_run_length(bytes, index)
    return 0 unless printable_pair?(bytes, index)

    length = 0
    length += 2 while printable_pair?(bytes, index + length)
    length
  end

  # Whether the bytes at an offset are a printable character and its null.
  #
  # @param bytes [String] the bytes of the file
  # @param index [Integer] the offset to look at
  # @return [Boolean] true if they are
  def printable_pair?(bytes, index)
    return false if index + 1 >= bytes.bytesize

    bytes.getbyte(index).between?(0x20, 0x7e) && bytes.getbyte(index + 1).zero?
  end
end
