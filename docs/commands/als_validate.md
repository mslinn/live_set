# `als_validate`

## Help Message

```text
als_validate checks that the XML in an Ableton Live .als file conforms to an XSD schema.
Returns rcode 0 if no errors are found.

Syntax: als_validate [OPTIONS] PATH_TO_ALS_FILE SCHEMA.xsd

Environment variables used in PATH_TO_ALS_FILE are expanded by the operating system.

OPTIONS may be specified anywhere on the command line:
  -h, --help
          Display this help message.
  -l LOGLEVEL, --log LOGLEVEL
          Set the log level. Allowable values are:
          DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN.

Example:
  $ als_validate     "$live_reference_sets/sets/live_11/experiments/projects_and_als/one_midi_track_only_11 Project/factory_default_11.als"     "$live_reference_sets/xsd/demo11.xsd"
  /mnt/f/work/ableton/live_reference_sets/sets/live_11/experiments/projects_and_als/one_midi_track_only_11 Project/factory_default_11.als is valid
```
