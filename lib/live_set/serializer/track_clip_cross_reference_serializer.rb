require 'markdown-tables'
require_relative '../model/live_palette'
require_relative 'live_midi_clip_groups'
require_relative 'live_midi_clip_serializer'
require_relative 'live_markup'

# Writes the section of the report that crosses the tracks of the set with the clips they
# hold.
#
# Sample usage:
# markdown = TrackClipCrossReferenceSerializer.new(cross_reference).to_markdown
class TrackClipCrossReferenceSerializer
  # Creates a serializer for the cross-reference of the tracks and the clips.
  #
  # @param cross_reference [LiveTrackClipCrossReference] the tracks and the clips
  def initialize(cross_reference)
    @cross_reference = cross_reference
  end

  # Returns the section as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = ['## Track / Clip Cross Reference', '']
    lines << '### Tracks And Their Clips'
    lines << ''
    lines << tracks_and_clips_table
    lines << ''
    lines << '### Clips And Their Tracks'
    lines << ''
    lines << clips_and_tracks_table
    lines.join("\n")
  end

  private

  # The tracks of the set, and the clips each of them holds.
  #
  # @return [String] the table
  def tracks_and_clips_table
    rows = []
    @cross_reference.tracks.each do |number, track|
      places = @cross_reference.places_of track, number
      next if places.empty?

      listed = places.map do |label, counts|
        "`#{LiveMarkup.escape label}` " + counts.map { |place, count| "#{place} ×#{count}" }.join(', ')
      end
      rows << [track_name(track), "#{number} #{track_label(track)}", listed.join('; ')]
    end
    return 'The set has no clips.' if rows.empty?

    rows.sort_by! { |row| row[0].downcase }
    MarkdownTables.make_table(%w[Track Clips], rows.map { |_, track, clips| [track, clips] },
                              align: %w[l l], is_rows: true)
  end

  # The clips of the set, and the tracks that hold them.
  #
  # @return [String] the table
  def clips_and_tracks_table
    uses = @cross_reference.tracks_of_clips
    rows = uses.sort_by { |clip, _| clip.downcase }.map do |clip, tracks|
      ["`#{LiveMarkup.escape clip}`", tracks.join(', ')]
    end
    return 'The set has no clips.' if rows.empty?

    MarkdownTables.make_table(%w[Clip Tracks], rows, align: %w[l l], is_rows: true)
  end

  # The name of a track.
  #
  # @param track [LiveTrack, LiveGroup] the track
  # @return [String] the name
  def track_name(track)
    track.display_name
  end

  # The name of a track, on the colour Live gave it.
  #
  # The name is in a table cell, so it is written without a line break.
  #
  # @param track [LiveTrack, LiveGroup] the track
  # @return [String] the name
  def track_label(track)
    LiveMarkup.track_name_markdown track, track_name(track), in_a_cell: true
  end
end
