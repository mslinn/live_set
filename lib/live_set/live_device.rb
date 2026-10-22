# One <Device/> node from an Ableton track's device chain.
#
# TODO.md N16: this class does not work. It looks for a <Device/> element, but no real set has
# one — a survey of 40 sets in $songs found zero <Device/> elements, and the plugins are in
# <PluginDevice/> elements instead. The name is not where this class looks for it either: it is
# under <PluginDesc><VstPluginInfo><PlugName Value="..."/></VstPluginInfo></PluginDesc>, and there
# is no <Manufacturer/> element at all. Fixing it is low priority, and the first step is to
# determine whether a <PluginDevice/> is by definition a third-party plugin.
class LiveDevice
  attr_reader :name, :manufacturer, :type

  # Explicit plugin markers seen in .als files across Live versions.
  # TODO.md N16: of these, only VstPreset was found in the survey, and only in one set.
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

    # Prefer an explicit Value attribute, whether on the element itself or on a nested EffectiveName.
    value = el['Value'] || el.at('EffectiveName')&.[]('Value')
    return value if value

    text = el.text.strip
    text.empty? ? nil : text
  end
end
