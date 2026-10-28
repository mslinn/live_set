require 'nokogiri'
require 'zlib'
require_relative 'live_xml_writer'

# Reads and writes Ableton Live set files.
#
# A live set is an XML document, usually gzip-compressed. Reading a set gives the XML document;
# writing one takes an XML document and writes it in Live's own format, compressed.
#
# The XML is written by LiveXmlWriter, because libxml2 does not write it the way Live does.
class AlsFile
  # Reads the XML document of a live set.
  #
  # @param path [String] the path of the .als file
  # @return [Nokogiri::XML::Document] the XML document
  def self.read(path)
    Nokogiri::XML(read_text(path))
  end

  # Reads the XML of a live set, as text.
  #
  # Most sets are gzip-compressed. A set that is not compressed is read as it is.
  #
  # @param path [String] the path of the .als file
  # @return [String] the XML document
  def self.read_text(path)
    read_gzip_text(path)
  rescue Zlib::GzipFile::Error
    File.binread(path)
  end

  # Reads the XML of a live set, as text, and requires the set to be compressed.
  #
  # @param path [String] the path of the .als file
  # @return [String] the XML document
  # @raise [Zlib::GzipFile::Error] if the set is not gzip compressed
  def self.read_gzip_text(path)
    Zlib::GzipReader.open(path, &:read)
  end

  # Writes a live set.
  #
  # The timestamp is stored in the gzip header, which is the timestamp a program reading the set
  # sees. The filesystem timestamp of the file that is written is the time the file was created.
  #
  # @param path [String] the path of the .als file to write
  # @param document [Nokogiri::XML::Document] the XML document to write
  # @param mtime [Time] the timestamp to store in the gzip header
  # @return [void]
  def self.write(path, document, mtime)
    xml = LiveXmlWriter.new.write(document)

    Zlib::GzipWriter.open(path) do |gz|
      gz.mtime = mtime
      gz.write(xml)
    end
  end
end
