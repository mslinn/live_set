# What the report is about, and what it may say.
#
# The report is of a set. When it is of a project, the project is named, and the report says
# what is common to the sets of the project. When it is of a lone set, there is no project.
#
# The facts of the machine the report was made on are written only when the report was asked
# for them: they are true of the machine, and not of the set.
#
# See docs/report_context.md.
class ReportContext
  # The path of the project the sets are in, or nil when the report is of a lone set.
  attr_reader :project_path

  # The number of the sets the report is of.
  attr_reader :sets

  # @param project_path [String, nil] the path of the project the sets are in
  # @param machine [Boolean] whether the facts of the machine are written
  # @param sets [Integer] the number of the sets the report is of
  def initialize(project_path: nil, machine: false, sets: 1)
    @project_path = project_path
    @machine = machine
    @sets = sets
  end

  # Whether the report is of a project.
  #
  # @return [Boolean] true when the report is of a project
  def project?
    !@project_path.nil?
  end

  # Whether the facts of the machine are written.
  #
  # @return [Boolean] true when the machine's facts are written
  def machine?
    @machine
  end

  # The sentence that says what the report is about.
  #
  # @return [String] the sentence
  def sentence
    return 'This report pertains to ALS XML, without a project folder.' unless project?

    name = File.basename project_path
    if @sets > 1
      "This report pertains to the Live sets contained in \"#{name}\" folder."
    else
      "This report pertains to the Live set contained in \"#{name}\" folder."
    end
  end
end
