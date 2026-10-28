require 'fileutils'
require 'nokogiri'
require 'tmpdir'
require 'zlib'

# Helpers for finding and using the official Ableton demo sets.
#
# Ableton ships a demo set with every version of Live, and it is the best reference for what a
# given Live version writes, because there is one for each version. The location is documented:
#
#   https://help.ableton.com/hc/en-us/articles/209774005-Location-of-the-default-Demo-Set
#
# On Windows the set is in:
#
#   C:\ProgramData\Ableton\[Live Version]\Resources\Core Library\Lessons\Demo Songs
#
# and on macOS it is inside the application bundle:
#
#   /Applications/Live [Version].app/Contents/App Resources/Core Library/Lessons/Demo Songs
#
# The sets are not always installed in those places — they can be copied elsewhere, and an
# installed Live version may have been uninstalled — so these helpers look in the documented
# places first and then fall back to a search.
module DemoSets
  # The directories the demo sets are expected to be in, in the order they are tried.
  #
  # The first two follow Ableton's documented layout. The rest are places where the sets are
  # found on the machine this was developed on.
  DEFAULT_DIRECTORIES = [
    '/mnt/c/ProgramData/Ableton',
    '/mnt/e/media/Ableton',
    '/mnt/m/Ableton'
  ].freeze

  # The directories holding the demo sets.
  #
  # The documented layout is searched first, because it is quick. The fallbacks are searched
  # with a bounded glob, because an unbounded one would walk the whole drive.
  #
  # @param directories [Array<String>] the directories to search
  # @return [Array<String>] the directories
  def self.directories(directories = DEFAULT_DIRECTORIES)
    directories.flat_map { |root| demo_songs_under root }.select { |path| File.directory? path }.uniq
  end

  # The "Demo Songs" directories under a root, found without walking the whole tree.
  #
  # The documented layout is a fixed path, and the fallbacks are a directory or two down.
  #
  # @param root [String] the directory to search
  # @return [Array<String>] the directories
  def self.demo_songs_under(root)
    candidates = [File.join(root, 'Resources', 'Core Library', 'Lessons', 'Demo Songs')]
    candidates += Dir.glob(File.join(root, '*', 'Resources', 'Core Library', 'Lessons', 'Demo Songs'))
    candidates += Dir.glob(File.join(root, 'Lessons', 'Demo Songs'))
    candidates
  end

  # The demo sets, as { live version => [paths] }.
  #
  # The Live version comes from the set's Creator attribute, e.g. "Ableton Live 11.3d1".
  #
  # The result is cached, because reading every set is slow and the answer does not change.
  #
  # @param directories [Array<String>] the directories to search
  # @return [Hash] the sets, keyed by Live version
  def self.all(directories = DEFAULT_DIRECTORIES)
    @all ||= directories(directories).flat_map { |dir| Dir.glob File.join(dir, '*.als') }
                                     .group_by do |path|
      creator = Nokogiri::XML(Zlib::GzipReader.open(path, &:read)).at('//Ableton')['Creator'].to_s
      creator[/Live\s+([\d.]+)/, 1]
    end
  end

  # The demo set for a Live version, preferring the smallest one.
  #
  # The version may be a major version, e.g. "12", or a full one, e.g. "12.4".
  #
  # The result is cached, because finding the sets means reading them.
  #
  # @param version [String] the Live version
  # @param directories [Array<String>] the directories to search
  # @return [String, nil] the path of the set
  def self.path(version, directories = DEFAULT_DIRECTORIES)
    @path ||= {}
    @path[version] ||= begin
      sets = all(directories).select { |found, _| found.start_with? version }
                             .values.flatten
      sets.min_by { |path| File.size path }
    end
  end

  # The demo set for a Live version and an edition.
  #
  # The result is cached.
  #
  # @param version [String] the Live version, e.g. "11"
  # @param edition [String] the edition, e.g. "Suite"
  # @param directories [Array<String>] the directories to search
  # @return [String, nil] the path of the set
  def self.edition(version, edition, directories = DEFAULT_DIRECTORIES)
    @edition ||= {}
    @edition["#{version} #{edition}"] ||= begin
      sets = all(directories).select { |found, _| found.start_with? version }
                             .values.flatten
      found = sets.find { |path| File.basename(path).include? "(#{edition} Demo)" }
      found || sets.min_by { |path| File.size path }
    end
  end

  # The demo set for a Live version, or an error when there is none.
  #
  # The test data of this project is the demo set of each version of Live. A spec that skips
  # when the data is missing proves nothing, so the absence of the data is an error.
  #
  # @param version [String] the Live version, e.g. "11" or "12"
  # @return [String] the path of the demo set
  # @raise [RuntimeError] when there is no demo set of that version
  def self.require!(version)
    found = path(version)
    raise "No demo set of Live #{version} was found in #{directories.join(', ')}" if found.nil?

    found
  end

  # The demo set for a Live version and an edition, or an error when there is none.
  #
  # @param version [String] the Live version, e.g. "11"
  # @param edition [String] the edition, e.g. "Suite"
  # @return [String] the path of the set
  # @raise [RuntimeError] when there is no demo set of that version and edition
  def self.require_edition!(version, edition)
    found = edition(version, edition)
    raise "No demo set of Live #{version} #{edition} was found in #{directories.join(', ')}" if found.nil?

    found
  end

  # The Live 12 version of a Live 11 demo set, or an error when there is none.
  #
  # @param version [String] the Live version the set was written in, e.g. "11"
  # @param edition [String] the edition, e.g. "Suite"
  # @return [String] the path of the set
  # @raise [RuntimeError] when the set has not been made
  def self.require_converted!(version, edition)
    found = converted(version, edition)
    raise "No Live 12 conversion of the Live #{version} #{edition} demo set was found" if found.nil?

    found
  end

  # The Live 12 version of a Live 11 demo set, made by opening it in Live 12 and saving it.
  #
  # This is the file the round trip needs: the same material, written by Live 12. It is not one
  # of the demo sets Ableton ships, because Live 12's demo set is a different song.
  #
  # Live writes a saved set into a Project folder, and names the file after the set it came
  # from, with "converted to Live 12" added. So the file is looked for in a folder named after
  # the set, and beside the original.
  #
  # @param version [String] the Live version the set was written in, e.g. "11"
  # @param edition [String] the edition, e.g. "Suite"
  # @param directories [Array<String>] the directories to search
  # @return [String, nil] the path of the set
  def self.converted(version, edition, directories = DEFAULT_DIRECTORIES)
    source = edition(version, edition, directories)
    return nil if source.nil?

    name = File.basename(source, '.als')
    song = name.delete_suffix('.als')
    folder = File.dirname(source)
    converted = "#{song} converted to Live 12"
    candidates = [
      File.join(folder, "#{converted}.als"),
      File.join(folder, "#{converted} Project", "#{converted}.als"),
      File.join(folder, "#{song} (Live 12).als")
    ]
    candidates += directories(directories).flat_map { |dir| Dir.glob File.join(dir, "#{song}*converted to Live 12*.als") }
    candidates.find { |path| File.file? path }
  end
end
