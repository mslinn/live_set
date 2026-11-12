require_relative 'als_model_serializer'
require_relative 'live_common_serializer'

# Writes the report of a project: the facts that are the same for every set of it, and a
# report for each of the sets.
#
# The report of a set is the report of a set: its title, its facts table, and its sections.
# What a project adds is the context, and not a different shape of report.
#
# Sample usage:
# markdown = LiveProjectSerializer.new(path, models, context).to_markdown
class LiveProjectSerializer
  # Creates a serializer for the report of a project.
  #
  # @param path [String] the path of the project
  # @param models [Array<AlsModel>] the models of the sets of the project
  # @param context [ReportContext] what the report is about, and what it may say
  def initialize(path, models, context)
    @path = path
    @models = models
    @context = context
  end

  # Returns the report of the project as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    lines = ["# `#{File.basename @path}`", '', common_section, '']
    @models.each do |model|
      lines << AlsModelSerializer.new(model).to_markdown
      lines << ''
    end
    lines.join("\n")
  end

  private

  # The facts that are the same for every set of the project.
  #
  # @return [String] the section
  def common_section
    LiveCommonSerializer.new(@models.first.header_block, @context).to_markdown
  end
end
