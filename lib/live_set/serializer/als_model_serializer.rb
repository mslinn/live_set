require_relative '../../common/util'
require_relative '../model/hierarchical_number'
require_relative '../model/live_device_cross_reference'
require_relative '../model/live_devices'
require_relative '../model/live_track_clip_cross_reference'
require_relative 'device_cross_reference_serializer'
require_relative 'live_assets_serializer'
require_relative 'live_audio_tracks_serializer'
require_relative 'live_checksums_serializer'
require_relative 'live_group_serializer'
require_relative 'live_groups_serializer'
require_relative 'live_master_track_serializer'
require_relative 'live_midi_tracks_serializer'
require_relative 'live_machine_packs_serializer'
require_relative 'live_packs_serializer'
require_relative 'live_project_info_serializer'
require_relative 'live_return_tracks_serializer'
require_relative 'live_samples_serializer'
require_relative 'live_sizes_serializer'
require_relative 'live_tracks_serializer'
require_relative 'missing_samples_serializer'
require_relative 'p3s_compatibility'
require_relative 'report_header_serializer'
require_relative 'track_clip_cross_reference_serializer'

# Serializes an AlsModel as a markdown report.
class AlsModelSerializer
  # What a clip is, and what the messages for a clip mean.
  LEGEND = <<~TEXT.squish.freeze
    Clip properties include the name of the clip and the audio file.
    A clip is in a place: a slot of the session view, the arrangement, or a take lane.
    Each place holds the whole clip, and the settings of a clip are written in the place
    that holds it.
    The take lanes of a track are under the track.
    The string `⚠ missing` means the sample is not within the project directory tree,
    so the set is not self-contained.
  TEXT

  # Creates a serializer for the given ALS model.
  #
  # @param als_model [AlsModel] the model to serialize
  def initialize(als_model)
    @als_model = als_model
  end

  # Returns the complete ALS model as markdown.
  #
  # The model of a set is the report of the set: the title, the facts about the file, the
  # metadata of the set, the verdict for a transfer to P3S Standalone, the outline of the
  # tracks and the nodes under them, the samples that are not in the project, the samples of
  # the set, the two cross-references, the assets of the set, and the state of the machine
  # the report was made on.
  #
  # @return [String] the serialized markdown for the entire ALS model
  def to_markdown
    <<~REPORT_END
      # `#{File.basename @als_model.path}`

      #{header_block_section}

      #{metadata_section}

      #{p3s_compatibility_section}

      #{hierarchy_html}

      #{missing_samples}

      #{samples_section}

      #{device_track_xref}

      #{track_clip_xref}

      #{assets_section}

      #{packs_section}

      #{test_environment_section}
    REPORT_END
  end

  # The facts about the file.
  #
  # @return [String] the section
  def header_block_section
    LiveHeaderSerializer.new(@als_model.header_block, @als_model.context).to_markdown
  end

  # The metadata of the set: its sizes and its checksums.
  #
  # @return [String] the section
  def metadata_section
    ['## Metadata', '', sizes_section, '', checksums_section].join("\n")
  end

  # The state of the machine the report was made on.
  #
  # The 'Ableton Project Info' folders around the set, and the packs that are installed.
  #
  # The section is written only when the report was asked for the facts of the machine:
  # they are true of the machine, and not of the set.
  #
  # @return [String] the section
  def test_environment_section
    return '' unless machine?

    ['## Test Environment', '', project_info_section, '', machine_packs_section].join("\n")
  end

  # Whether the facts of the machine are written.
  #
  # @return [Boolean] true when the machine's facts are written
  def machine?
    @als_model.context.machine?
  end

  # The 'Ableton Project Info' folders around the set.
  #
  # @return [String] the section
  def project_info_section
    LiveProjectInfoSerializer.new(@als_model.project_info).to_markdown
  end

  # The packs the set refers to.
  #
  # @return [String] the section
  def packs_section
    LivePacksSerializer.new(@als_model.packs).to_markdown
  end

  # The packs that are on this machine, and the ones that are not.
  #
  # @return [String] the sections
  def machine_packs_section
    LiveMachinePacksSerializer.new(@als_model.packs).to_markdown
  end

  # The sizes of the set.
  #
  # @return [String] the section
  def sizes_section
    LiveSizesSerializer.new(@als_model.sizes).to_markdown
  end

  # The checksums of the set.
  #
  # @return [String] the section
  def checksums_section
    LiveChecksumsSerializer.new(@als_model.checksums).to_markdown
  end

  # The verdict for a transfer to P3S Standalone.
  #
  # @return [String] the section
  def p3s_compatibility_section
    P3SCompatibility.new(@als_model).to_markdown
  end

  # The samples of the set that are not in the project.
  #
  # @return [String] the section
  def missing_samples
    MissingSamplesSerializer.new(@als_model.samples.missing, machine: machine?).to_markdown
  end

  # The samples of the set.
  #
  # @return [String] the section
  def samples_section
    LiveSamplesSerializer.new(@als_model.samples).to_markdown
  end

  # The devices of the set, and the tracks they are on.
  #
  # @return [String] the section
  def device_track_xref
    DeviceCrossReferenceSerializer.new(devices).to_markdown
  end

  # The clips of the set, and the tracks that hold them.
  #
  # @return [String] the section
  def track_clip_xref
    TrackClipCrossReferenceSerializer.new(cross_reference).to_markdown
  end

  # The assets of the set.
  #
  # @return [String] the section
  def assets_section
    LiveAssetsSerializer.new(@als_model.assets, machine: machine?).to_markdown
  end

  # The groups and the tracks at the top of the set, and the nodes under them.
  #
  # The tracks of the set are written in the order they appear in the file. When they are to
  # be shown separately, the audio tracks and the MIDI tracks are written in their own
  # sections, and the return tracks and the master track have sections of their own.
  #
  # @param format [Symbol] the format the outline is written in
  # @return [String] the outline of the set
  def hierarchy(format)
    lines = ['## Groups/Tracks/Clips/Devices', '', LEGEND, '']

    lines.concat master_section(format)

    groups = LiveGroupsSerializer.new(@als_model.live_set.groups_of_the_set).public_send(format)
    unless groups.empty?
      lines << '### Groups'
      lines << ''
      lines << list(format, groups)
      lines << ''
    end

    lines.concat track_sections(format)

    lines.join("\n")
  end

  # The outline of the set, as markdown.
  #
  # @return [String] the outline of the set
  def hierarchy_markdown
    hierarchy :to_markdown
  end

  # The outline of the set, as HTML.
  #
  # The outline is a list of nodes that can be folded, so it is written as HTML: the
  # `<details>` and `<summary>` elements fold the nodes under a node.
  #
  # @return [String] the outline of the set
  def hierarchy_html
    hierarchy :to_html
  end

  # A list of nodes.
  #
  # The HTML of a list is a `<ul>` element; the markdown of a list is the lines of the
  # nodes.
  #
  # @param format [Symbol] the format the list is written in
  # @param content [String] the nodes of the list
  # @return [String] the list
  def list(format, content)
    return content unless format == :to_html

    "<ul style=\"list-style: none;\">\n#{content}\n</ul>"
  end

  # The sections of the tracks of the set.
  #
  # @param format [Symbol] the format the tracks are written in
  # @return [Array<String>] the lines of the sections
  def track_sections(format)
    return [section('### Ungrouped Tracks', list(format, tracks_serializer.public_send(format)))] unless separate_tracks?

    [
      section('### Audio Tracks', list(format, tracks_serializer.tracks_of_kind('Audio', format))),
      section('### MIDI Tracks', list(format, tracks_serializer.tracks_of_kind('MIDI', format))),
      section('### Return Tracks', list(format, tracks_serializer.tracks_of_kind('Return', format)))
    ].flatten
  end

  # The section of the master track of the set.
  #
  # @param format [Symbol] the format the track is written in
  # @return [Array<String>] the lines of the section
  def master_section(format)
    track = @als_model.master_track
    heading = "### #{track.icon} Master Track"
    content = LiveMasterTrackSerializer.new(track, master_track_number).public_send(format)
    section(heading, list(format, content))
  end

  # The number the master track has in the report.
  #
  # The master track is numbered after the tracks at the top of the set.
  #
  # @return [HierarchicalNumber] the number
  def master_track_number
    number = HierarchicalNumber.new LiveTracksSerializer::PREFIX
    number.increment @als_model.live_set.top_level_tracks.length
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

  # The devices of the set, and the tracks they are on.
  #
  # @return [LiveDeviceCrossReference] the cross-reference
  def devices
    @devices ||= LiveDeviceCrossReference.new(
      LiveDevices.new(@als_model.live_set.top_level + [@als_model.master_track])
    )
  end

  # The tracks of the set and the clips they hold, and the clips and the tracks that hold
  # them.
  #
  # @return [LiveTrackClipCrossReference] the cross-reference
  def cross_reference
    @cross_reference ||= LiveTrackClipCrossReference.new numbered_tracks
  end

  # The serializer of the tracks of the set.
  #
  # @return [LiveTracksSerializer] the serializer
  def tracks_serializer
    @tracks_serializer ||= LiveTracksSerializer.new @als_model.live_set
  end

  # Every track of the set, with the numbers they have in the report.
  #
  # The tracks at the top of the set are numbered from one, and the members of the groups are
  # numbered after the group they are in. The numbers are the ones the outline gives them.
  #
  # @return [Array<Array>] the number and the track
  def numbered_tracks
    @numbered_tracks ||= tracks_serializer.numbered_tracks
  end
end
