# `Live_set` [![Gem Version](https://badge.fury.io/rb/live_set.svg)](https://badge.fury.io/rb/live_set)

<blockquote style="border: 1px solid currentColor; padding: 12px; border-radius: 4px;">
This project is in a state of flux.
The published gem was a proof of concept.
All code and comments are aspirational until this message is deleted.
The current code probably does not work and the docs are a mess.
Come back real soon now, and things should be much better!
</blockquote>


## Capabilities

This software can:

1. Make a copy of an Ableton Live 12 set and save to Live 11 format.

2. Report the version compatibility of an Ableton Live set.

3. Detect environmental problems, for example unwanted directories called
   `Ableton Project Info` in parent directories.

4. Display the location and size of the samples in each track.

5. Show changes that are made to a Live set.

6. Show changes persisted to file storage each time a Live session is saved in real time.

7. Clearly show if a Live set is ready to be transferred to a P3S,
   and what needs to be changed if not.

   a. Detect sets that are too large to be frozen, which means they are too
   large to transfer to P3S.

   b. Detect tracks that have non-Ableton plugins are not frozen, which means
   they are not ready to be transferred to P3S.

   c. Detect group tracks that have non-Ableton plugins. A group track cannot be
   frozen unless Options.txt allows it. The plugin has to be
   removed from the group&rsquo;s chain, or the group has to be bounced to
   another track and then be disabled.

   d. Show clips that are have not been collected within the set&rsquo;s
   project directory.

8. Report the samples in frozen tracks. During playback, a frozen track
   *shadows* the track with the editable material. Both tracks are reported.


## Current Project Status

The published gem converted the Ableton Live 12 demo project to Live 11. Other
functionality has been tested with Live 8.6 session files.

