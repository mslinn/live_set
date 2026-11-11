require 'logger'
require 'optparse'
require_relative '../common/command'
require_relative '../common/log'

class AlsReleaseNotes
  extend Command

  # Display help message for als_release_notes
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      Als_release_notes prints the release notes of a version of Live as markdown.

      The release notes are the evidence the version_diff documents are built from.
      They say the changes to expect between version formats, and which version
      introduced each change. Release notes are written for the musicians who use
      Live, so they never give an element name or an attribute name, thus they are
      only a guide to the differences rather than a detailed source of information.

      Ableton provides the notes at https://www.ableton.com/en/release-notes/live-XX/,
      where XX is the version of Live. The fetched notes are cached in HTML at
      docs/release_notes/, one file per version. The cache allows the notes to be
      accessed easily. The release notes are fetched when there is a cache miss.

      The cache is found beside the command: the notes are packaged with the gem, so the
      command reads them wherever the gem is installed.

      Syntax: als_release_notes [OPTIONS] VERSION

      VERSION is the version of Live
        Specifying just the major release (e.g. 12) returns the release notes for all
        versions of that major release. Specifying the minor release (e.g. 12.0)
        returns just the release notes for that minor release.

      OPTIONS can be specified anywhere on the command line:
        --find PATTERN  print the lines of the notes that match PATTERN, each with the
                        release it belongs to. The pattern is case-insensitive.
        -h              Display this help message.
        #{log_level_help}

      Examples:
        als_release_notes 12          # output the release notes for all Live 12 versions
        als_release_notes 12.0        # output the release notes for 12.0 only
        als_release_notes 12.1        # output the release notes for 12.1 only
        als_release_notes 12 --find "scale awareness"
        als_release_notes 12 > docs/release_notes/live-12.md
        diff <(als_release_notes 12.0) <(als_release_notes 12.1)
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # The options the command starts with.
  #
  # @return [Hash] the options
  def self.default_options
    super.merge(find: nil)
  end

  def self.parser
    OptionParser.new do |parser|
      parser.program_name = 'als_release_notes'

      parser.on('--find PATTERN', 'Print the lines of the notes that match PATTERN')
      add_common_options parser

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
