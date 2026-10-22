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
  # Reads the value of an XML element.
  #
  # Every value in an .als file is stored in a `Value` attribute, e.g.
  # `<EffectiveName Value="My Track" />`. This was verified against a corpus of 460 sets, in every
  # Live version from 8.2 to 12.4.
  #
  # An element that has no `Value` attribute, or an empty one, holds no value and yields nil. An
  # empty attribute is not the same as an absent one: `<RelativePath Value="" />` means the
  # sample is not in the project folder, while an absent `<RelativePath>` means the field is not
  # in this version of the file. Both yield nil here, because every caller treats them alike.
  #
  # @param element [Nokogiri::XML::Node, nil] the element to read
  # @return [String, nil] the value, or nil if the element is missing or holds no value
  def xml_value(element)
    return nil if element.nil?

    value = element['Value']
    value.nil? || value.empty? ? nil : value
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

  # The devices in a track's device chain.
  #
  # The devices are the children of a Devices element. The path to the top-level one is doubled:
  # the track's DeviceChain contains a DeviceChain, which contains Devices.
  #
  # A chain can be nested. An AudioEffectGroupDevice holds a group's device chain in its branches,
  # and a DrumGroupDevice holds a drum rack, so a track's real devices can be several levels down.
  # Every device in the chain is found, at any depth.
  #
  # The container devices themselves are not returned. They are not devices that process audio —
  # they hold devices that do. See docs/als_format.md sections 8.1 and 9.3.
  #
  # @param element [Nokogiri::XML::Node, nil] the track or group element
  # @return [Array<Nokogiri::XML::Element>] the devices
  def xml_chain_devices(element)
    return [] if element.nil?

    element.xpath('.//Devices/*').reject { |node| LiveDevice::CONTAINER_ELEMENTS.include? node.name }
  end
end
