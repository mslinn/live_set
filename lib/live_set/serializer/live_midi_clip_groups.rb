require_relative 'live_markup'
require_relative 'live_midi_clip_serializer'

# The copies of a MIDI clip that are alike, written as one line.
#
# A clip is written once for each place it is in, and the copies of it are alike, so the
# report counts them: the number of the copies, and then the settings they differ in.
#
# The grouping is the report's own. The format holds a copy of the clip at every place, and
# nothing in it ties the copies together.
#
# Sample usage:
# groups = LiveMidiClipGroups.new(clips)
# markdown = groups.to_markdown('1.1')
class LiveMidiClipGroups
  # Creates the groups of the given clips.
  #
  # @param clips [Array<LiveMidiClip>] the clips of a track, or of a lane
  def initialize(clips)
    @clips = clips
  end

  # The lines of the groups: a line for each group, and the settings under it.
  #
  # @param number [String] the number of the track the clips are on
  # @return [Array<String>] the lines
  def to_markdown(number)
    groups.flat_map { |group, index| lines_of(group, index, number) }
  end

  private

  # The groups of alike clips, and the number of the first copy of each.
  #
  # @return [Array<Array>] the group of copies, and the number of the first of them
  def groups
    numbered = @clips.each_with_index.to_a
    numbered.group_by { |(clip, _index)| clip.key }
            .map { |_key, pairs| [pairs.map(&:first), pairs.first[1]] }
  end

  # The lines of one group of alike clips.
  #
  # The indentation of the clip comes from its number, so that the number of a clip and the
  # place of it in the outline always agree.
  #
  # @param group [Array<LiveMidiClip>] copies
  # @param index [Integer] the number of the first copy among the clips
  # @param number [String] the number of the track the clips are on
  # @return [Array<String>] the lines
  def lines_of(group, index, number)
    first = group.first
    clip_number = "#{number}.#{index + 1}"
    indent = LiveMarkup.indent_for clip_number
    lines = ["#{indent}- Clip #{clip_number} (#{count_of group.length})  " \
             "#{LiveMidiClipSerializer.new(first, clip_number).to_markdown}"]
    settings_lines(group).each { |line| lines << "#{indent}#{LiveMarkup::INDENT}#{line}" }
    lines
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
          .map { |count, settings| "- Copies (#{count_of count}): #{settings}" }
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

  # A count of things, as the report writes it.
  #
  # @param count [Integer] the count
  # @return [String] the count
  def count_of(count)
    "×#{count}"
  end
end
