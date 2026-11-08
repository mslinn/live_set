# TODO: This is a placeholder to start off the changes described as TODO comments in lib/live_set/live_palette.rb
# TODO Write unit tests
#
# Writes the "P3S Standalone" section of the markdown report for a `LiveSet` model.
#
# Two kinds of message are reported. An error stops a set from being transferred: a clip that
# is not collected, and a third-party device on an unfrozen track or in a group's chain.
# Advice is not an error and does not change the verdict: an unfrozen track that uses only
# native devices.
#
# The clips that are not collected are counted and not named: a demo set holds dozens of
# them, and the list of them says nothing that the count does not.
#
# Sample usage:
# markdown = P3SCompatibility.new(live_set).to_markdown
class P3SCompatibility
  # Create a serializer for the "P3S Standalone" report section for the given set.
  #
  # @param live_set [LiveSet] the live_set to report on
  def initialize(live_set)
    @live_set = live_set
  end

  # Return the "P3S Standalone" report section as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    errors = @live_set.p3s_errors
    uncollected = @live_set.uncollected_clips.length

    lines = ['## P3S Standalone', '']
    lines << if errors.empty? && uncollected.zero?
               '✅ Ready for transfer to P3S Standalone'
             else
               <<~END_MSG
                 ❌ Warning: This set should not be transferred to P3S Standalone.

                 ### Reasons Why
               END_MSG
             end
    unless uncollected.zero?
      lines << "- [#{uncollected} #{uncollected == 1 ? 'clip has' : 'clips have'} " \
               'not been collected.](#missing-samples)'
    end
    errors.each { |error| lines << "- #{error.sub(/\A\s*-\s*/, '')}" }
    @live_set.p3s_advice.each { |advice| lines << "- #{advice.sub(/\A\s*-\s*/, '')}" }
    lines.join("\n")
  end
end
