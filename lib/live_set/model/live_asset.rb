require_relative '../../common/xml'

# An external asset of a set: a file the set refers to.
#
# Every external asset is named by a `FileRef`: the same element a sample is referenced by,
# whether the asset is a sample or a device preset. The reference holds the path of the file
# as the set writes it, the size Live recorded for it, and when it was last changed.
#
# The paths the references name take four shapes, and the shape says where the asset is:
#
# | The path | What it is |
# | --- | --- |
# | relative to the set | an asset in the project folder |
# | absolute | an asset in the user library, or in the Core Library of the Live installation |
# | relative, with `..` in it | an asset outside the project folder, in the folder the set was made in |
# | a folder | a folder rather than a file, and not an asset at all |
#
# See docs/als_notes.md, "The sample references of a clip", and docs/serializer_plan.md,
# "The assets".
class LiveAsset
  include Xml

  # The places an asset can be in, and the names the report gives them.
  LOCATIONS = {
    project:      'the project',
    user_library: 'the user library',
    core_library: 'the Core Library',
    outside:      'outside the project',
  }.freeze

  # The parts of an absolute path that say where the file is.
  USER_LIBRARY = 'User Library'.freeze
  CORE_LIBRARY = 'Core Library'.freeze

  attr_reader :absolute_path, :last_modified, :recorded_size, :relative_path

  # @param file_ref [Nokogiri::XML::Element] the `FileRef` element
  # @param set_directory [String] the directory the set is in
  def initialize(file_ref, set_directory)
    @file_ref = file_ref
    @set_directory = set_directory
    @absolute_path = xml_value(file_ref.at('Path')).to_s
    @relative_path = xml_value(file_ref.at('RelativePath')).to_s
    @recorded_size = recorded_size_of file_ref
    @last_modified = last_modified_of file_ref
  end

  # The path as the set writes it.
  #
  # The relative path is the one to use: the absolute path is a fallback for a reference that
  # has no relative path.
  #
  # @return [String] the path
  def path
    relative_path.empty? ? absolute_path : relative_path
  end

  # The path the reference was resolved to.
  #
  # @return [String] the path of the file on disk
  def resolved_path
    return absolute_path if relative_path.empty?

    File.expand_path File.join(@set_directory, relative_path)
  end

  # Where the asset is.
  #
  # @return [Symbol] the place the asset is in
  def location
    return :outside if relative_path.start_with? '..'
    return :project unless relative_path.empty?
    return :user_library if absolute_path.include? USER_LIBRARY
    return :core_library if absolute_path.include? CORE_LIBRARY

    :outside
  end

  # Whether the asset is in the project folder.
  #
  # @return [Boolean] true when the asset is in the project
  def in_project?
    location == :project
  end

  # Whether the file is on disk.
  #
  # @return [Boolean] true when the file is there
  def there?
    File.file? resolved_path
  end

  # Whether the reference names a folder rather than a file.
  #
  # @return [Boolean] true when the reference names a folder
  def folder?
    File.directory? resolved_path
  end

  # The size of the file on disk.
  #
  # @return [Integer, nil] the size in bytes, or nil when the file is not there
  def size_on_disk
    return nil unless there?

    File.size resolved_path
  end

  # The size the asset is expected to be.
  #
  # The size Live recorded is the size of the source file as Live saw it, and it is sometimes
  # zero even though the file exists and is not empty. The size on disk is used in that case.
  #
  # @return [Integer] the size in bytes
  def expected_size
    return recorded_size unless recorded_size.zero?

    size_on_disk.to_i
  end

  # When the file was last changed.
  #
  # The time on disk is the time of the file itself, and the time Live recorded is the time of
  # the source file as Live saw it.
  #
  # @return [Time, nil] the time, or nil when it is not known
  def last_modified_on_disk
    return nil unless there?

    File.mtime resolved_path
  end

  private

  # The size Live recorded for the file.
  #
  # Live 8 wrote `FileSize` instead of `OriginalFileSize`.
  #
  # @param file_ref [Nokogiri::XML::Element] the `FileRef` element
  # @return [Integer] the size in bytes
  def recorded_size_of(file_ref)
    size = xml_value(file_ref.at('OriginalFileSize')) || xml_value(file_ref.at('FileSize'))
    size.to_i
  end

  # When Live last saw the file.
  #
  # @param file_ref [Nokogiri::XML::Element] the `FileRef` element
  # @return [Time, nil] the time, or nil when it is not known
  def last_modified_of(file_ref)
    seconds = xml_value(file_ref.at('LastModDate'))&.to_i
    return nil if seconds.nil? || seconds.zero?

    Time.at(seconds).utc
  end
end
