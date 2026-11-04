require 'markdown-tables'
require_relative '../live_palette'
require_relative '../model/live_clips'
require_relative 'live_clip_groups'
require_relative 'live_clip_serializer'
require_relative 'live_clips_serializer'
require_relative 'live_track_serializer'

# Writes the section of the report that crosses the tracks of the set with the clips they
# hold.
#
# The clips are the clips of the outline: a clip is the same clip when it has the same name,
# the same file, the same colour and the same state. A clip that is on more than one track
# is a clip the set shares, and it is marked as one.
class TrackClipCrossReferenceSerializer
  # Creates a serializer for the cross-reference of the tracks and the clips.
  #
  # @param tracks [LiveTracks] the tracks of the set
  def initialize(tracks)
    @tracks = tracks
  end

  # Returns the section as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = ['## Track / Clip Cross Reference', '']
    lines << '### Tracks and their clips'
    lines << ''
    lines << tracks_and_clips_table
    lines << ''
    lines << '### Clips and their tracks'
    lines << ''
    lines << clips_and_tracks_table
    lines.join("\n")
  end

  private

  # The tracks of the set, and the clips each of them holds.
  #
  # The clips of the take lanes of a track are the clips of the track as well, and are marked
  # with the lane they are in.
  #
  # @return [String] the table
  def tracks_and_clips_table
    rows = []
    @tracks.each_numbered_track do |number, track|
      places = places_of track, number
      next if places.empty?

      listed = places.map do |label, counts|
        "`#{LiveTrackSerializer.escape label}` " + counts.map { |place, count| "#{place} ×#{count}" }.join(', ')
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
  # A clip of a take lane is marked with the lane it is in.
  #
  # @return [String] the table
  def clips_and_tracks_table
    LiveClipsSerializer.new(LiveClips.new(@tracks)).to_markdown
  end

  # The places the clips of a track are in, and how many of them there are in each.
  #
  # @param track [LiveTrack, LiveGroup] the track
  # @param number [String] the number of the track
  # @return [Hash] each clip, the places it is in, and the number of them in each
  def places_of(track, number)
    return {} if track.group?

    places = Hash.new { |hash, key| hash[key] = Hash.new(0) }

    track.clips.each { |clip| places[clip_label(clip)][clip.place] += 1 }
    track.take_lanes.each_with_index do |lane, index|
      lane_number = "#{number}.#{index + 1}"
      lane.clips.each { |clip| places[clip_label(clip)]["take lane #{lane_number}"] += 1 }
    end

    places
  end

  # The tracks that hold each clip of the set.
  #
  # A track that holds a clip in its take lanes as well as in itself is one entry, and the
  # lanes it holds the clip in are named with it.
  #
  # @return [Hash] each clip, and the tracks that hold it
  def tracks_of_clips
    uses = Hash.new { |hash, key| hash[key] = {} }

    @tracks.each_numbered_track do |number, track|
      next if track.group?

      name = track_name(track)
      track.clips.each { |clip| holds_of uses, clip_label(clip), number, name }
      holds_of_lanes uses, track, number, name
    end

    uses.transform_values { |holds| holds.map { |number, hold| hold_line number, hold } }
  end

  # The record of a track that holds a clip.
  #
  # @param uses [Hash] the clips and the tracks that hold them
  # @param label [String] the name of the clip
  # @param number [String] the number of the track
  # @param name [String] the name of the track
  # @return [Hash] the record of the track
  def holds_of(uses, label, number, name)
    uses[label][number] ||= { name: name, lanes: [] }
  end

  # The take lanes of a track, and the clips of them.
  #
  # @param uses [Hash] the clips and the tracks that hold them
  # @param track [LiveTrack, LiveGroup] the track
  # @param number [String] the number of the track
  # @param name [String] the name of the track
  # @return [void]
  def holds_of_lanes(uses, track, number, name)
    track.take_lanes.each_with_index do |lane, index|
      lane_number = "#{number}.#{index + 1}"
      lane.clips.each do |clip|
        hold = holds_of uses, clip_label(clip), number, name
        hold[:lanes] << lane_number unless hold[:lanes].include? lane_number
      end
    end
  end

  # The line of a track that holds a clip.
  #
  # @param number [String] the number of the track
  # @param hold [Hash] the record of the track
  # @return [String] the line
  def hold_line(number, hold)
    lanes = hold[:lanes].empty? ? '' : " (take lane #{hold[:lanes].join(', ')})"
    "#{number} #{hold[:name]}#{lanes}"
  end

  # The name of a clip, as the cross-reference names it.
  #
  # @param clip [LiveClip] the clip
  # @return [String] the name
  def clip_label(clip)
    clip.file.nil? ? clip.name : File.basename(clip.file, File.extname(clip.file))
  end

  # The name of a track.
  #
  # @param track [LiveTrack, LiveGroup] the track
  # @return [String] the name
  def track_name(track)
    LiveTrackSerializer.display_name track
  end

  # The name of a track, on the colour Live gave it.
  #
  # @param track [LiveTrack, LiveGroup] the track
  # @return [String] the name
  def track_label(track)
    name = track_name(track)
    if track.problem?
      return LiveTrackSerializer.colored_code LiveTrackSerializer.escape(name),
                                              background_color: LiveTrackSerializer::DARK_BACKGROUND,
                                              foreground_color: LiveTrackSerializer::LIGHT_TEXT
    end

    color = LivePalette.color_of track.color
    return "<code>#{LiveTrackSerializer.escape name}</code>" unless color

    LiveTrackSerializer.colored_code LiveTrackSerializer.escape(name),
                                     color_number:     track.color,
                                     background_color: "##{color}",
                                     foreground_color: LiveTrackSerializer.text_color(color)
  end
end
