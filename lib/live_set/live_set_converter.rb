require 'colorator'
require_relative '../common/log'
require_relative 'als_file'
require_relative 'live_set_transformer'

# Converts a Live set to the Live 11 format.
#
# The conversion itself is done by LiveSetTransformer, which finds the bridge for the version of
# the set and applies it. This class reads the set, hands the document to the transformer, and
# writes the result.
#
# See docs/live_11_12_differences.md for the rules, and docs/cpfir.md for the architecture.
class LiveSetConverter
  # @param set_name [String] the path of the set to convert
  # @param xml_doc [Nokogiri::XML::Document] the set to convert
  # @param overwrite [Boolean] whether an existing converted set may be overwritten
  def initialize(set_name, xml_doc, overwrite: false)
    @set_name = set_name
    @xml_doc = xml_doc
    @overwrite = overwrite
  end

  # Converts the set, and writes the converted set next to the set that was converted.
  #
  # @return [void]
  def convert
    write_conversion(transform)
  end

  private

  # Converts the set.
  #
  # @return [Nokogiri::XML::Document] the converted set
  def transform
    LiveSetTransformer.new(@xml_doc).transform
  end

  # Writes the converted set next to the set that was converted.
  #
  # An existing set is not overwritten unless the user asks for it. The gzip writer truncates the
  # file it opens, so without this check a conversion would silently destroy the previous result.
  #
  # The set is written the way Live writes it, so that the converted set is a Live 11 set and not
  # merely XML that happens to mean the same thing.
  #
  # @param document [Nokogiri::XML::Document] the converted set
  # @return [void]
  def write_conversion(document)
    set_path = File.dirname @set_name
    new_set_name = File.basename @set_name, '.als'
    new_set_path = File.join set_path, "#{new_set_name}_11.als"

    if File.exist? new_set_path
      abort "Error: #{new_set_path} already exists. Use -f to overwrite it." unless @overwrite

      puts "Overwriting existing #{new_set_path}".green
    else
      puts "Writing #{new_set_path}".green
    end

    AlsFile.write(new_set_path, document, File.mtime(@set_name))
    puts 'Conversion complete'.green
  end
end
