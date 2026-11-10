require_relative '../../common/xml'

# One device from an Ableton track's device chain.
#
# The devices in a chain are the children of DeviceChain/DeviceChain/Devices. Each device is its own element: Eq8,
# GlueCompressor, Limiter, Saturator, and so on. A plug-in is a PluginDevice.
#
# A native Ableton device is never a PluginDevice — it is its own element, and the P3S has all of them. Every plug-in in
# the corpus is third-party, though the file does not say so: there is no Manufacturer element anywhere. See
# docs/als_notes.md, "The devices of a chain, and the plug-ins among them".
#
# A plug-in's name is in a different place depending on the plug-in format:
#
#   PluginDesc/VstPluginInfo/PlugName    for a VST2 plug-in PluginDesc/Vst3PluginInfo/Name        for a VST3 plug-in
#
# Both shapes are in real sets, and the VST3 shape has no PlugName at all. See docs/als_notes.md, "The devices of a
# chain, and the plug-ins among them".
class LiveDevice
  include Xml

  attr_reader :name, :manufacturer, :type

  # The element names that mean "this device is a plug-in".
  #
  # A PluginDevice is a plug-in. A Max for Live device is one of the elements
  # MAX_FOR_LIVE_ELEMENTS names, and Max for Live devices are supported on the P3S if they
  # are not CPU intensive, so it is treated separately.
  PLUGIN_ELEMENTS = %w[PluginDevice].freeze

  # The element names that mean "this device is a Max for Live device".
  #
  # The devices of a chain are the children of the `Devices` element of a device chain, and
  # a Max for Live device is a child of its own kind. Its element name says which kind it
  # is:
  #
  #   MxDeviceMidiEffect    a Max for Live MIDI effect
  #   MxDeviceInstrument    a Max for Live instrument
  #   MxDeviceAudioEffect   a Max for Live audio effect
  #
  # These are the class names of the Live Object Model. The name of the device is inside the
  # element, and says nothing about what the device is: there are hundreds of Max for Live
  # devices, and the element is what they all have in common.
  MAX_FOR_LIVE_ELEMENTS = %w[MxDeviceAudioEffect MxDeviceInstrument MxDeviceMidiEffect].freeze

  # The element names that mean "this device holds other devices".
  #
  # An AudioEffectGroupDevice holds a group's device chain, in its branches. A DrumGroupDevice
  # holds a drum rack, and an InstrumentGroupDevice holds a rack. They are not devices that
  # process audio themselves, so they are not reported — but the devices they hold are, because
  # those are the devices that actually run.
  #
  # See docs/als_notes.md, "The device chain, and the chains nested inside it", and "Group Device
  # Chain".
  CONTAINER_ELEMENTS = %w[AudioEffectGroupDevice DrumGroupDevice InstrumentGroupDevice].freeze

  def initialize(node)
    @node = node
    @name         = device_name
    @manufacturer = xml_value(node.at('Manufacturer')) || ''
    @type         = xml_value(node.at('Type')) || xml_value(node.at('DeviceType')) || ''
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
  # they hold devices that do. See docs/als_notes.md, "The device chain, and the chains nested
  # inside it", and "Group Device Chain".
  #
  # @param element [Nokogiri::XML::Node, nil] the track or group element
  # @return [Array<Nokogiri::XML::Element>] the devices
  def self.chain_devices(element)
    return [] if element.nil?

    element.xpath('.//Devices/*').reject { |node| CONTAINER_ELEMENTS.include? node.name }
  end

  # The devices of an element itself, and not of the chain it is in.
  #
  # The chain of a track in a group holds the chain of the group, and the devices of that
  # chain belong to the group. A device of the group's chain is not a device of the track.
  #
  # @param element [Nokogiri::XML::Node, nil] the track or group element
  # @return [Array<Nokogiri::XML::Element>] the devices
  def self.own_devices(element)
    return [] if element.nil?

    element.xpath('.//Devices/*').reject do |node|
      CONTAINER_ELEMENTS.include?(node.name) ||
        node.ancestors.any? { |ancestor| CONTAINER_ELEMENTS.include? ancestor.name }
    end
  end

  # Whether the device stops the track from being transferred to P3S Standalone.
  #
  # A plug-in stops the transfer: the P3S Standalone cannot run one. A Max for Live device
  # is supported by the P3S Standalone, but with less CPU headroom, so it is a matter of
  # advice rather than of transfer. See README.md, "Push 3 Standalone (P3S)".
  #
  # @return true if the device is a plug-in
  def blocking?
    plug_in?
  end

  # @return true if the device is a plug-in
  def plug_in?
    PLUGIN_ELEMENTS.include? @node.name
  end

  # @return device manufacturer label
  def label
    @manufacturer.empty? ? @name : "#{@name} (#{@manufacturer})"
  end

  # What kind of device this is.
  #
  # A device of Live is a device of Live, whatever it does; a device of another company is a
  # plug-in, and the format of the plug-in is in its description.
  #
  # @return [String] the kind of the device
  def kind
    return 'M4L' if max_for_live?
    return plugin_format if plug_in?

    'Live'
  end

  # The format of a plug-in.
  #
  # The description of the plug-in says which format it is in.
  #
  # @return [String] the format
  def plugin_format
    description = @node.at('PluginDesc')
    return 'plug-in' if description.nil?

    case description.element_children.first&.name
    when 'VstPluginInfo' then 'VST2'
    when 'Vst3PluginInfo' then 'VST3'
    when 'AuPluginInfo' then 'Audio Unit'
    when 'ClapPluginInfo' then 'CLAP'
    else 'plug-in'
    end
  end

  # Whether the device is a Max for Live device.
  #
  # The element the device was built from is the whole of the answer. The name of the device
  # and the manufacturer are not consulted: the name is whatever the user called the device,
  # and no device of the corpus has a manufacturer.
  #
  # @return [Boolean] true when the device is a Max for Live device
  def max_for_live?
    MAX_FOR_LIVE_ELEMENTS.include? @node.name
  end

  private

  # The device's name.
  #
  # A plug-in's name is in its PluginDesc, and where it is depends on the plug-in format. A native
  # device's name is in its own Name element.
  #
  # @return [String] the name
  def device_name
    plugin_name || native_name || @node.name
  end

  # The name of a plug-in, from its PluginDesc.
  #
  # @return [String, nil] the name, or nil if the device is not a plug-in or has no name
  def plugin_name
    return nil unless plug_in?

    desc = @node.at('PluginDesc')
    return nil if desc.nil?

    # A VST2 plug-in names itself PlugName; a VST3 plug-in names itself Name.
    xml_first_value(
      desc.at('VstPluginInfo/PlugName'),
      desc.at('Vst3PluginInfo/Name')
    )
  end

  # The name of a native device.
  #
  # @return [String, nil] the name, or nil if the device has no name
  def native_name
    xml_first_value(
      @node.at('Name/EffectiveName'),
      @node.at('Name/UserName'),
      @node.at('Name')
    )
  end
end
