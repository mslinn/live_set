# Where a file of a set comes from.
#
# The path Live wrote for a file says where the file was when the set was saved: in the
# project, in the user library, in the Core Library of Live, or in a pack. The content of a
# pack is under a folder of its own — Samples, Sounds, IRs, Devices, Racks, Presets — and
# the pack is the folder above it.
#
# The libraries of Live are not packs: they come with Live, and they are there for every
# set.
#
# See docs/als_notes.md, "Where a file comes from".
module LiveOrigin
  # The folders the content of a pack is in.
  CONTENT_FOLDERS = %w[Samples Sounds IRs Devices Racks Presets].freeze

  # The library of Live that comes with the program.
  CORE_LIBRARY = 'Core Library'.freeze

  # The library of the user, where the user puts the files of their own.
  USER_LIBRARY = 'User Library'.freeze

  # The libraries of Live, which are not packs.
  LIBRARIES = [CORE_LIBRARY, USER_LIBRARY].freeze

  class << self
    # The name of the pack the file is in.
    #
    # A file in the project, or in one of the libraries of Live, is not in a pack.
    #
    # @param path [String, nil] the path Live wrote for the file
    # @param project_directory [String, nil] the directory of the project
    # @return [String, nil] the name of the pack, or nil when the file is not in one
    def pack(path, project_directory = nil)
      name = origin_name path
      return nil if name.nil? || LIBRARIES.include?(name)
      return nil if in_project? path, project_directory

      name
    end

    # The name of the library the file is in.
    #
    # @param path [String, nil] the path Live wrote for the file
    # @return [String, nil] the name of the library, or nil when the file is not in one
    def library(path)
      name = origin_name path
      return nil unless LIBRARIES.include? name

      name
    end

    # The path of the pack the file is in.
    #
    # @param path [String, nil] the path Live wrote for the file
    # @return [String, nil] the path of the pack, or nil when the file is not in one
    def pack_path(path)
      index = content_index path
      return nil if index.nil? || !index.positive?

      path.split('/')[0...index].join('/')
    end

    # Whether the file is in the project.
    #
    # @param path [String, nil] the path Live wrote for the file
    # @param project_directory [String, nil] the directory of the project
    # @return [Boolean] true when the file is in the project
    def in_project?(path, project_directory)
      return false if path.nil? || path.empty? || project_directory.nil?

      File.expand_path(path).start_with?("#{File.expand_path project_directory}/")
    end

    private

    # The name of the folder the content of the file is in.
    #
    # @param path [String, nil] the path Live wrote for the file
    # @return [String, nil] the name of the folder
    def origin_name(path)
      index = content_index path
      return nil if index.nil? || !index.positive?

      path.split('/')[index - 1]
    end

    # The place in the path where the content of a pack begins.
    #
    # @param path [String, nil] the path Live wrote for the file
    # @return [Integer, nil] the index of the folder, or nil when the path names no content
    def content_index(path)
      path.to_s.split('/').index { |part| CONTENT_FOLDERS.include? part }
    end
  end
end
