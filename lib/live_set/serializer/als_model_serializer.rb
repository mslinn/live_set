require_relative '../model/live_device_cross_reference'
require_relative '../model/live_devices'
require_relative '../model/live_track_clip_cross_reference'
require_relative 'device_cross_reference_serializer'
require_relative 'live_audio_tracks_serializer'
require_relative 'live_group_serializer'
require_relative 'live_groups_serializer'
require_relative 'live_master_tracks_serializer'
require_relative 'live_midi_tracks_serializer'
require_relative 'live_return_tracks_serializer'
require_relative 'live_samples_serializer'
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
    track_clip_xref           = TrackClipCrossReferenceSerializer.new(cross_reference).to_markdown

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

  # The groups and the tracks at the top of the set, and the things under them.
  #
  # The tracks of the set are written in the order Live wrote them. When they are to be
  # shown separately, the audio tracks and the MIDI tracks are written in their own
  # sections, and the return tracks and the master track have sections of their own.
  #
  # @return [String] the outline of the set
  def hierarchy_markdown
    lines = ['## Groups/Tracks/Clips/Devices', '', LEGEND, '']

    groups = LiveGroupsSerializer.new(@als_model.live_set.groups_of_the_set).to_markdown
    unless groups.empty?
      lines << '### Groups'
      lines << ''
      lines << groups
      lines << ''
    end

    lines.concat track_sections
    lines.concat master_section

    lines.join("\n")
  end

  # The sections of the tracks of the set.
  #
  # @return [Array<String>] the lines of the sections
  def track_sections
    return [section('### Tracks', @als_model.live_set.to_markdown)] unless separate_tracks?

    [
      section('### Audio Tracks', @als_model.live_set.audio_tracks.to_markdown),
      section('### MIDI Tracks', @als_model.live_set.midi_tracks.to_markdown),
      section('### Return Tracks', @als_model.live_set.return_tracks.to_markdown)
    ].flatten
  end

  # The section of the master track of the set.
  #
  # @return [Array<String>] the lines of the section
  def master_section
    master = @als_model.master_tracks.to_a.map do |track|
      track.to_markdown((@als_model.live_set.top_level_tracks.length + 1).to_s)
    end.join("\n")
    section('### Master Track', master)
  end

  # Whether the two kinds of track are written in their own sections.
  #
  # @return [Boolean] true when they are
  def separate_tracks?
    @als_model.show_midi_and_audio_tracks_separately
  end

  # A subsection of the outline: its heading, and the tracks under it.
  #
  # @param heading [String] the heading of the subsection
  # @param tracks [String] the tracks of the subsection
  # @return [Array<String>] the lines of the subsection
  def section(heading, tracks)
    return [] if tracks.empty?

    [heading, '', tracks, '']
  end

  private

  # The samples of the set.
  #
  # @return [LiveSamples] the samples
  def samples
    @samples ||= LiveSamples.new(@als_model.live_set.audio_clips)
  end

  # The devices of the set, and the tracks they are on.
  #
  # @return [LiveDeviceCrossReference] the cross-reference
  def devices
    @devices ||= LiveDeviceCrossReference.new(
      LiveDevices.new(@als_model.live_set.top_level + @als_model.master_tracks.to_a)
    )
  end

  # The tracks of the set and the clips they hold, and the clips and the tracks that hold
  # them.
  #
  # @return [LiveTrackClipCrossReference] the cross-reference
  def cross_reference
    @cross_reference ||= LiveTrackClipCrossReference.new @als_model.live_set
  end
end
