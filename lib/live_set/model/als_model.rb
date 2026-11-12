require_relative '../report_context'
require_relative 'header_block'
require_relative 'live_assets'
require_relative 'live_checksums'
require_relative 'live_master_track'
require_relative 'live_packs'
require_relative 'live_project_info'
require_relative 'live_samples'
require_relative 'live_sizes'
require_relative 'live_tracks'

# The complete model of the contents of an ALS file.
#
# The file is a set: the XML of it, the times of it, and the Live contents of it.
class AlsModel
  attr_reader :path, :xml, :file_created, :file_last_modified, :time_zone

  # @param path [String] the path of the file
  # @param xml [Nokogiri::XML::Document] the XML of the file
  # @param header_block [HeaderBlock] the facts about the set, which hold the times of it
  # @param context [ReportContext] what the report is about, and what it may say
  # @param show_midi_and_audio_tracks_separately [Boolean] whether the audio tracks and the
  #   MIDI tracks of the set are written in their own lists
  def initialize(path, xml, header_block, context: ReportContext.new, show_midi_and_audio_tracks_separately: false)
    @path = path
    @xml = xml
    @header_block = header_block
    @file_created = header_block.set_created_at
    @file_last_modified = header_block.set_last_modified_at
    @time_zone = header_block.time_zone
    @context = context
    @show_midi_and_audio_tracks_separately = show_midi_and_audio_tracks_separately
  end

  # What the report is about, and what it may say.
  #
  # @return [ReportContext] the context of the report
  attr_reader :context

  # Whether the audio tracks and the MIDI tracks of the set are written in their own lists.
  #
  # By default, every track is written in the order Live saved it in.
  #
  # @return [Boolean] true when the two kinds of track have their own lists
  attr_reader :show_midi_and_audio_tracks_separately

  # The Live contents of the file.
  #
  # Every track of the set is in the model: the MIDI tracks, the audio tracks, the groups
  # and the return tracks, in the order Live wrote them.
  #
  # @return [LiveTracks] the tracks of the set
  def live_set
    @live_set ||= LiveTracks.new directory, track_elements
  end

  # The one and only master track in the set.
  #
  # The master track is a child of the set and not one of the tracks of the set. Live has
  # one master track, and a set has one element for it.
  #
  # @return [LiveMasterTrack] the master track
  def master_track
    @master_track ||= LiveMasterTrack.new directory, master_track_element
  end

  # The facts about the file.
  #
  # @return [HeaderBlock] the facts about the set
  attr_reader :header_block

  # The external assets of the set: every file it refers to.
  #
  # @return [LiveAssets] the assets
  def assets
    @assets ||= LiveAssets.new directory, xml
  end

  # The sizes of the set.
  #
  # @return [LiveSizes] the sizes
  def sizes
    @sizes ||= LiveSizes.new path, assets
  end

  # The samples of the set: the files it plays.
  #
  # @return [LiveSamples] the samples
  def samples
    @samples ||= LiveSamples.new(live_set.audio_clips, directory)
  end

  # The packs the set refers to.
  #
  # @return [LivePacks] the packs
  def packs
    @packs ||= LivePacks.new(samples)
  end

  # The checksums of the set: the hash of the file, and the hash of the content.
  #
  # @return [LiveChecksums] the checksums
  def checksums
    @checksums ||= LiveChecksums.new path
  end

  # The 'Ableton Project Info' folders around the set.
  #
  # @return [LiveProjectInfo] the folders
  def project_info
    @project_info ||= LiveProjectInfo.new directory
  end

  # The directory the file is in.
  #
  # @return [String] the path of the directory
  def directory
    File.dirname File.expand_path(path)
  end

  private

  # The elements of the tracks of the set, in the order Live wrote them.
  #
  # @return [Array<Nokogiri::XML::Element>] the elements
  def track_elements
    xml.xpath('//MidiTrack | //AudioTrack | //GroupTrack | //Tracks/ReturnTrack')
  end

  # The element of the master track of the set.
  #
  # Live 12 writes the master track as a `<MainTrack>`, and the earlier versions write it
  # as a `<MasterTrack>`.
  #
  # @return [Nokogiri::XML::Element, nil] the element
  def master_track_element
    xml.at_xpath('//MasterTrack | //MainTrack')
  end
end
