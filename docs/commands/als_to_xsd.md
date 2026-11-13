# `als_to_xsd`

## Help Message

This is the help message:

```text
als_to_xsd reads one or more Ableton Live sets and generates an XSD with the given name.

Syntax: als_to_xsd [OPTIONS] XSD_FILE_NAME PATH_TO_ALS_FILE...

Environment variables used in XSD_FILE_NAME and PATH_TO_ALS_FILE are expanded by the operating system.

A PATH_TO_ALS_FILE that holds a glob pattern is expanded by the command, and a pattern
that holds ** matches the files in the directories below the one that is named.

OPTIONS may be specified anywhere on the command line:
  -f      Overwrite any existing xsd.
  -h, --help
          Display this help message.
  -l LOGLEVEL, --log LOGLEVEL
          Set the log level. Allowable values are:
          DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN.

Example:
  $ als_to_xsd -f "$live_reference_sets/xsd/demo11.xsd"     "$live_reference_sets/sets/live_11/demo/projects_and_als"/**/*.als
  Wrote '/mnt/f/work/ableton/live_reference_sets/xsd/demo11.xsd'
```
