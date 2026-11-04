require_relative '../../common/xml'

# The settings of a clip: how it is launched, and how its sample is warped.
#
# The settings belong to the clip element they are written in. Every place a clip is in
# holds the whole clip, and each of those copies has its own settings. See
# docs/als_notes.md, "Every place holds its own clip".
#
# not implemented: parsing of elements WarpMarkers, GrainSize, TransientLoopMode and the
# attributes of a note other than its pitch, time, duration, velocity, probability and
# whether it is enabled
class LiveClipSettings
  include Xml

  # The ways a clip can be launched.
  LAUNCH_MODES = { 0 => 'trigger', 1 => 'toggle', 2 => 'gate' }.freeze

  # The warp modes of a sample, in the order of the manual.
  #
  # The number Live writes for the mode is the number of the mode in the manual: Beats,
  # Tones, Texture, Re-Pitch, Complex, and, in Live 12, Complex Pro.
  #
  # See "Warp Modes" in the manual of Live 12, section 9.3:
  # https://www.ableton.com/en/live-manual/12/audio-clips-tempo-and-warping/#warp-modes
  WARP_MODES = {
    0 => 'Beats', 1 => 'Tones', 2 => 'Texture', 3 => 'Re-Pitch', 4 => 'Complex', 5 => 'Complex Pro'
  }.freeze

  # @param element [Nokogiri::XML::Element] the clip
  def initialize(element)
    @element = element
  end

  # How the clip is launched.
  #
  # @return [String, nil] the way it is launched, or nil when the clip says nothing
  def launch_mode
    value = @element.at('LaunchMode')&.[]('Value')
    return nil if value.nil?

    LAUNCH_MODES.fetch value.to_i, value
  end

  # How the sample of the clip is warped.
  #
  # A MIDI clip has no sample and is not warped.
  #
  # @return [String, nil] the name of the mode, or nil when the clip has no warp mode
  def warp_mode
    value = @element.at('WarpMode')&.[]('Value')
    return nil if value.nil?

    WARP_MODES.fetch value.to_i, 'unknown'
  end

  # Whether the sample of the clip is warped.
  #
  # The warp mode is written whether the sample is warped or not, so the mode says nothing
  # about it on its own.
  #
  # @return [Boolean] true when the sample is warped
  def warped?
    @element.at('IsWarped')&.[]('Value') == 'true'
  end

  # Whether the clip is disabled.
  #
  # @return [Boolean] true when the clip is disabled
  def disabled?
    @element.at('Disabled')&.[]('Value') == 'true'
  end
end
