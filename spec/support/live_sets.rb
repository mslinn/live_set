require 'nokogiri'
require 'zlib'
require 'demo_sets'

# Real Live sets, and the elements in them.
#
# The examples that read a set read a real one. A document written to look like a set proves
# that the code agrees with the author's idea of the format, and not that the code reads the
# format.
#
# Two sets are used:
#
#   The Live 11 Suite demo set is the largest of the Live 11 demo sets by content: fourteen
#   audio tracks, a group track, and 255 clips. It is a set Ableton ships, so it is the same
#   for everyone who has Live 11 installed.
#
#   Fascination.als is checked in, and is the only set in the corpus with a third-party device
#   in it. It is a set by a user of Live, not a demo set of Ableton. See sets/README.md.
module LiveSets
  class << self
    # The Live 11 Suite demo set.
    #
    # @return [String] the path of the set
    def suite
      DemoSets.edition '11', 'Suite'
    end

    # The checked-in set with return tracks and a third-party device.
    #
    # @return [String] the path of the set
    def fascination
      File.expand_path '../../sets/live_11/Fascination.als', __dir__
    end

    # The Live 12 version of the checked-in set with return tracks and a third-party device.
    #
    # Live 12 saves a set as a project folder, and the set is the .als file in it.
    #
    # @return [String] the path of the set
    def fascination12
      path = 'sets/live_12/Fascination_12_converted_by_live Project/Fascination_12_converted_by_live.als'
      File.expand_path "../../#{path}", __dir__
    end

    # The document of a set.
    #
    # The document is decorated the way LiveSet decorates it, so that the elements of it answer
    # to the names of their children.
    #
    # @param path [String] the path of the set
    # @return [Nokogiri::XML::Document] the set
    def document(path)
      @documents ||= {}
      @documents[path] ||= Nokogiri::Slop(Zlib::GzipReader.open(path, &:read))
    end

    # The elements of a set that match an XPath expression.
    #
    # @param path [String] the path of the set
    # @param xpath [String] the XPath expression
    # @return [Array<Nokogiri::XML::Element>] the elements
    def nodes(path, xpath)
      document(path).xpath(xpath)
    end

    # The first element of a set that matches an XPath expression.
    #
    # @param path [String] the path of the set
    # @param xpath [String] the XPath expression
    # @return [Nokogiri::XML::Element, nil] the element
    def node(path, xpath)
      nodes(path, xpath).first
    end

    # The directory of a set, which is where the samples of the set are looked for.
    #
    # @param path [String] the path of the set
    # @return [String] the path of the directory
    def directory(path)
      File.dirname path
    end

    # A copy of an element, with the value of one of its attributes changed.
    #
    # A case that no set in the corpus holds is made by copying a real element and changing one
    # value in it. The document is real; only the one value differs.
    #
    # @param element [Nokogiri::XML::Element] the element to copy
    # @param name [String] the name of the attribute
    # @param value [String] the value the attribute is given
    # @return [Nokogiri::XML::Element] the copy
    def with_attribute(element, name, value)
      copy = Nokogiri::Slop(element.to_xml)
      copied = copy.at_xpath('//*')
      copied[name] = value
      copied
    end

    # A copy of an element, with one of its children removed.
    #
    # @param element [Nokogiri::XML::Element] the element to copy
    # @param xpath [String] the XPath expression that names the child
    # @return [Nokogiri::XML::Element] the copy
    def without(element, xpath)
      copy = Nokogiri::Slop(element.to_xml)
      copied = copy.at_xpath('//*')
      copied.xpath(xpath).each(&:remove)
      copied
    end

    # A copy of a track that is frozen, and whose clips are in its FreezeSequencer.
    #
    # No set in the corpus holds a frozen track. Every track of every set is unfrozen, and every
    # FreezeSequencer of every track is empty, so the case of a track whose clips are only in the
    # FreezeSequencer is made by moving the clips of a real track from one sequencer to the
    # other. The track is real, the clips are real, and the only thing that differs is the
    # sequencer the clips sit in, which is the thing the reader has to get right.
    #
    # @param track [Nokogiri::XML::Element] the track element
    # @param keep_main [Boolean] true to leave the clips in the MainSequencer as well
    # @return [Nokogiri::XML::Element] the copy
    def frozen_with_clips_in_freeze_sequencer(track, keep_main: false)
      copy = Nokogiri::Slop(track.to_xml)
      copied = copy.at_xpath('//*')
      main = copied.at_xpath('./DeviceChain/MainSequencer')
      freeze = copied.at_xpath('./DeviceChain/FreezeSequencer')

      moved = main.dup(1)
      moved.name = 'FreezeSequencer'
      freeze.replace moved
      main.remove unless keep_main

      copied.at_xpath('./Freeze')['Value'] = 'true'
      copied
    end
  end
end
