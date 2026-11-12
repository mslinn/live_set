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

      The nodes are printed as XML. The values of the nodes are printed as a JSON array of
      strings, so that jq can work with them: jq reads JSON, and not XML.

      Syntax: als_nodes FILE XPATH [options]

      FILE is the path of the file, or a selector of a demo set, e.g. demo:11:suite.

      Options are:
        --attribute NAME  print the value of an attribute of each node, not the node itself. The
                           option may be given more than once, and the values of the attributes
                           are then printed in the order the options were given.
        --attributes       print every attribute of each node, as name=value pairs
        --name             print the name of each node, not the node itself
        --children        print the names of the children of each node, not the node itself
        --count           print the number of nodes that were found, and nothing else
        --max N           print at most N nodes
        --unique          print each distinct result once
        -h                Display this help message.
        #{log_level_help}

      Examples:
        als_nodes set.als '//MidiTrack/IsTuned' --attribute Value
        als_nodes set.als '//MidiTrack' --attribute Id --attribute SelectedToolPanel
        als_nodes set.als '//MidiTrack' --attributes
        als_nodes set.als '//LiveSet/Scenes/Scene/FollowAction' --children
        als_nodes set.als '//LiveSet/MainTrack' --children | jq -r '.[]'
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
