require_relative '../../common/util'
require_relative '../model/live_project_info'

# Writes what the report found of the 'Ableton Project Info' folders around the set.
#
# The folders are a fact about the machine the report was made on, and not about the set, so
# the report says what it found, and what it means: Live gets confused by a folder of that
# name in a parent folder of the folder of the project.
#
# Sample usage:
# markdown = LiveProjectInfoSerializer.new(project_info).to_markdown
class LiveProjectInfoSerializer
  # Creates a serializer for the folders around a set.
  #
  # @param project_info [LiveProjectInfo] the folders
  def initialize(project_info)
    @project_info = project_info
  end

  # Returns the section as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = ['### The Ableton Project Info Folder', '']
    warnings = @project_info.warnings
    if warnings.empty?
      lines << <<~END_MSG.squish
        The '#{LiveProjectInfo::FOLDER}' folder is in the folder of the set, and in no
        parent folder.
      END_MSG
    else
      warnings.each { |warning| lines << "- #{warning}" }
    end
    lines << ''
    lines << <<~END_MSG.squish
      Live gets confused by a <code>#{LiveProjectInfo::FOLDER}</code> folder in a parent folder of
      the folder of where the `.als` file is found. This possible error condition does not affect
      the content of the report being generated, but Live might not operate as expected if it
      were to load the project from the directory the report was generated from.
    END_MSG
    lines.join("\n")
  end
end
