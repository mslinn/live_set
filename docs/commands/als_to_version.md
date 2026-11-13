# `als_to_version`

Convert a set to another version of the Live format, and write it out:

## Help Message

This is the help message:

```text
$ als_to_version -h
als_to_version converts a Live set to another version of the Live format.
If SRC is already at the version it is converted to, the program says so and stops.

Syntax: als_to_version [OPTIONS] VERSION SRC [DST]

Where:
  VERSION  is the Ableton Live version to be converted to, e.g. 11.
  SRC      is the path of of the set to be converted, or a selector of a demo set,
           e.g. demo:11:suite
  DST      is the optional path to write the converted set to. Without it, the
           converted set is written to the same directory as SRC, with the version
           as a suffix. For example, if SRC is set.als, and VERSION is 11, the default
           destination path would be set_11.als.

OPTIONS can be specified anywhere on the command line:
  -f      Overwrite the destination if it already exists.
  -h, --help
          Display this help message.
  -l LOGLEVEL, --log LOGLEVEL
          Set the log level. Allowable values are:
          DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN.

Example:
  als_to_version 11 "$path/to/sample_set.als"  # writes to "$path/to/sample_set_11.als"
  als_to_version 12 "$path/to/sample_set.als" "live_12_test_conversion.als" -f
```

## Example Usage

```shell
$ als_to_version 11 path/to/my_set_12.als path/to/my_set_11.als
```

The set is written to the same directory as the original set to be converted,
unless another destination is named. The `-f` option overwrites any pre-existing
destination set.

When converting to Live 11 format, the converted set uses the Live 11.3.21
schema. The sub-version is not configurable.  For more infomation, see
[docs/dev/live_11_12_diff.md](docs/dev/live_11_12_diff.md#converting-a-set-to-live-11-uses-a-fixed-schema).
