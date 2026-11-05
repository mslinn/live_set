require_relative '../../common/xml'
require_relative 'live_clip_settings'

# A MIDI clip of a track.
#
# A MIDI clip holds notes and plays no file. The clip of the audio side of a track is
# `LiveAudioClip`, and it is a different thing: it holds a file, it has a size, and it has
# no notes.
#
# The model holds no number: the XML has no notion of a clip number, and the serializer
# generates the numbers of the report.
#
# not implemented: parsing of elements Loop, TimeSignature, Envelopes, Onsets,
# GrooveSettings, ScaleInformation and PerNoteEventStore
class LiveMidiClip
  include Xml

  attr_reader :name, :color, :place, :settings, :notes

  # @param element [Nokogiri::XML::Element] the clip
  # @param place [String, nil] where the clip is: `session view`, `arrangement`, or the
  #   number of the take lane it is in
  def initialize(element, place: nil)
    @element = element
    @place = place
    @name = name_of element
    @color = element.at('Color')&.[]('Value')&.to_i
    @settings = LiveClipSettings.new element
    @notes = notes_of element
  end

  # What makes a clip the same clip as another.
  #
  # The copies of a clip that are alike are counted together, and the report writes them as
  # one line.
  #
  # @return [String] the key of the clip
  def key
    name
  end

  # The name the cross-reference names the clip by.
  #
  # @return [String] the name
  def label
    name
  end

  # Whether the clip holds notes and plays no file.
  #
  # @return [Boolean] true, always
  def midi?
    true
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
