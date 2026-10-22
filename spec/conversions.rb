require 'digest'
require 'fileutils'
require 'nokogiri'
require 'open3'
require 'rbconfig'
require 'stringio'
require 'tmpdir'
require 'zlib'

# Helpers for converting a Live set to the Live 11 format, and for reading the result.
#
# A conversion is not free. The in-process conversion takes about half a millisecond, but
# running the live_set command takes about six hundred milliseconds, because Ruby has to start
# up and load the code. A suite that converts the same set in every example pays for the same
# work over and over, and that work is the bulk of the run time.
#
# These helpers convert each set once and cache the result, so the examples that look at the
# same conversion share one. The cache is keyed by the set, so different sets are still handled
# separately.
#
# The sets that are converted are copies. Nothing here writes to the demo sets themselves.
module Conversions
  # The outcome of running the live_set command.
  #
  # @!attribute status
  #   @return [Process::Status] how the command finished
  # @!attribute output
  #   @return [String] everything the command wrote to stdout and stderr
  # @!attribute path
  #   @return [String] the path of the set the command wrote
  CommandResult = Struct.new(:status, :output, :path, keyword_init: true) do
    # @return [Boolean] whether the command succeeded
    def success?
      status.success?
    end
  end

  # What the live_set command does when it is run three times on the same set.
  #
  # The first run writes the converted set. The second run finds the set already there, and
  # refuses to overwrite it. The third run is given the force option, and overwrites it.
  #
  # The three runs share a directory, because that is the point: the second and third runs are
  # about what happens when the set already exists.
  #
  # @!attribute first_run
  #   @return [CommandResult] the result of the first run
  # @!attribute second_run
  #   @return [CommandResult] the result of the second run
  # @!attribute third_run
  #   @return [CommandResult] the result of the third run
  # @!attribute converted
  #   @return [Nokogiri::XML::Document] the set the first run wrote
  # @!attribute after_second
  #   @return [String] the contents of the written set after the second run
  # @!attribute after_third
  #   @return [String] the contents of the written set after the third run
  # @!attribute source
  #   @return [String] the path of the set that was converted
  # @!attribute source_before
  #   @return [String] the contents of the set that was converted, before the runs
  # @!attribute source_after
  #   @return [String] the contents of the set that was converted, after the runs
  CommandScenario = Struct.new(:first_run, :second_run, :third_run, :converted, :after_second,
                               :after_third, :source, :source_before, :source_after,
                               keyword_init: true)

  class << self
    # Reads a set as a document.
    #
    # The result is cached, because reading a set takes a couple of hundred milliseconds and
    # the answer does not change.
    #
    # @param path [String] the path of the set
    # @return [Nokogiri::XML::Document] the set
    def read_set(path)
      @read_sets ||= {}
      @read_sets[path] ||= Nokogiri::XML Zlib::GzipReader.open(path, &:read)
    end

    # The path of a copy of a set, in a directory of its own.
    #
    # The copy is made once, and the path is stable, so the conversions of the same set share
    # a directory.
    #
    # @param source [String] the path of the set to copy
    # @param name [String] the name of the directory, for a set that needs more than one
    # @return [String] the path of the copy
    def set_path(source, name = 'default')
      @set_paths ||= {}
      @set_paths[[source, name]] ||= begin
        path = File.join directory(source, name), 'set.als'
        FileUtils.cp source, path
        path
      end
    end

    # Converts a set to the Live 11 format, in this process, and returns the converted set.
    #
    # The conversion is done once for each set, and the result is shared by every example that
    # looks at it.
    #
    # @param source [String] the path of the set to convert
    # @return [Nokogiri::XML::Document] the converted set
    def in_process(source)
      @in_process ||= {}
      @in_process[source] ||= begin
        set = set_path source, 'in-process'
        capture_stdout { LiveSet.new(set).modify_als }
        read_set output_path(set)
      end
    end

    # Runs the live_set command on a set three times, and records what happened.
    #
    # The command is run in a directory of the set's own, so that the second and third runs
    # find the set that the first run wrote. This is what makes it possible to test what the
    # command does when the set it writes already exists.
    #
    # The scenario is done once for each set, and the result is shared by every example that
    # looks at it.
    #
    # @param source [String] the path of the set to convert
    # @return [CommandScenario] what happened
    def command_scenario(source)
      @command_scenarios ||= {}
      @command_scenarios[source] ||= begin
        set = set_path source, 'command'
        source_before = read_contents set

        first = run_command set
        converted = read_set output_path(set)

        second = run_command set
        after_second = read_contents output_path(set)

        third = run_command set, ['-f']
        after_third = read_contents output_path(set)

        CommandScenario.new first_run: first, second_run: second, third_run: third,
                            converted: converted, after_second: after_second,
                            after_third: after_third, source: set, source_before: source_before,
                            source_after: read_contents(set)
      end
    end

    # The path of the set that the conversion writes.
    #
    # @param set [String] the path of the set that is converted
    # @return [String] the path of the converted set
    def output_path(set)
      set.sub(/\.als\z/, '_11.als')
    end

    private

    # Runs the live_set command on a set.
    #
    # @param set [String] the path of the set to convert
    # @param args [Array<String>] the extra command line arguments
    # @return [CommandResult] the outcome of the command
    def run_command(set, args = [])
      output, status = Open3.capture2e({ 'VO_DEBUGGING' => '1' }, RbConfig.ruby, executable,
                                       '-11', *args, set)
      CommandResult.new status: status, output: output, path: output_path(set)
    end

    # Reads the contents of a set, without the compression.
    #
    # The gzip header holds the time the file was written, so two files with the same contents
    # are not the same bytes. The contents are what matters here.
    #
    # @param path [String] the path of the set
    # @return [String] the contents of the set
    def read_contents(path)
      Zlib::GzipReader.open(path, &:read)
    end

    # The path of the live_set executable in this repository.
    #
    # @return [String] the path
    def executable
      @executable ||= File.expand_path '../exe/live_set', __dir__
    end

    # The directory a set is copied to.
    #
    # @param source [String] the path of the set
    # @param name [String] the name of the directory
    # @return [String] the path of the directory
    def directory(source, name)
      @directories ||= {}
      @directories[[source, name]] ||= begin
        path = File.join root, "#{Digest::SHA256.hexdigest(source)[0, 12]}-#{name}"
        FileUtils.mkdir_p path
        path
      end
    end

    # The root of the temporary directories the copies are made in.
    #
    # @return [String] the path of the directory
    def root
      @root ||= begin
        path = Dir.mktmpdir 'live_set_spec_'
        at_exit { FileUtils.remove_entry path if File.directory? path }
        path
      end
    end

    # Runs a block, and returns what it wrote to stdout.
    #
    # The conversion says what it is doing, and that is of no interest to the examples, so it
    # is kept out of the spec output.
    #
    # @return [String] what the block wrote to stdout
    def capture_stdout
      original = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = original
    end
  end
end
