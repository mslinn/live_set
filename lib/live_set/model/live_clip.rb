require_relative '../../common/xml'
require_relative 'live_clip_settings'

# One clip in a set.
#
# A clip belongs to a place: a slot of the session view, a position on the arrangement
# timeline, or a take lane. Each of those holds the whole clip, so there is no clip in a
# set that the places point at. See docs/als_notes.md, "Every place holds its own clip".
#
# not implemented: parsing of elements Loop, TimeSignature, Envelopes, Onsets,
# GrooveSettings, ScaleInformation and PerNoteEventStore
class LiveClip
  include Xml

  # The mark of a clip whose sample is not in the project.
  NOT_COLLECTED = '⚠ not in project'.freeze

  attr_reader :name, :file, :color, :place, :settings, :notes

  # @param element [Nokogiri::XML::Element] the clip
  # @param place [String, nil] where the clip is: `session view`, `arrangement`, or the
  #   number of the take lane it is in
  def initialize(element, place: nil)
    @element = element
    @place = place
    @name = name_of element
    @file = file_of element
    @color = element.at('Color')&.[]('Value')&.to_i
    @marks = marks_of element
    @settings = LiveClipSettings.new element
    @notes = notes_of element
  end

  # What is said about the clip.
  #
  # @return [Array<String>] the marks
  attr_reader :marks

  # Whether the clip is a MIDI clip.
  #
  # @return [Boolean] true when the clip holds notes and plays no file
  def midi?
    @element.name == 'MidiClip'
  end

  # Whether the file of the clip is in the project.
  #
  # A clip is collected when its file was copied into the project's `Samples/Imported/`
  # folder. See docs/als_notes.md, "Whether a sample has been collected".
  #
  # @return [Boolean] true when the file is in the project
  def collected?
    !file.nil? && file.start_with?('Samples/Imported/')
  end

  private

  # The name Live wrote for the clip.
  #
  # Live numbers the names of the tracks and clips that share a name, and the number is
  # not part of the name.
  #
  # @param element [Nokogiri::XML::Element] the clip
  # @return [String] the name
  def name_of(element)
    name = element.at('Name')&.[]('Value')
    return '(unnamed)' if name.nil? || name.empty?

    name.sub(/\A\d+-/, '')
  end

  # The file the clip plays.
  #
  # The relative path is the one to use: the absolute path is a fallback for a clip that has
  # no relative path. Live 12 writes an empty relative path for a sample that is not in
  # the project, and keeps only the absolute path of it.
  #
  # @param element [Nokogiri::XML::Element] the clip
  # @return [String, nil] the file, or nil when the clip plays no file
  def file_of(element)
    reference = element.at 'SampleRef/FileRef'
    return nil if reference.nil?

    relative = reference.at('RelativePath')&.[]('Value')
    return relative unless relative.nil? || relative.empty?

    absolute = reference.at('Path')&.[]('Value')
    absolute.nil? || absolute.empty? ? nil : absolute
  end

  # What is said about the clip.
  #
  # @param element [Nokogiri::XML::Element] the clip
  # @return [Array<String>] the marks
  def marks_of(element)
    marks = []
    marks << NOT_COLLECTED unless collected_in_project? element
    marks
  end

  # Whether the file of the clip is in the project.
  #
  # @param element [Nokogiri::XML::Element] the clip
  # @return [Boolean] true when the file is in the project
  def collected_in_project?(element)
    path = file_of element
    !path.nil? && path.start_with?('Samples/Imported/')
  end

  # The notes of a MIDI clip.
  #
  # The notes are in the key tracks of the clip, and the pitch of a note is the key of the
  # track it is in.
  #
  # @param element [Nokogiri::XML::Element] the clip
  # @return [Array<Hash>] the notes
  def notes_of(element)
    element.xpath('.//KeyTrack').flat_map do |key_track|
      pitch = key_track.at('MidiKey')&.[]('Value')&.to_i
      key_track.xpath('.//MidiNoteEvent').map do |note|
        {
          pitch:       pitch,
          time:        note['Time']&.to_f,
          duration:    note['Duration']&.to_f,
          velocity:    note['Velocity']&.to_i,
          probability: note['Probability']&.to_f,
          enabled:     note['IsEnabled'] == 'true',
        }
      end
    end
  end
end
