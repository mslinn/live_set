require 'nokogiri'
require_relative 'log'

# Helpers for reading values out of Ableton Live's XML.
#
# Ableton stores the same kind of value in more than one shape, and the shape changed between
# Live versions:
#
#   As an attribute:  <EffectiveName Value="My Track" />
#   As text:          <EffectiveName>My Track</EffectiveName>
#   As nested text:   <Path><Path>E:/media/song.mp3</Path></Path>
#
# Rather than have every call site guess which shape it is looking at, put the guess in one place.
# Mix this module into a class that needs to read XML values:
#
#   class LiveTrack
#     include Xml
#
#     def name
#       xml_value(@audio_track.at('Name/EffectiveName')) || "##{@id}"
#     end
#   end
module Xml
  # Reads the value of an XML element, whichever shape the value is stored in.
  #
  # The rules, in order:
  #
  # 1. A `Value` attribute wins, if it is present and not empty. This is the shape Live 8 uses
  #    for scalars: `<EffectiveName Value="My Track" />`.
  # 2. Otherwise the element's text is used, stripped of surrounding whitespace. Nokogiri's
  #    `Node#text` recurses into child elements, so this also covers the nested-text shape:
  #    `<Path><Path>E:/media/song.mp3</Path></Path>`.
  # 3. If there is no usable value, `nil` is returned. Callers can then use `||` to fall back to
  #    a different element, which is why blank strings are reported as `nil` rather than `""`.
  #
  # @param element [Nokogiri::XML::Node, nil] the element to read
  # @return [String, nil] the value, or nil if the element is missing or holds no value
  def xml_value(element)
    return nil if element.nil?

    value = element['Value']
    return value unless value.nil? || value.empty?

    text = element.text.strip
    text.empty? ? nil : text
  end

  # Reads the value of the first of several elements that holds one.
  #
  # @param elements [Array<Nokogiri::XML::Node, nil>] the candidate elements, in preference order
  # @return [String, nil] the first value found, or nil if none of them holds one
  def xml_first_value(*elements)
    elements.each do |element|
      value = xml_value(element)
      return value unless value.nil?
    end

    nil
  end

  # Reads a boolean value from an XML element, whichever shape the value is stored in.
  #
  # The result is always true or false, never nil.
  #
  # A missing element means false. For example, an AudioTrack with no <Freeze> element is not
  # frozen. This is the convention for every boolean read: absent means "no".
  #
  # A value that is neither "true" nor "false" is also false, but is reported, so that malformed
  # data does not pass unnoticed.
  #
  # @param element [Nokogiri::XML::Node, nil] the element to read
  # @param description [String, nil] what the element means, used in the warning
  # @return [Boolean] true or false
  def xml_bool?(element, description: nil)
    value = xml_value(element)
    return false if value.nil?

    return true if value.casecmp('true').zero?
    return false if value.casecmp('false').zero?

    Log.warn "Ignoring unrecognized boolean value #{value.inspect}#{" for #{description}" if description}"
    false
  end
end
