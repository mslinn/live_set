require 'markdown-tables'
require_relative '../live_palette'
require_relative 'live_markup'

# Writes the table of the clips of the set, and the tracks that hold them.
#
# A clip of a take lane is marked with the lane it is in.
#
# Sample usage:
# markdown = LiveClipsSerializer.new(clips).to_markdown
class LiveClipsSerializer
  # Creates a serializer for the clips of the set.
  #
  # @param clips [LiveClips] the clips of the set
  def initialize(clips)
    @clips = clips
  end

  # Returns the table as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    rows = holds.sort_by { |clip, _| clip.downcase }.map do |clip, tracks|
      ["`#{LiveMarkup.escape clip}`", tracks.join(', ')]
    end
    return 'The set has no clips.' if rows.empty?

    MarkdownTables.make_table(%w[Clip Tracks], rows, align: %w[l l], is_rows: true)
  end

  private

  # The tracks that hold each clip of the set.
  #
  # A track that holds a clip in its take lanes as well as in itself is one entry, and the
  # lanes it holds the clip in are named with it.
  #
  # @return [Hash] each clip, and the tracks that hold it
  def holds
    uses = Hash.new { |hash, key| hash[key] = {} }

    @clips.each_with_its_track do |clip, number, track, lane|
      name = LiveMarkup.display_name track
      hold = uses[label_of(clip)][number] ||= { name: name, lanes: [] }
      hold[:lanes] << lane unless lane.nil? || hold[:lanes].include?(lane)
    end

    uses.transform_values do |holds|
      holds.map do |number, hold|
        lanes = hold[:lanes].empty? ? '' : " (take lane #{hold[:lanes].join(', ')})"
        "#{number} #{hold[:name]}#{lanes}"
      end
    end
  end

  # The name of a clip, as the cross-reference names it.
  #
  # @param clip [LiveMidiClip, LiveAudioClip] the clip
  # @return [String] the name
  def label_of(clip)
    clip.label
  end
end
