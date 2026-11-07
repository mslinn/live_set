# ALS Architecture

This document describes how this project uses Ruby classes to model ALS XML
entities, and how serializers generate markdown.

The ALS format changes with every Ableton Live release. The `live_set` project
is designed to handle structural differences in ALS files, such as an element
name that was renamed, or elements that exist in one version but not in another.

## Rubygem Commands

Every command defined by this project is named with the `als_` prefix, and the
class that implements a command is named after the command. The class has a
`run` method that takes the command line arguments, and a `help` method that
prints what the command does and what its options mean.

Commands mix in the `Command` module, defined in `lib/common/command.rb`;
provides functionality common to all commands, including option parsing, and logging.

Every command takes `-l` (or `--log`) with the level of the messages it writes to the
standard error: `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL` or `UNKNOWN`. The help of every
command names the levels.

| The command | The class | What it does |
| --- | --- | --- |
| `als_report` | `AlsReport` | writes the report of a set in markdown |
| `als_to_version` | `AlsToVersion` | converts a set to another version of the format |
| `als_delta` | `AlsDelta` | shows the changes to a set each time Live saves it |
| `als_to_xsd` | `AlsToXsd` | writes a schema of the format from the demo sets |
| `als_validate` | `AlsValidate` | checks a set against a schema |
| `als_nodes` | `AlsNodes` | prints the nodes of a document that an XPath expression finds |
| `als_diff` | `AlsDiff` | compares two sets element by element |
| `als_xsd_order` | `AlsXsdOrder` | prints the order of the children of an element in a schema |
| `als_release_notes` | `AlsReleaseNotes` | prints the release notes of a version of Live as markdown |
