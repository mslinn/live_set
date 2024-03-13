require 'nokogiri'
require 'zlib'

class LiveSet
  def initialize(set_name)
    @set_name = set_name
    @contents = Zlib::GzipReader.open(set_name, &:readlines)
    @xml_doc = Nokogiri::Slop @contents.join("\n")

    @ableton = @xml_doc.Ableton
    minor_version = @ableton['MinorVersion']
    puts "Version #{minor_version}"

    exit if minor_version.start_with? '11.'

    modify_als
  end

  def modify_als
    @ableton['Creator'] = 'Ableton Live 11.3.21'
    @ableton['MajorVersion'] = '5'
    @ableton['MinorVersion'] = '11.0_11300'
    @ableton['Revision'] = '5ac24cad7c51ea0671d49e6b4885371f15b57c1e'
    @ableton['SchemaChangeCount'] = '3'

    @xml_doc.xpath('//ContentLanes').remove
    @xml_doc.xpath('//ExpressionLanes').remove

    new_contents = @xml_doc.to_xml.to_s
    new_contents.gsub! 'AudioOut/Main', 'AudioOut/Master'

    set_path = File.dirname @set_name
    new_set_name = File.basename @set_name, '.als'
    new_set_path = File.join set_path, "#{new_set_name}_11", '.als'
    puts "Writing #{new_set_path}"
    Zlib::GzipWriter.open(new_set_path) { |gz| gz.write new_contents }
  end
end
