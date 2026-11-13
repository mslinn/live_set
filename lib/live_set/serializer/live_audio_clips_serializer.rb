require_relative '../model/hierarchical_number'
require_relative 'hierarchical_number_serializer'
require_relative 'live_audio_clip_serializer'
require_relative 'live_collection_serializer'
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
# markdown = LiveAudioClipsSerializer.new(clips, number).to_markdown
# html = LiveAudioClipsSerializer.new(clips, number).to_html
class LiveAudioClipsSerializer < LiveCollectionSerializer
  # Creates a serializer for a collection of audio clips.
  #
  # @param clips [LiveAudioClips] the clips of the collection
  # @param hierarchical_number [HierarchicalNumber] the number of the first clip of the track
  def initialize(clips, hierarchical_number)
    super()
    @clips = clips
    @hierarchical_number = hierarchical_number
  end

  # The groups of alike clips, and the number of each of them.
  #
  # @return [Array<Array>] the group of copies, and the number of the group
  def similar_clips
    @similar_clips ||= @clips.group_by(&:key).values.each_with_index.map { |copies, index| [copies, index] }
  end

  private

  # The clips of the collection, with the numbers they have in the report.
  #
  # @return [Array<Array>] the number and the copies
  def items
    similar_clips.map { |copies, index| [@hierarchical_number.dup.increment(index), copies] }
  end

  # Writes one group of alike clips.
  #
  # @param number [HierarchicalNumber] the number of the clip in the report
  # @param copies [Array<LiveAudioClip>] the copies of the clip
  # @param method [Symbol] the format the group is written in
  # @return [String] the group, written
  def write_item(number, copies, method)
    return lines_of(copies, number).join("\n") if method == :to_markdown

    item_of(copies, number)
  end

  # The lines of one group of alike clips.
  #
  # The indentation of the clip comes from its number, so that the number of a clip and the
  # place of it in the outline always agree.
  #
  # @param copies [Array<LiveAudioClip>] the copies of the clip
  # @param clip_number [HierarchicalNumber] the number of the clip in the report
  # @return [Array<String>] the lines
  def lines_of(copies, clip_number)
    indent = clip_number.indent_for LiveMarkup::INDENT
    lines = ["#{indent}- #{text_of(copies, clip_number)}"]
    settings_lines(copies).each { |line| lines << "#{indent}#{LiveMarkup::INDENT}- #{line}" }
    lines
  end

  # The item of one group of alike clips.
  #
  # @param copies [Array<LiveAudioClip>] the copies of the clip
  # @param clip_number [HierarchicalNumber] the number of the clip in the report
  # @return [String] the item
  def item_of(copies, clip_number)
    item = HierarchicalNumberSerializer.new clip_number, text_of(copies, clip_number)
    children = settings_lines(copies).map { |line| "#{item.children_indent}<li>#{line}</li>" }
    item.to_html children
  end

  # The text of one group of alike clips: its number, the number of its copies, and the clip.
  #
  # @param copies [Array<LiveAudioClip>] the copies of the clip
  # @param clip_number [HierarchicalNumber] the number of the clip in the report
  # @return [String] the text
  def text_of(copies, clip_number)
    detail = LiveAudioClipSerializer.new(copies.first, clip_number).to_markdown
    "Audio Clip #{clip_number} (×#{copies.length})  #{detail}"
  end

  # The lines of the settings the copies differ in.
  #
  # The copies that have the same settings are presented once, with a count, and the lines are ordered by the count, so
  # that the most common copies are shown first.
  #
  # @param group [Array<LiveAudioClip>] the copies @return [Array<String>] the lines
  def settings_lines(group)
    the_groups = group.group_by { |clip| settings_of clip }
    the_groups.map { |settings, copies| [copies.length, settings] }
              .sort_by { |count, settings| [-count, settings] }
              .map { |count, settings| "Copies (×#{count}): #{settings}" }
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
