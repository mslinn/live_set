# Reads Ableton Live's log, and says what Live did.
#
# Live writes a log of everything it does, one line per event:
#
#   %APPDATA%\Ableton\Live <version>\Preferences\Log.txt
#
# The lines that matter are:
#
#   Loading document "<path>"                 which set Live opened
#   Begin ExchangeDocument                     a load started
#   End ExchangeDocument                       the load finished
#   Exception: Fatal Error: Unhandled exception Live fell over
#   Restore Document: Rejected by the user     a dialog was answered
#   Live App: GlobalExit( ): End or Exit: End  Live quit normally
#
# The log is appended to, so a reader is given the offset to start at, and only reads
# what was written after that. See docs/live_control_plan.md.
class LiveLog
  # The line that says Live quit normally.
  #
  # Ableton's "Reading Ableton Live Crash Reports" article says a normal exit is logged
  # as "Live App: GlobalExit( ): End or Exit: End". Live 11.3.43 writes it as
  # "Live App: GlobalExit(): End", so the match is on the part both agree on.
  EXIT_LINE = 'GlobalExit(): End'.freeze

  # The line that says Live fell over.
  CRASH_LINE = 'Exception: Fatal Error'.freeze

  # The line that says a document was being restored, or was not.
  RESTORE_LINE = 'Restore Document:'.freeze

  # The line that says Live is offering to restore a document.
  OFFER_RESTORE_LINE = 'Checking whether to restore the document'.freeze

  # The outcome of a run.
  #
  # A crash and a load are independent facts. Live can finish loading a set and then
  # crash, so a run that loaded is not necessarily a run that succeeded.
  #
  # @!attribute loaded
  #   @return [Boolean] whether Live finished loading a set
  # @!attribute crashed
  #   @return [Boolean] whether Live fell over
  # @!attribute exited_cleanly
  #   @return [Boolean] whether Live quit normally
  # @!attribute documents
  #   @return [Array<String>] the sets Live opened, in order
  # @!attribute restore_offered
  #   @return [Boolean] whether Live offered to restore a document
  # @!attribute restore_answered
  #   @return [Boolean] whether the restore offer was answered
  Outcome = Struct.new(:loaded, :crashed, :exited_cleanly, :documents, :restore_offered,
                       :restore_answered, keyword_init: true) do
    # @return [Boolean] whether Live opened the set without complaint
    def success?
      loaded && !crashed
    end
  end

  # @param path [String] the path of Live's log
  def initialize(path)
    @path = path
  end

  # The path of Live's log.
  #
  # @return [String] the path
  attr_reader :path

  # Reads the log from an offset, and says what Live did.
  #
  # @param offset [Integer] the offset to start reading at
  # @return [Outcome] what Live did
  def read(offset = 0)
    lines = read_lines offset
    Outcome.new(
      loaded:           lines.any? { |line| line.include? 'End ExchangeDocument' },
      crashed:          lines.any? { |line| line.include? CRASH_LINE },
      exited_cleanly:   lines.any? { |line| line.include? EXIT_LINE },
      documents:        documents_in(lines),
      restore_offered:  lines.any? { |line| line.include? OFFER_RESTORE_LINE },
      restore_answered: lines.any? { |line| line.include? RESTORE_LINE }
    )
  end

  # The size of the log, so that a later read can start where this one ended.
  #
  # @return [Integer] the size in bytes
  def size
    File.exist?(@path) ? File.size(@path) : 0
  end

  # The lines of the log after an offset.
  #
  # @param offset [Integer] the offset to start reading at
  # @return [Array<String>] the lines
  def read_lines(offset = 0)
    return [] unless File.exist? @path

    File.open(@path, 'rb') do |file|
      file.seek(offset)
      file.read.to_s.force_encoding('UTF-8').scrub
    end.split("\n")
  end

  private

  # The sets Live opened, in the order it opened them.
  #
  # @param lines [Array<String>] the log lines
  # @return [Array<String>] the paths
  def documents_in(lines)
    lines.filter_map do |line|
      match = line.match(/Loading document "(.*)"/)
      match && match[1]
    end
  end
end
