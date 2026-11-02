require 'fileutils'

# Finds the repository of the reference sets of Live.
#
# The sets of every version of Live are checked in to a repository of their own, so that the
# sets and the reports of them are in one place, and neither is in the way of the code that
# reads them.
#
# The layout of the repository is:
#
#   sets/live_<version>/projects_and_als/    the sets, as Live wrote them
#   sets/live_<version>/reports/             the reports of the sets
#
# The repository is found through the environment variable `live_reference_sets`. Where that
# is not set, the directory beside the work of this project is used.
module ReferenceSets
  class << self
    # The directory the sets and the reports are in.
    #
    # @return [String] the path of the directory
    def directory
      @directory ||= ENV.fetch('live_reference_sets') do
        File.expand_path '../../../../ableton/live_reference_sets', __dir__
      end
    end

    # The directory the sets of a version are in.
    #
    # @param version [String] the version, e.g. "11"
    # @return [String] the path of the directory
    def directory_of(version)
      File.join directory, 'sets', "live_#{version}"
    end

    # The directory the reports of a version are in.
    #
    # @param version [String] the version, e.g. "11"
    # @return [String] the path of the directory
    def reports_of(version)
      File.join directory_of(version), 'reports'
    end

    # The sets of a version.
    #
    # @param version [String] the version, e.g. "11"
    # @return [Array<String>] the paths of the sets
    def sets_of(version)
      Dir.glob File.join(directory_of(version), 'projects_and_als', '**', '*.als')
    end

    # The versions of Live that have sets.
    #
    # @return [Array<String>] the versions, e.g. ["11", "12"]
    def versions
      Dir.children(File.join(directory, 'sets'))
         .select { |entry| File.directory? File.join(directory, 'sets', entry) }
         .map { |entry| entry.sub('live_', '') }
         .sort
    end
  end
end
