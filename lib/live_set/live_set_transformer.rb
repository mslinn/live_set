require 'nokogiri'

# Applies an XSLT stylesheet to a Live set.
#
# The stylesheets are in the tx subdirectory of this directory. Each one converts a set from one
# version of the Live format to another.
#
# The result is a document, not a file. Writing the file is the job of AlsFile, because libxml2
# does not write XML the way Live does. See LiveXmlWriter.
class LiveSetTransformer
  # The directory the stylesheets are in.
  STYLESHEET_DIRECTORY = File.expand_path('tx', __dir__)

  # The path of a stylesheet.
  #
  # @param name [String] the name of the stylesheet, without its extension
  # @return [String] the path of the stylesheet
  def self.stylesheet_path(name)
    File.join(STYLESHEET_DIRECTORY, "#{name}.xsl")
  end

  # @param name [String] the name of the stylesheet, without its extension
  def initialize(name)
    @path = self.class.stylesheet_path(name)
    @stylesheet = Nokogiri::XSLT(File.read(@path))
  end

  # Applies the stylesheet to a document.
  #
  # @param document [Nokogiri::XML::Document] the document to transform
  # @return [Nokogiri::XML::Document] the transformed document
  def transform(document)
    @stylesheet.transform(document)
  end
end
