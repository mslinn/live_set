require 'logger'
require 'optparse'
require_relative '../common/command'
require_relative '../common/log'

class AlsNodes
  extend Command

  # Display help message for als_nodes
  #
  # @param msg [String, nil] an error message to show above the help
  # @return [String] the help message
  def self.help(msg = nil)
    help = <<~END_HELP
      Als_nodes prints the nodes of an XML document that an XPath expression finds.

      A Live set is XML, usually gzip-compressed, so the document can be a .als file or any XML
      file. The XPath expression is the only thing that has to change from one question to the
      next, which makes this the tool to reach for instead of writing a program for each
      element.

      Some options return XML results, some return plaintext, while others return JSON.

      Syntax: als_nodes [OPTIONS] FILE XPATH

      FILE is the path of the file, or a selector of a demo set, e.g. demo:12:suite.
      XPATH is an XPATH selector
      OPTIONS may be placed anywhere on the command line. They are:
        --attribute NAME
                Return the value of an attribute of each node as plaintext. The
                option may be given more than once. The values of the attributes
                are returned in the order the options were given.
        --attributes
                Return every attribute of each node, as a JSON dictionary (name/value pairs).
                Has priority over the --attribute, --children and --name options.
        --children
                Return the names of the children of each node as a JSON array of text strings.
                Has priority over the --attribute option.
        --count Return the number of nodes that were found, and nothing else.
        #{help_help}
        #{log_level_help}
        --max N Return at most N nodes. This is the highest priority option.
        --name  Return the name of each node, not the node itself.
        --unique
                Remove duplicate results.

      Examples:
        als_nodes set.als '//MidiTrack/IsTuned' --attribute Value
        als_nodes set.als '//MidiTrack' --attribute Id --attribute SelectedToolPanel
        als_nodes set.als '//MidiTrack' --attributes
        als_nodes set.als '//LiveSet/Scenes/Scene/FollowAction' --children
        als_nodes set.als '//LiveSet/MainTrack' --children | jq -r '.[]' | sort -u
        als_nodes set.als '//MidiTrack' --count
        als_nodes set.als '//MidiTrack' --count
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  # The options the command starts with.
  #
  # @return [Hash] the options
  def self.default_options
    super.merge(attribute: [])
  end

  def self.parser
    OptionParser.new do |parser|
      parser.program_name = 'als_nodes'

      # The option may be given more than once, and the attributes are collected in the order
      # the options were given.
      attributes = []
      parser.on('--attribute NAME', 'Print the value of an attribute of each node') do |name|
        attributes << name
        attributes
      end
      parser.on('--attributes', 'Print every attribute of each node')
      parser.on('--name', 'Print the name of each node')
      parser.on('--children', 'Print the names of the children of each node')
      parser.on('--count', 'Print the number of nodes that were found')
      parser.on('--max N', Integer, 'Print at most N nodes')
      parser.on('--unique', 'Print each distinct result once')
      add_common_options parser

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end
