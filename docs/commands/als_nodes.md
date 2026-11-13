# `als_nodes`

## Help Message

```text
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
  -h, --help
          Display this help message.
  -l LOGLEVEL, --log LOGLEVEL
          Set the log level. Allowable values are:
          DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN.
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
```

## Output

| The command            | What it prints                                                          |
| ---------------------- | ----------------------------------------------------------------------- |
| `als_nodes FILE XPATH` | the XML of the nodes, one after another                                 |
| `--attribute NAME`     | the value of the attribute, as plaintext                                |
| `--attributes`         | every attribute of the node, as a JSON dictionary of name/value pairs   |
| `--name`               | the name of each node, as plaintext                                     |
| `--children`           | the names of the children of each node, as a JSON array of text strings |
| `--count`              | the number of nodes that were found, and nothing else                   |

`--attributes` has priority over `--children`, `--attribute` and `--name`, and
`--children` has priority over `--attribute`.

The XML is indented: every level of nesting is indented by two spaces, and the
outermost element is at the start of a line.

```shell
$ als_nodes "$live_set" //FileRef --max 1
<FileRef>
  <RelativePathType Value="6"/>
  <RelativePath Value="Samples/Pink Noise - EDMtips.com.wav"/>
  <Path Value="/Users/owen/Music/Ableton/User Library/Samples/Pink Noise - EDMtips.com.wav"/>
  <Type Value="2"/>
  <LivePackName Value=""/>
  <LivePackId Value=""/>
  <OriginalFileSize Value="4130387"/>
  <OriginalCrc Value="513"/>
</FileRef>
```
