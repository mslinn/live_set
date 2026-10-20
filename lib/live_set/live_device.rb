# One <Device/> node from an Ableton track's device chain.
class LiveDevice
  attr_reader :name, :manufacturer, :type

  # Explicit plugin markers seen in .als files across Live versions.
  PLUGIN_MARKERS = %w[
    VstPlugin VstPluginCategory VstPreset VstId
    AudioUnitPlugin AudioUnitPreset AudioComponent
    ClapPlugin PluginId
  ].freeze

  def initialize(node)
    @node = node
    preset = node.at('.//PresetManifestV1') || node.at('.//CurrentPreset') || node

    @name         = value_of(preset, 'Name') || value_of(node, 'Name') || 'Unnamed device'
    @manufacturer = value_of(preset, 'Manufacturer') || ''
    @type         = value_of(node, 'Type') || value_of(node, 'DeviceType') || ''
  end

  # @return true if device is not made by ableton or uses max4live
  def blocking?
    third_party? || max_for_live?
  end

  # @return device manufacturer label
  def label
    @manufacturer.empty? ? @name : "#{@name} (#{@manufacturer})"
  end

  private

  # @return true if Native to Live, but not available in the standalone runtime.
  def max_for_live?
    "#{@manufacturer} #{@name}".match?(/max\s*for\s*live|\bM4L\b|^Max\b/i)
  end

  # @return true if a device was not manufactured by Ableton
  def third_party?
    return true unless @manufacturer.empty? || @manufacturer.casecmp?('Ableton')

    PLUGIN_MARKERS.any? { |tag| @node.at(".//#{tag}") }
  end

  # @return XML value of a node at the given tag
  def value_of(node, tag)
    el = node.at(tag)
    return nil unless el

    el['Value'] ||
      el.at('EffectiveName')&.[]('Value') ||
      el.text.strip.then { |s| s.empty? ? nil : s }
  end
end
