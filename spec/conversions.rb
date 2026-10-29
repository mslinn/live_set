require 'digest'
require 'fileutils'
require 'nokogiri'
require 'tmpdir'
require 'zlib'

# Helpers for converting a Live set to the Live 11 format, and for reading the result.
#
# A conversion is not free, so these helpers convert each set once and cache the result. The
# examples that look at the same conversion share one. The cache is keyed by the set, so
# different sets are still handled separately.
#
# The sets that are converted are copies. Nothing here writes to the demo sets themselves.
module Conversions
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
        silence_output { LiveSet.new(set).modify_als }
        read_set output_path(set)
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
  end
end
