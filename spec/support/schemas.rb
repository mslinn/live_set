require 'open3'
require 'zlib'
require 'nokogiri'

# The schemas of the Live versions, generated from the demo sets of each version.
#
# The schemas are not in the repository — .gitignore excludes *.xsd — so every computer has to
# generate its own. A spec that skips when the schema is missing proves nothing, so the schema
# is generated when it is not there, and the spec fails when it cannot be generated.
#
# See bin/generate_xsds, which generates the schemas of every version at once.
module Schemas
  # The directory the schemas are written to.
  DIRECTORY = File.expand_path('../../schemas', __dir__)

  # The root of the project, which the generator is run from.
  PROJECT_ROOT = File.expand_path('../..', __dir__)

  # The path of the schema of a Live version.
  #
  # @param version [String] the Live version, e.g. "11" or "12.4"
  # @return [String] the path of the schema
  # @raise [RuntimeError] when the schema is missing and cannot be generated
  def self.path(version)
    name = schema_name(version)
    raise "No demo set of Live #{version} was found, so no schema can be generated" if name.nil?

    file = File.join(DIRECTORY, "live_#{name}.xsd")
    return file if File.exist?(file)

    generate(version, file)
    file
  end

  # The name of the schema of a Live version.
  #
  # The name comes from the Creator attribute of the demo set, e.g. "Ableton Live 11.3d1" gives
  # "11.3d1". The version may be a major version, e.g. "11", or a full one, e.g. "11.3".
  #
  # @param version [String] the Live version
  # @return [String, nil] the name of the schema
  def self.schema_name(version)
    sets = demo_sets(version)
    return nil if sets.empty?

    creator = creator_of(sets.first)
    creator&.delete_prefix('Ableton Live ')
  end

  # The demo sets of a Live version.
  #
  # @param version [String] the Live version
  # @return [Array<String>] the paths of the sets
  def self.demo_sets(version)
    DemoSets.all.select { |found, _| found.start_with?(version) }.values.flatten
  end

  # The Creator attribute of a set.
  #
  # @param path [String] the path of the set
  # @return [String, nil] the value of the attribute
  def self.creator_of(path)
    document = Nokogiri::XML(Zlib::GzipReader.open(path, &:read))
    document.at_xpath('//Ableton')&.[]('Creator')
  end

  # Generates the schema of a Live version.
  #
  # @param version [String] the Live version
  # @param file [String] the path of the schema to write
  # @return [String] the path of the schema
  # @raise [RuntimeError] when the generator fails
  def self.generate(version, file)
    sets = demo_sets(version)
    Dir.chdir(PROJECT_ROOT) do
      command = ['bundle', 'exec', 'ruby', 'exe/generate_xsd', '-f', file, *sets]
      output, status = Open3.capture2e(*command)
      raise "Generating the schema of Live #{version} failed:\n#{output}" unless status.success?
    end

    raise "Generating the schema of Live #{version} produced no file" unless File.exist?(file)

    puts "Generated #{file}"
    file
  end
end
