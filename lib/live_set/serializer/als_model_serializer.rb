require_relative 'device_cross_reference_serializer'
require_relative 'live_group_track_serializer'
require_relative 'live_samples_serializer'
require_relative 'live_track_serializer'
require_relative 'missing_samples_serializer'
require_relative 'p3s_compatibility'
require_relative 'report_header_serializer'
require_relative 'track_clip_cross_reference_serializer'

# Serializes an AlsModel as a markdown report.
class AlsModelSerializer
  # What a clip is, and what the marks on a clip mean.
  LEGEND = <<~TEXT.squish.freeze
    Clip properties include the name of the clip and the audio file.
    Clip references are found in session view slots, the arrangement, and a take lanes.
    Reference properties include launch method and warp mode.
    The take lanes of a track are under the track.
    The string `⚠ not in project` means the sample is not the project directory tree, so the set is not self-contained.
  TEXT

  # Creates a serializer for the given ALS model.
  #
  # @param als_model [AlsModel] the model to serialize
  def initialize(als_model)
    @als_model = als_model
  end

  # Returns the complete ALS model as markdown.
  #
  # @return [String] the serialized markdown for the entire ALS model
  def to_markdown
    header_block_section      = LiveHeaderSerializer.new(@als_model.header_block).to_markdown
    p3s_compatibility_section = P3SCompatibility.new(@als_model.live_set).to_markdown
    hierarchical_entities     = hierarchy_markdown
    missing_samples           = MissingSamplesSerializer.new(samples.missing).to_markdown
    samples_section           = LiveSamplesSerializer.new(samples).to_markdown
    device_track_xref         = DeviceCrossReferenceSerializer.new(devices).to_markdown
    track_clip_xref           = TrackClipCrossReferenceSerializer.new(@als_model.live_set).to_markdown

    <<~REPORT_END
      #{header_block_section}
      #{p3s_compatibility_section}
      #{hierarchical_entities}
      #{missing_samples}
      #{samples_section}
      #{device_track_xref}
      #{track_clip_xref}
    REPORT_END
  end

  private

  # The groups and the tracks at the top of the set, and the things under them.
  #
  # @return [String] the outline of the set
  def hierarchy_markdown
    lines = ['## Groups/Tracks/Clips/Devices', '']
    lines << LEGEND
    lines << ''
    lines << @als_model.live_set.top_level_numbered.map do |number, track|
      if track.group?
        LiveGroupTrackSerializer.new(track, number).to_markdown
      else
        LiveTrackSerializer.new(track, number).to_markdown
      end
    end.join("\n")
    lines.join("\n")
  end

  # The clips of the set.
  #
  # @return [LiveClips] the clips
  def clips
    @clips ||= LiveClips.new(@als_model.live_set)
  end

  # The samples of the set.
  #
  # @return [LiveSamples] the samples
  def samples
    @samples ||= LiveSamples.new clips.to_a
  end

  # The devices of the set, and the tracks they are on.
  #
  # @return [LiveDevices] the devices
  def devices
    @devices ||= LiveDevices.new(@als_model.live_set.top_level)
  end
end
