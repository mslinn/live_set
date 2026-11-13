# `als_release_notes`

## Help Message

```text
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
  -p PATTERN, --pattern PATTERN
          Return the lines of the notes that match PATTERN with the release it belongs to.
          PATTERN is case-insensitive.
  -h, --help
          Display this help message.
  -l LOGLEVEL, --log LOGLEVEL
          Set the log level. Allowable values are:
          DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN.

Examples:
  als_release_notes 12          # output the release notes for all Live 12 versions
  als_release_notes 12.0        # output the release notes for 12.0 only
  als_release_notes 12.1        # output the release notes for 12.1 only
  als_release_notes 12 --pattern "scale awareness"
  diff <(als_release_notes 12.0) <(als_release_notes 12.1) # Show what changed between 12.0 and 12.1
```
