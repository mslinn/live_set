require_relative 'live_audio_clip_serializer'
require_relative 'live_markup'

# Writes a collection of the clips of the audio side of a track.
#
# The collection is never written by itself: each clip is written by the serializer of a
# clip, and the outputs are mapped together.
#
# The copies of a clip that are alike are written as one line, and the number of them is
# written with it. The settings the copies differ in are written under the line.
#
# Sample usage:
# markdown = LiveAudioClipsSerializer.new(clips, '1.1').to_markdown
class LiveAudioClipsSerializer
  # Creates a serializer for a collection of audio clips.
  #
  # @param clips [LiveAudioClips] the clips of the collection
  # @param hierarchical_number [String] the number of the track the clips are on
  def initialize(clips, hierarchical_number)
    @clips = clips
    @hierarchical_number = hierarchical_number
  end

  # Returns the collection as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    similar_clips.flat_map { |group, index| lines_of(group, index) }.join("\n")
  end

  private

  # The groups of alike clips, and the number of the first copy of each.
  #
  # @return [Array<Array>] the group of copies, and the number of the first of them
  def similar_clips
    numbered = @clips.each_with_index.to_a
    numbered.group_by { |(clip, _index)| clip.key }
            .map { |_key, pairs| [pairs.map(&:first), pairs.first[1]] }
  end

  # The lines of one group of alike clips.
  #
  # The indentation of the clip comes from its number, so that the number of a clip and the
  # place of it in the outline always agree.
  #
  # @param group [Array<LiveAudioClip>] the copies
  # @param index [Integer] the number of the first copy among the clips
  # @return [Array<String>] the lines
  def lines_of(group, index)
    number = "#{@hierarchical_number}.#{index + 1}"
    indent = LiveMarkup.indent_for number
    detail = LiveAudioClipSerializer.new(group.first, number).to_markdown
    header = "#{indent}- Audio Clip #{number} (×#{group.length})  #{detail}"
    [header, *settings_lines(group).map { |line| "#{indent}#{LiveMarkup::INDENT}#{line}" }]
  end

  # The lines of the settings the copies differ in.
  #
  # The copies that have the same settings are one line, with the number of them, and the
  # lines are ordered by the number of copies, so that the ones with the most come first.
  #
  # @param group [Array<LiveAudioClip>] the copies
  # @return [Array<String>] the lines
  def settings_lines(group)
    the_groups = group.group_by { |clip| settings_of clip }
    the_groups.map { |settings, copies| [copies.length, settings] }
              .sort_by { |count, settings| [-count, settings] }
              .map { |count, settings| "- References (×#{count}): #{settings}" }
  end

  # The settings of a clip: how it is launched, and how its sample is warped.
  #
  # @param clip [LiveAudioClip] the clip
  # @return [String] the settings
  def settings_of(clip)
    settings = []
    settings << 'disabled' if clip.settings.disabled?
    settings << "launch: #{clip.settings.launch_mode}" if clip.settings.launch_mode
    settings << if clip.settings.warp_mode && clip.settings.warped?
                  "warp: #{clip.settings.warp_mode}"
                else
                  'warp: none'
                end
    settings.join(', ')
  end
end
