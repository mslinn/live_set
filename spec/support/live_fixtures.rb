require 'nokogiri'
require 'zlib'

# The test fixture data: the XML of a set, saved as text.
#
# The fixture is the XML of the largest Live 12 demo set, which exercises every feature of
# a set that the report reads: MIDI tracks, audio tracks, groups, return tracks, the master
# track, devices of every kind, clips in the session view, in the arrangement and in take
# lanes, and samples in the project and in the user library.
#
# The XML is saved gzipped, because it is 27 MB of text. See docs/serializer_plan.md,
# "Testing".
module LiveFixtures
  # The directory the fixture data is in.
  DIRECTORY = File.expand_path '../fixtures', __dir__

  class << self
    # The document of a fixture.
    #
    # @param name [String] the name of the fixture, without its extension
    # @return [Nokogiri::XML::Document] the document
    def document(name)
      @documents ||= {}
      @documents[name] ||= Nokogiri::Slop read(name)
    end

    # The text of a fixture.
    #
    # @param name [String] the name of the fixture, without its extension
    # @return [String] the text
    def read(name)
      Zlib::GzipReader.open path_of(name), &:read
    end

    # The path of a fixture.
    #
    # @param name [String] the name of the fixture, without its extension
    # @return [String] the path
    def path_of(name)
      File.join DIRECTORY, "#{name}.xml.gz"
    end

    # The directory of the fixture set.
    #
    # @param name [String] the name of the fixture, without its extension
    # @return [String] the path of the directory the set is in
    def directory_of(name)
      File.dirname path_of(name)
    end
  end
end
