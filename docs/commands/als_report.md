# `als_report`

## Sample Usage

Here is an example of running `als_report`:

```shell
live_reference_sets="/mnt/f/work/ableton/live_reference_sets"
projects_and_als_12="$live_reference_sets/sets/live_12/demo/projects_and_als"
live_set="$projects_and_als_12/Chuck Sutton - Patience (Live 12 Suite Demo).als"
als_report "$live_set"
```


## Help Mesage

This is the help message:

```text
$ als_report -h
Als_report writes a report of an Ableton Live set in markdown, including but not
limited to the groups, tracks, the devices, clips, take lanes, missing samples,
and several cross-references.

The report is written to stdout as markdown. Log output is written in plaintext
to stderr.

If the special folder called 'Ableton Project Info' is not present in the same
folder as the .als file, a warning is generated. Similarly, if 'Ableton Project
Info' is present in any parent folder, a warning is issued and the user is asked
if the directory should be renamed.

Syntax: als_report OPTIONS PATH_TO_ALS_FILE

PATH_TO_ALS_FILE is the path of a set, or the path of a Live project directory. A
project holds one or more sets, and each of them is reported.

Environment variables used in PATH_TO_ALS_FILE are expanded.

OPTIONS may be specified anywhere on the command line:
  -a, --als NAME
          Report only the `.als` file specifed by NAME and ignore all other `.als` files
          in the project. This option may be provided more than once.
  -c, --computer
          Report the facts of the computer the report was made on: the packs that are
          installed, the folders around the set, and the files that are there. They are
          true of the machine and not of the set.
  -h, --help
          Display this help message.
  -l LOGLEVEL, --log LOGLEVEL
          Set the log level. Allowable values are:
          DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN.
  -s, --show_midi_and_audio_tracks_separately
          Report the audio tracks and the MIDI tracks separately. By default, every
          track is displayed in the order found in the ALS file.
  -v      Show the version of this program and exit. This is the highest priority option.
  -z      The time zone to use in the report in, e.g. America/Chicago. The default
          is America/Toronto, unless the TZ environment variable is set. This option
          overrides the TZ environment variable.

Examples:
  als_report \
    -z Europe/Berlin \
    --show_midi_and_audio_tracks_separately \
    "$path_to_my_set/demo.als"

   TZ=Europe/Berlin als_report \
    --show_midi_and_audio_tracks_separately \
    "$path_to_my_set/demo.als"
```


## Project Report vs. ALS XML Report

The path given to the command dictates the type of report that will be
generated:

- a path to a Live set is a report of the XML in that file.
- a path to a Live project directory is a report of the entire project.


## Common To All Reports

`als_report` writes a report of a set in markdown mixed with HTML, including the
tracks of the set and the groups they are in, their devices, clips and take
lanes, missing and not missing samples, set metadata, collected assets,
packs references, and a cross-reference of the tracks and the clips.

See [docs/report_context.md](docs/report_context.md) for what the command is
given, and [docs/dev/report_design.md](docs/dev/report_design.md) for the shape
of the report.

Every track and clip is reported in the order they appear in the ALS XML. The
`-s` / `--show_midi_and_audio_tracks_separately` option writes the audio tracks
and the MIDI tracks in their own lists instead, which is easier to read when a
set has many tracks of one kind.

The names in the report are written on the colour Live gave the corresponding
XML element, so that the colour of a track, a group or a clip can be seen at a
glance:

- the name is written in a `<code>` element, and the colors are applied as a
  style attribute.
- colors are defined in class [`LivePalette`](lib/live_set/model/live_palette.rb).
- Every node displayed in the markdown output of an ALS report is colored
  according to the value for the corresponding node in the XML of the ALS. The
  default Live colour palette is assumed.
- A track, a group or a device that P3S cannot use is highlighted.
- Uncollected samples are highlighted differently.

The reports of the reference sets are stored in
[$live_reference_sets/sets/ANALYSIS.md](https://github.com/mslinn/live_reference_sets/blob/main/sets/ANALYSIS.md).


## Sizes and Checksums

A report is intended to be used in a courtroom as reliable evidence. It must:

- Display the court case number, title, and the party funding the report
  generation.
- Display all relevant metadata (dates, size, permissions, owner, etc.).
- Prove that the set has not been tampered with.

### Checksums

Matching checksums says the two sets contain identical XML content, ignoring any
whitespace.

A set is a gzipped XML document, and two files with the same content need not
have the same bytes because of whitespace differences. The report carries both
SHA-256 checksums of the set that was read:

- the hash of the **file**, of the `.als` as it is on disk. It changes when
  anything in the file changes, including the compression.
- the hash of the **content**, of the XML the `.als` holds when it is inflated,
  without whitespace.

### Sizes

The report displays four sizes, and how each was computed.

| The size              | What it is                                                                                                                                 | How it was computed                                                    |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| The set file          | the size of the `.als`                                                                                                                     | the file on disk                                                       |
| Expected Project Size | what the project should be, according to the `.als`: the set file, and every sample the set refers to that is in the project, counted once | the sizes Live recorded, and the size on disk where Live recorded zero |
| Actual Project Size   | what the project is, on disk                                                                                                               | the files in the project folder                                        |
| Fully Resolved Size   | everything the set draws on: the project, and the assets outside it                                                                        | the expected size, with the assets outside the project added           |

The report indicates any sizes that could not be computed. For example, the
space consumed by a missing project folder cannot be verified.

### Assets

The report contains a list of the assets of the set (the samples it collects)
that were used to compute the project sizes, including:

- asset paths
- file sizes
- last modification dates

### Uncollected

An uncollected sample is marked as one that P3S cannot play, and a
sample that is not on disk is marked as one that is missing from the project.

### Devices

Ableton devices are reported with the packs that defined them, or the Live core library.

### Computer Information

If the `-c, --computer` command-line option was specified, the report includes
the state of the machine the report was made on: , and the packs the set refers to.  A pack that is not
installed is not a fault of the set — the set names the file, and the pack holds
it — so the packs that are missing are reported on their own.


The presence of extra 'Ableton Project Info' folders in parent directories is reported.

The report says what made it — the version of `live_set`, and where the tool is
documented.
