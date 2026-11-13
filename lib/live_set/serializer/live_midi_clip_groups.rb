require_relative '../model/hierarchical_number'
require_relative 'hierarchical_number_serializer'
require_relative 'live_collection_serializer'
require_relative 'live_markup'
require_relative 'live_midi_clip_serializer'

# The copies of a MIDI clip that are alike, written as one line.
#
# A clip is written once for each place it is in, and the copies of it are alike, so the
# report counts them: the number of the copies, and then the settings they differ in.
#
# The grouping is the report's own. The format holds a copy of the clip at every place, and
# nonode in it ties the copies together.
#
# Sample usage:
# groups = LiveMidiClipGroups.new(clips, number)
# markdown = groups.to_markdown
class LiveMidiClipGroups < LiveCollectionSerializer
  # Creates the groups of the given clips.
  #
  # @param clips [Array<LiveMidiClip>] the clips of a track, or of a lane
  # @param first_number [HierarchicalNumber] the number of the first clip of the track
  def initialize(clips, first_number)
    super()
    @clips = clips
    @first_number = first_number
  end

  # The groups of alike clips, and the number of each of them.
  #
  # @return [Array<Array>] the group of copies, and the number of the group
  def groups
    @groups ||= @clips.group_by(&:key).values.each_with_index.map { |copies, index| [copies, index] }
  end

  private

  # The clips of the collection, with the numbers they have in the report.
  #
  # @return [Array<Array>] the number and the copies
  def items
    groups.map { |copies, index| [@first_number.dup.increment(index), copies] }
  end

  # Writes one group of alike clips.
  #
  # @param number [HierarchicalNumber] the number of the clip in the report
  # @param copies [Array<LiveMidiClip>] the copies of the clip
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
  # @param copies [Array<LiveMidiClip>] the copies of the clip
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
  # @param copies [Array<LiveMidiClip>] the copies of the clip
  # @param clip_number [HierarchicalNumber] the number of the clip in the report
  # @return [String] the item
  def item_of(copies, clip_number)
    item = HierarchicalNumberSerializer.new clip_number, text_of(copies, clip_number)
    children = settings_lines(copies).map { |line| "#{item.children_indent}<li>#{line}</li>" }
    item.to_html children
  end

  # The text of one group of alike clips: its number, the number of its copies, and the clip.
  #
  # @param copies [Array<LiveMidiClip>] the copies of the clip
  # @param clip_number [HierarchicalNumber] the number of the clip in the report
  # @return [String] the text
  def text_of(copies, clip_number)
    detail = LiveMidiClipSerializer.new(copies.first, clip_number).text
    "Clip #{clip_number} (#{count_of copies.length})  #{detail}"
  end

  # The lines of the settings the copies differ in.
  #
  # The copies that have the same settings are displayed once, with a count, sortedso that the most common copies appear
  # first.
  #
  # @param group [Array<LiveMidiClip>] the copies @return [Array<String>] the lines
  def settings_lines(group)
    groups = group.group_by { |clip| settings_of clip }
    groups.map { |settings, copies| [copies.length, settings] }
          .sort_by { |count, settings| [-count, settings] }
          .map { |count, settings| "Copies (#{count_of count}): #{settings}" }
  end

  # The settings of a clip: how it is launched, and how its sample is warped.
  #
  # @param clip [LiveMidiClip] the clip
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

  # A count of nodes, as the report writes it.
  #
  # @param count [Integer] the count
  # @return [String] the count
  def count_of(count)
    "×#{count}"
  end
end
