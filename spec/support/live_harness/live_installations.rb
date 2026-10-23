require 'open3'

# Finds the Ableton Live installations on this machine.
#
# Live installs every edition under one directory, and the demo sets are a subdirectory of the
# installation. So finding the installations finds the demo sets too, and finding the demo sets
# is not a separate problem. The locations are documented:
#
#   https://help.ableton.com/hc/en-us/articles/209774005-Location-of-the-default-Demo-Set
#
# On Windows the installation is in:
#
#   C:\ProgramData\Ableton\Live [Version] [Edition]\
#
# and on macOS it is an application bundle:
#
#   /Applications/Live [Version].app
#
# Within an installation, the executable and the demo sets are in fixed places:
#
#   Windows:  Program\Ableton Live [Version] [Edition].exe
#             Resources\Core Library\Lessons\Demo Songs
#   macOS:    Contents/MacOS/Ableton Live [Version]
#             Contents/App Resources/Core Library/Lessons/Demo Songs
#
# The Windows program data directory is also the one the user can install to elsewhere, so a
# search is needed as well as the documented location. The search is bounded to the directories
# that hold an Ableton directory, because an unbounded search would walk the whole disk.
module LiveInstallations
  # A Live installation.
  #
  # @!attribute root
  #   @return [String] the directory the installation is in
  # @!attribute version
  #   @return [String] the Live version, e.g. "11"
  # @!attribute edition
  #   @return [String] the edition, e.g. "Suite"
  # @!attribute executable
  #   @return [String, nil] the path of the executable, if it is there
  # @!attribute demo_songs
  #   @return [String, nil] the path of the demo songs directory, if it is there
  Installation = Struct.new(:root, :version, :edition, :executable, :demo_songs,
                            keyword_init: true) do
    # @return [String] a name for the installation, e.g. "Live 11 Suite"
    def name
      "Live #{version} #{edition}"
    end
  end

  # The directories that hold the Live installations.
  #
  # The first is the documented Windows location, seen from WSL. The second is the Windows
  # location written the way a Windows program would write it. The third is macOS.
  DEFAULT_ROOTS = [
    '/mnt/c/ProgramData/Ableton',
    'C:/ProgramData/Ableton',
    '/Applications'
  ].freeze

  # The Live installations that are present.
  #
  # The result is cached, because finding them means reading the disk.
  #
  # @param roots [Array<String>] the directories to search
  # @return [Array<Installation>] the installations
  def self.all(roots = DEFAULT_ROOTS)
    @all ||= {}
    @all[roots] ||= roots.flat_map { |root| installations_under root }.uniq(&:root)
  end

  # The installation of a Live version.
  #
  # The version may be a major version, e.g. "11", or a full one, e.g. "11.3".
  #
  # @param version [String] the Live version
  # @param roots [Array<String>] the directories to search
  # @return [Installation, nil] the installation
  def self.version(version, roots = DEFAULT_ROOTS)
    all(roots).find { |installation| installation.version.start_with? version }
  end

  # The demo sets of an installation.
  #
  # @param installation [Installation] the installation
  # @return [Array<String>] the paths of the demo sets
  def self.demo_sets(installation)
    return [] if installation.demo_songs.nil?

    Dir.glob File.join(installation.demo_songs, '*.als')
  end

  # The demo set for a Live version, preferring the smallest one.
  #
  # @param version [String] the Live version
  # @param roots [Array<String>] the directories to search
  # @return [String, nil] the path of the demo set
  def self.demo_set(version, roots = DEFAULT_ROOTS)
    installation = version(version, roots)
    return nil if installation.nil?

    sets = demo_sets installation
    sets.min_by { |path| File.size path }
  end

  # The installations under a root.
  #
  # @param root [String] the directory to search
  # @return [Array<Installation>] the installations
  def self.installations_under(root)
    candidates = if File.directory?(File.join(root, 'Program'))
                   # The root is an installation itself.
                   [root]
                 else
                   Dir.glob File.join(root, '*')
                 end

    candidates.filter_map { |path| installation_at path }
  end

  # The installation at a path, if it is one.
  #
  # @param path [String] the path of a candidate directory
  # @return [Installation, nil] the installation
  def self.installation_at(path)
    name = File.basename path
    return nil unless name =~ /\ALive\s+(\d+(?:\.\d+)*)\s*(.*)\z/

    version = Regexp.last_match(1)
    edition = Regexp.last_match(2).strip

    executable = [
      Dir.glob(File.join(path, 'Program', 'Ableton Live*.exe')),
      Dir.glob(File.join(path, 'Contents', 'MacOS', 'Ableton Live*'))
    ].flatten
    demo_songs = [
      Dir.glob(File.join(path, 'Resources', 'Core Library', 'Lessons', 'Demo Songs')),
      Dir.glob(File.join(path, 'Contents', 'App Resources', 'Core Library', 'Lessons',
                         'Demo Songs'))
    ].flatten

    Installation.new root: path, version: version, edition: edition,
                     executable: executable.first, demo_songs: demo_songs.first
  end

  # The preferences folder of a Live installation.
  #
  # Live writes its per-version state, including its log, under the user's roaming profile:
  #
  #   %APPDATA%\Ableton\Live <version>\Preferences\
  #
  # The version directory is named for the full version, e.g. "Live 11.3.43", so it has to be
  # found rather than assumed.
  #
  # @param version [String] the Live version, e.g. "11"
  # @param roots [Array<String>] the profile directories to search
  # @return [String, nil] the path of the Preferences folder
  def self.preferences(version, roots = profile_roots)
    @preferences ||= {}
    @preferences[version] ||= begin
      found = roots.flat_map { |root| Dir.glob File.join(root, 'Ableton', 'Live *') }
                   .map { |path| File.join path, 'Preferences' }
                   .select { |path| File.directory? path }
                   .select { |path| File.basename(File.dirname(path)).start_with? "Live #{version}." }
      found.max_by { |path| File.mtime path }
    end
  end

  # The directories the user's roaming profile is in.
  #
  # @return [Array<String>] the directories
  def self.profile_roots
    @profile_roots ||= Dir.glob('/mnt/c/Users/*/AppData/Roaming')
  end
end
