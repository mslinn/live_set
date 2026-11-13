# `als_diff`

This is the help message:

```text
Als_diff compares two Ableton Live sets element by element, and prints the
differences.

A Live set is XML, usually gzip-compressed, so the documents can be .als files
or files containing XML extracted from an ALS file. The two documents are
first promoted to the newer of the two ALS versions, and are then walked in
parallel: the children of two elements are matched by their names, and the
children that one of the elements has and the other does not are reported as
differences. The attributes of two elements are compared as well.

Syntax: als_diff [OPTIONS] FILE1 FILE2

Where: FILE1 and FILE2 are paths

OPTIONS can be specified anywhere on the command line:
  -c, --count
          Only return the number of differences. This is the highest priority option.
  -h, --help
          Display this help message.
  -l LOGLEVEL, --log LOGLEVEL
          Set the log level. Allowable values are:
          DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN.
  -m N, --max N
          Return at most N differences
  -s NAME, --skip NAME
          Do not compare elements with this name, or any children.
          This option may be specified more than once.

The exit status is 0 when the documents are the same, and 1 when they are not.

Examples:
  als_diff live11.als live12.als
  als_diff live11.als live12.als --skip Devices --skip DeviceChain
  als_diff live11.als live12.als --count
  als_diff --skip Devices --skip DeviceChain live11.als live12.als
```
