require_relative '../common/xml'

# One device from an Ableton track's device chain.
#
# The devices in a chain are the children of DeviceChain/DeviceChain/Devices. Each device is its
# own element: Eq8, GlueCompressor, Limiter, Saturator, and so on. A plug-in is a PluginDevice.
#
# A native Ableton device is never a PluginDevice — it is its own element, and the Push 3
# Standalone has all of them. Every plug-in in the corpus is third-party, though the file does not
# say so: there is no Manufacturer element anywhere. See docs/als_format.md section 8.
#
# A plug-in's name is in a different place depending on the plug-in format:
#
#   PluginDesc/VstPluginInfo/PlugName    for a VST2 plug-in
#   PluginDesc/Vst3PluginInfo/Name        for a VST3 plug-in
#
# Both shapes are in real sets, and the VST3 shape has no PlugName at all. See
# docs/als_format.md section 8.
class LiveDevice
  include Xml

  attr_reader :name, :manufacturer, :type

  # The element names that mean "this device is a plug-in".
  #
  # A PluginDevice is a plug-in. A Max for Live device is an MxDeviceAudioEffect, and Max for Live
  # is supported on the Push 3 but with less headroom, so it is treated separately.
  PLUGIN_ELEMENTS = %w[PluginDevice].freeze

  # The element names that mean "this device is a Max for Live device".
  MAX_FOR_LIVE_ELEMENTS = %w[MxDeviceAudioEffect].freeze

  # The element names that mean "this device holds other devices".
  #
  # An AudioEffectGroupDevice holds a group's device chain, in its branches. A DrumGroupDevice
  # holds a drum rack, and an InstrumentGroupDevice holds a rack. They are not devices that
  # process audio themselves, so they are not reported — but the devices they hold are, because
  # those are the devices that actually run.
  #
  # See docs/als_format.md sections 8.1 and 9.3.
  CONTAINER_ELEMENTS = %w[AudioEffectGroupDevice DrumGroupDevice InstrumentGroupDevice].freeze

  def initialize(node)
    @node = node
    @name         = device_name
    @manufacturer = xml_value(node.at('Manufacturer')) || ''
    @type         = xml_value(node.at('Type')) || xml_value(node.at('DeviceType')) || ''
  end

  # @return true if the device is a plug-in, or a Max for Live device
  def blocking?
    plug_in? || max_for_live?
  end

  # @return true if the device is a plug-in
  def plug_in?
    PLUGIN_ELEMENTS.include? @node.name
  end

  # @return device manufacturer label
  def label
    @manufacturer.empty? ? @name : "#{@name} (#{@manufacturer})"
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

  # @return true if the device is a Max for Live device
  def max_for_live?
    return true if MAX_FOR_LIVE_ELEMENTS.include? @node.name

    "#{@manufacturer} #{@name}".match?(/max\s*for\s*live|\bM4L\b/i)
  end
end