The conversion the published gem performed was a selective removal: it wrote the
Live 11 version strings, removed the three elements that Live 11 does not have,
and copied everything else through unchanged. Two elements that Live 11 *does*
have were translated rather than removed, because Live 12 names them
differently — see
[docs/live_11_12_diff.md](docs/live_11_12_diff.md#the-elements-the-two-versions-name-differently).

The conversion in this repository is not yet known to produce a set that Live 11
opens: the lane types are the open risk (See `TODO.md` N42).

The demo programs provided with each version of Ableton Live are an important
source of information.


## Push 3 Standalone (P3S)

Importing Ableton Live project files to the P3S is a painful process. Debugging
can be frustrating. You sometimes feel like you are spending more time
struggling with the technology than you are getting useful work done.

The `als_report` command from `Live_set` reports on the status of an Ableton
Live set and gives a go/no go signal for transmission to a P3S.

P3S runs an embedded version of Live internally. The earliest compatible version
of a Live set that can be transferred to a P3S is Live 11. Live 12 sets can also
be transferred; the latest supported version is Live 12.4.

### Reported Problems

1. Third-Party Plugins (VST / AU)

    An unfrozen track will cause a error (or fail to produce sound) on a P3S if
    it relies on an unsupported device or routing that the P3S does not support.

    The P3S runs a customized version of Ableton Live that does not support
    non-Ableton devices, such as VST2, VST3, Audio Units (AU), or CLAP plugins.

    If an unfrozen track uses any of these non-Ableton plugins, the P3S will
    throw a "Missing Plugin" or "Plugin not available" error when loading the
    set. The track will either be completely silent or replaced by a blank
    placeholder device.

    Freezing a track renders the it to an audio file, making a permanent
    recording of the plugin's sound processing. Frozen tracks are easily played
    back by the P3S, so the plugin can be ignored while the track is frozen.

    If any non-Ableton plugin is not on a frozen track then the `als_report`
    command includes a clear explanation of the problem in its generated report.

2. Desktop-Specific External Audio Routing

    If a track's Audio From is set to "Ext. In" and routed to a specific channel of
    a desktop audio interface (e.g., "Ext. In: 3/4" from a Focusrite Scarlett), that
    routing will not exist on the P3S.

    The track will load, but it will be silent because the expected input hardware
    isn't there.

    Once again, freezing the track makes the Live set compatible with the P3S.
    Recording the external audio into a clip, then freezing the track converts
    an external input dependency into a self-contained audio clip and makes the
    Live set compatible with the P3S.

3. Incompatible or Overloaded Max for Live (M4L) Devices

    While the P3S does support Max for Live, the P3S has less CPU headroom than a
    modern desktop computer.

    Complex M4L devices might fail to load, throw DSP overload errors, or cause the
    entire set to crash on the standalone unit.

    Freezing an M4L device renders its output to audio, removing the CPU load and
    the need for the Max runtime to process it in real-time.

    You do not need to freeze tracks that only use:

    - Native Ableton Instruments: Simpler, Sampler, Drum Rack, Wavetable, Operator,
      etc. (These are built into the Push 3 OS).
    - Native Ableton Effects: EQ Eight, Compressor, Reverb, Delay, etc.
    - External MIDI Hardware: If a track is set to "MIDI To" an external hardware
      synth connected to the Push 3's MIDI out ports, it will work perfectly. The
      Push 3 will just send the MIDI notes out to your gear.


## Installation

Type:

```shell
$ gem install live_set
```

If the above does not work because you need to install Ruby, please
[follow these instructions](https://www.mslinn.com/ruby/1000-ruby-setup.html).


## Upgrading

Type:

```shell
$ gem upgrade live_set
```


## Commands

The following commands are provided:

- `als_delta` (used when Live is running) shows changes to a session file each
  time the session is saved.
- `als_diff` compares two sets element by element, and prints the differences.
- `als_nodes` prints the nodes of an XML document that an XPath expression finds.
- `als_release_notes` prints the release notes of a version of Live as markdown.
- `als_report` writes a report of a Live set in markdown.
- `als_to_version` converts a Live set to another version of the format.
- `als_to_xsd` reads one or more Ableton Live sets and generates an XSD.
- `als_validate` checks that a session file conforms to an XSD schema.
- `als_xsd_order` prints the order of the children of an element in a schema.

The examples of how to use each command assume the `$live_set` environment
variable points to an ALS file, for example:

```shell
live_12_demos="$live_reference_sets/sets/live_12/demo/projects_and_als/"
live_set="$live_12_demos/Chuck Sutton - Patience (Live 12 Suite Demo).als"
```


### `als_delta`

```text
$ als_delta -h
als_delta: Shows changes to an .als file each time a session file is saved.
Press any key to make a backup of the current version of the `als` file and
compare it with previous version.

Backups can be kept by using the -k option. By default, only one backup is
used, and it is deleted when the process exits.

Syntax: als_delta OPTIONS PATH_TO_ALS_FILE

Environment variables used in PATH_TO_ALS_FILE are expanded.

Options are:
  -k Keep each backup and timestamp it, instead of overwriting the previous backup.
  -h Display this help message.
  -l LOGLEVEL Set the log level (DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN)

Example (references an environment variable called `path`):
als_delta "$live_set"
```

#### Example

```shell
$ als_delta "$live_set"
Backing up Live set to '/mnt/c/ProgramData/Ableton/Live 12 Suite/Resources/Core Library/Lessons/Demo Songs/Chuck Sutton - Patience (Live 12 Suite Demo)_backup.als'
Press any key to display the changes to the Live set XML file, or press Esc to exit.
There were no changes to the saved live set.
Press any key to display the changes to the Live set XML file, or press Esc to exit.
Deleting '/mnt/c/ProgramData/Ableton/Live 12 Suite/Resources/Core Library/Lessons/Demo Songs/Chuck Sutton - Patience (Live 12 Suite Demo)_backup.als'
```


### `als_diff`

```text
Als_diff compares two Ableton Live sets element by element, and prints the
differences.

A Live set is XML, usually gzip-compressed, so the documents can be .als files
or files containing XML extracted from an ALS file. The two documents are
first promoted to the newer of the two ALS versions, and are then walked in
parallel: the children of two elements are matched by their names, and the
children that one of the elements has and the other does not are reported as
differences.

TODO: compare attributes as well

Syntax: als_diff [OPTIONS] FILE1 FILE2

Where: FILE1 and FILE2 are paths

OPTIONS can be specified before or after positional parameters:
  -h             Display this help message.
  --count        print the number of differences, and nothing else
  --max N        print at most N differences
  --skip NAME    do not compare the elements with this name, or anything below
                 them. This option may be given more than once.
  -l LOGLEVEL Set the log level (DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN)

The exit status is 0 when the documents are the same, and 1 when they are not.

Examples:
  als_diff live11.als live12.als
  als_diff live11.als live12.als --skip Devices --skip DeviceChain
  als_diff live11.als live12.als --count
  als_diff --skip Devices --skip DeviceChain live11.als live12.als
```


### `als_nodes`

```text
Als_nodes prints the nodes of an XML document that an XPath expression finds.

A Live set is XML, usually gzip-compressed, so the document can be a .als file or any XML
file. The XPath expression is the only thing that has to change from one question to the
next, which makes this the tool to reach for instead of writing a program for each
element.

The results are printed as a JSON array of strings, so that jq can work with them.

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
  -l LOGLEVEL Set the log level (DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN)

Examples:
  als_nodes set.als '//MidiTrack/IsTuned' --attribute Value
  als_nodes set.als '//MidiTrack' --attribute Id --attribute SelectedToolPanel
  als_nodes set.als '//MidiTrack' --attributes
  als_nodes set.als '//LiveSet/Scenes/Scene/FollowAction' --children
  als_nodes set.als '//LiveSet/MainTrack' --children | jq -r '.[]'
  als_nodes set.als '//MidiTrack' --count
```


### `als_release_notes`

```text
Als_release_notes prints the release notes of a version of Live as markdown.

The release notes are the evidence the version_diff documents are built from: they say
which differences to expect, and which version introduced each one. They are written for
the musicians who use Live, and they never give an element name or an attribute name, so
they are a filter over the differences rather than a source of them.

The notes are HTML, downloaded from Ableton's web site and kept in docs/release_notes/,
one file per version. This command reads one of them and prints it as markdown, so that
the notes can be read, searched, and pasted into a document. When the file is not there,
the notes are fetched from the page they came from.

Syntax: als_release_notes VERSION [--find PATTERN]

VERSION is the version of Live, e.g. 12, and it may name a single release, e.g. 12.0. The
notes of a single release are printed when it does.

Options are:
  --find PATTERN  print the lines of the notes that match PATTERN, each with the release
                  it belongs to. The pattern is matched without regard to case.
  -h              Display this help message.
  -l LOGLEVEL Set the log level (DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN)

Examples:
  als_release_notes 12          # the notes of Live 12
  als_release_notes 12.0        # the notes of the release 12.0
  als_release_notes 12 --find "scale awareness"
  als_release_notes 12 > docs/release_notes/live-12.md
```



### `als_report`

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

Environment variables used in PATH_TO_ALS_FILE are expanded.

Options are:
  -v  Show the version of this program.
  -z  The time zone to use in the report in, e.g. America/Chicago. The time zone
      of the computer the command ran on when this option is not specified.
  -h Display this help message.
  -l LOGLEVEL Set the log level (DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN)
  --show_midi_and_audio_tracks_separately
      Report the audio tracks and the MIDI tracks separately. By default, every
      track is displayed in the order found in the ALS file.


Example:
  als_report $path/to/my_set.als
```

#### The Report

`als_report` writes a report of a set in markdown: the tracks of the set and the groups they
are in, the devices of each of them, the clips and the take lanes, the samples that are not
in the project and the samples that are, the metadata of the set, the assets the set ships,
the packs it refers to, and a cross-reference of the tracks and the clips.

Every track of the set is written in the order Live saved it in. The
`--show_midi_and_audio_tracks_separately` option writes the audio tracks and the MIDI
tracks in their own lists instead, which is easier to read when a set has many tracks of
one kind.

The names in the report are written on the colour Live gave the thing, so that the colour of
a track, a group or a clip can be seen at a glance:

- the name is written in a `<code>` element, and the colors are applied as a
  style attribute;
- colors are defined in class [`LivePalette`](../lib/live_set/model/live_palette.rb);
- Every node displayed in the markdown output of an ALS report is colored
  according to the value for the corresponding node in the XML of the ALS. The
  default Live colour palette is assumed.
- a track, a group or a device that P3S cannot use is highlighted,
  and a sample that is not in the project folder is highlighted differently.

The styles are inline, because Mike is unaware of a widely accepted way to use
stylesheets with markdown. (TODO is this possible?) The reports of the reference
sets are in the associated repository of reference Live sets, and
[sets/ANALYSIS.md](https://github.com/mslinn/live_reference_sets/blob/main/sets/ANALYSIS.md)
describes what they hold.

#### Sample Usage

Report an ALS file this way:

```shell
live_home="/mnt/c/ProgramData/Ableton"
live_12_home="$live_home/Live 12 Suite/Resources/Core Library/Lessons/Demo Songs"
live_set="$live_12_home/Chuck Sutton - Patience (Live 12 Suite Demo).als"
zcat "$live_set" | less -x2
als_report "$live_set"
```


#### Sizes and Checksums

A report is intended to be used in a courtroom as reliable evidence. It must
display all relevant metadata (dates, size, permissions, owner, etc.), and it
must prove that the set has not been tampered with.

**Checksums:** A set is a gzipped XML document, and two files with the same
content need not have the same bytes. The report carries both SHA-256 checksums
of the set that was read:

- the hash of the **file**, of the `.als` as it is on disk. It changes when
  anything in the file changes, including the compression.
- the hash of the **content**, of the XML the `.als` holds when it is inflated.
  It says the material of the set did not change, however it was compressed.

**Sizes:** Four of them, and the report says what each was computed from:

| The size | What it is | How it was computed |
| --- | --- | --- |
| The set file | the size of the `.als` | the file on disk |
| Expected Project Size | what the project should be, according to the `.als`: the set file, and every sample the set refers to that is in the project, counted once | the sizes Live recorded, and the size on disk where Live recorded zero |
| Actual Project Size | what the project is, on disk | the files in the project folder |
| Fully Resolved Size | everything the set draws on: the project, and the assets outside it | the expected size, with the assets outside the project added |

A size that could not be computed says so: a project folder that is not there has no actual
size, and the report says that instead of the expected one.

The report contains a list of the assets of the set — the samples it ships — that explains
the sizes: the path as the set writes it, the size of the file, and when it was last
changed. A sample that is outside the set is marked as one that P3S cannot
play, and a sample that is not on disk is marked as one that is missing from the project.
The devices of Ableton are not in the list: they have no location, and they come with Live.

The report ends with the state of the machine the report was made on: the
'Ableton Project Info' folders around the set, and the packs the set refers to. A pack
that is not installed is not a fault of the set — the set names the file, and the pack holds
it — so the packs that are missing are reported on their own.

The report says what made it — the version of `live_set`, and where the tool is
documented: <https://www.mslinn.com/av_studio/ableton_live_set.html>.



### `als_validate`

```text
$ als_validate
Als_validate checks that an Ableton Live set conforms to an XSD schema.

Syntax: als_validate PATH_TO_ALS_FILE SCHEMA.xsd

Environment variables used in PATH_TO_ALS_FILE are expanded.

Options are:
  -h Display this help message.
  -l LOGLEVEL Set the log level (DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN)

Example:
  als_validate $path/to/my_v12_set.als schema.xsd
```


### `als_to_version`

Convert a set to another version of the Live format, and write it out:

```shell
$ als_to_version 11 path/to/my_set_12.als path/to/my_set_11.als
```

The set is written to the same directory as the original set to be converted,
unless another destination is named. The `-f` option overwrites any pre-existing
destination set.

```text
$ als_to_version -h
Als_to_version converts a Live set to another version of the Live format.

The direction of the conversion is given: the set is converted to the version named on
the command line. The set is written the way Live writes it, so that the converted set is
a set of that version and not merely XML that happens to mean the same thing.

Syntax: als_to_version [-f] VERSION SRC [DST]

VERSION is the Ableton Live version to be converted to, e.g. 11.
SRC is the set to convert: the path of the file, or a selector of a demo set, e.g.
  demo:11:suite  the Live 11 Suite demo set
  demo:12        the demo set of Live 12
DST is where the converted set is written. Without it, the set is written next to the set
that was converted, with the version as a suffix, e.g. set_11.als.

Options are:
  -f Overwrite the destination when it already exists.
  -h Display this help message.
  -l LOGLEVEL Set the log level (DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN)

If SRC is already at the version it is converted to, the program says so and stops.

Example:
  als_to_version 11 $path/to/my_v12_set.als
```

When converting to Live 11 format, the converted set uses the Live 11.3.21
schema. The sub-version is not configurable. For more infomation, see
[docs/live_11_12_diff.md](docs/live_11_12_diff.md#converting-a-set-to-live-11-uses-a-fixed-schema).


### `als_to_xsd`

```text
Als_to_xsd reads one or more Ableton Live sets and generates an XSD with the given name.

Syntax: als_to_xsd [OPTIONS] XSD_FILE_NAME PATH_TO_ALS_FILE...

Environment variables used in XSD_FILE_NAME and PATH_TO_ALS_FILE are expanded.

A PATH_TO_ALS_FILE that holds a glob pattern is expanded by the command, and a pattern
that holds ** matches the files in the directories below the one that is named.

Options are:
  -f Overwrite any existing xsd.
  -h Display this help message.
  -l LOGLEVEL Set the log level (DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN)

Example:
  als_to_xsd -f xsd_file_name $path/to/my_v12_set.als
```


### `als_validate`

```text
Als_validate checks that an Ableton Live set conforms to an XSD schema.

Syntax: als_validate [OPTIONS] PATH_TO_ALS_FILE SCHEMA.xsd

Environment variables used in PATH_TO_ALS_FILE are expanded.

Options are:
  -h Display this help message.
  -l LOGLEVEL Set the log level (DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN)

Example:
  als_validate $path/to/my_v12_set.als schema.xsd
```


### `als_xsd_order`

```text
Als_xsd_order prints the order of the children of an element in a generated Live schema.

The transformations of a conversion put elements in a particular place, and the schema is
where that order comes from: it is generated from the demo sets of a Live version, so it
records the order Live writes the children of an element in.

Syntax: als_xsd_order SCHEMA_FILE ELEMENT_NAME

SCHEMA_FILE is the path of a generated schema, e.g. schemas/live_12.4d1.xsd.
ELEMENT_NAME is the name of an element of the format, e.g. MidiClip.

Options are:
  -h Display this help message.
  -l LOGLEVEL Set the log level (DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN)

Example:
  als_xsd_order schemas/live_12.4d1.xsd MidiClip
  MidiClip: ["LomId", "LomIdView", "CurrentStart", ...]
```


## Live Experimental Features

Ableton Live can be configured to enable experimental and unsupported features through an
`Options.txt` file in its Preferences folder. For example, `-_GroupTrackFreeze` allows a group
track to be bounced as though it were a track.

`als_report` does not search for a file called `Options.txt`.

TODO I am uncomfortable with the following conclusion, depending on the state of
the XML file. If an ALS file is generated somehow that has a frozen group track,
we should respect the XML file. We need to follow through and look in this
project for contradictory docs and code, and fix them.

TODO One of the experimental options that might be in effect when saving a Live
set is the ability to save a frozen group track. The all of the group-related
data should be converted when upgrading between versions to maintain the
integrity of the data, unless we learn about a problem from doing that. Also see
[docs/als_notes.md](docs/als_notes.md#the-optionstxt-hidden-option).


## Development

After checking out this git repository, install dependencies by running `bin/setup`:

```text
$ git clone https://github.com/mslinn/live_set
$ cd live_set
$ bin/setup
$ code .  # Run Visual Studio Code
```


### The File Format

[docs/als_notes.md](docs/als_notes.md) documents the parts of the Ableton Live
`.als` format that this project reads, based on a survey of 460 real sets and
on the official Ableton demo sets. `bin/als_files` re-runs the survey. The terms
the documents use are defined in
[docs/glossary.md](docs/glossary.md).

The demo sets are the better evidence when the question is "what does Live 11
do?", because there is one for each version. Ableton installs them with Live:

```shell
$ bin/als_files "/mnt/c/ProgramData/Ableton/Live 11 Suite/Resources/Core Library/Lessons/Demo Songs"
$ bin/als_files "/mnt/c/ProgramData/Ableton/Live 12 Suite/Resources/Core Library/Lessons/Demo Songs"
```

Ableton documents the location in
[Location of the default Demo Set](https://help.ableton.com/hc/en-us/articles/209774005-Location-of-the-default-Demo-Set).
`locate -i "Demo Songs|Live 9 Demo"` finds them.

One extra Live 11 set is checked in, because no demo set of Live 11 has a return
track: `sets/live_11/projects_and_als/Fascination.als`. It comes from
[owenbush/ableton-inspector](https://github.com/owenbush/ableton-inspector),
which is under the MIT license.

Live 8 and 9 did not store demo sets according to the above instructions. Live 9 demo sets can be found via:

```shell
$ pwd
/mnt/c/ProgramData/Ableton/Live 9 Suite

$ find . -iname *.als | grep 'Live 9 Demo'
./Resources/Core Library/Lessons/Sets/Live 9 Demo_Intro.als
./Resources/Core Library/Lessons/Sets/Live 9 Demo_Lite.als
./Resources/Core Library/Lessons/Sets/Live 9 Demo_Standard.als
./Resources/Core Library/Lessons/Sets/Live 9 Demo_Suite.als
```

We have not got Live 8 demo sets figured out yet.


### Run the Tests

```text
$ bundle exec rake test
```


### Debug run

Define the `VO_DEBUGGING` environment variable so the code is loaded from the project
instead of attempting to load the `live_set` gem.

```shell
$ VO_DEBUGGING=true ruby exe/als_report /path/to/my_set.als
```

### Interactive Session

The following will allow you to experiment:

```shell
$ bin/console
```


### Local Installation

To install this gem onto your local machine, type:

```text
$ bundle exec rake install
```


### To Release A New Version

To create a git tag for the new version, push git commits and tags,
and push the new version of the gem to https://rubygems.org, type:

```shell
$ bundle exec rake release
```


## Contributing

Bug reports and pull requests are welcome at https://github.com/mslinn/live_set.


## License

The gem is provided as [source-available, noncommercial license](LICENSE.md).
Commercial use, and use in court-case investigations, require paid
licenses.
