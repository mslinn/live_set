# `Live_set` [![Gem Version](https://badge.fury.io/rb/live_set.svg)](https://badge.fury.io/rb/live_set)

<blockquote style="border: 1px solid currentColor; padding: 12px; border-radius: 4px;">
This project is in a state of flux.
The published gem was a proof of concept.
All code and comments are aspirational until this message is deleted.
The current code probably does not work and the docs are a mess.
Come back real soon now, and things should be much better!
</blockquote>

This software can:

1. Make a copy of an Ableton Live 12 set and save to Live 11 format.

2. Report the version compatibility of an Ableton Live set.

3. Detect environmental problems, for example unwanted directories called
   `Ableton Project Info` in parent directories.

4. Display the location and size of the samples in each track.

5. Show changes that are made to a Live set.

6. Show changes persisted to file storage each time a Live session is saved in real time.

7. Clearly show if a Live set is ready to be transferred to a Push 3 Standalone,
   and what needs to be changed if not.

   a. Detect sets that are too large to be frozen, which means they are too
   large to transfer to Push 3 Standalone.

   b. Detect tracks that have non-Ableton plugins are not frozen, which means
   they are not ready to be transferred to Push 3 Standalone.

   c. Detect group tracks that have non-Ableton plugins. A group track cannot be
   frozen unless Options.txt allows it. The plugin has to be
   removed from the group&rsquo;s chain, or the group has to be bounced to
   another track and then be disabled.

   d. Show clips that are have not been collected within the set&rsquo;s
   project directory.

8. Report the samples in frozen tracks. During playback, a frozen track
   *shadows* the track with the editable material. Both tracks are reported.

The published gem converted the Ableton Live 12 demo project to Live 11. Other
functionality has been tested with Live 8.6 session files.

The conversion the published gem performed was a selective removal: it wrote the
Live 11 version strings, removed the three elements that Live 11 does not have,
and copied everything else through unchanged. Two elements that Live 11 *does*
have were translated rather than removed, because Live 12 names them
differently — see
[docs/live_11_12_diff.md](docs/live_11_12_diff.md#the-elements-the-two-versions-name-differently).

The conversion in this repository is not yet known to produce a set that Live 11
opens: the lane types are the open risk (TODO.md N42).

This project is transitioning to being driven by XLST transformations, derived
by recursively running Ableton Live in a GUI test harness. The demo programs
provided with each version of Ableton Live were an important source of
information.

## Push 3 Standalone (P3S)

**This section was updated in anticipation of work actually getting done at some
point, so it is aspirational**

Importing Ableton Live project files to the P3S is a painful process. Debugging
can be frustrating. You sometimes feel like you are spending more time
struggling with the technology than you are getting useful work done.

Live_set reports on the status of an Ableton Live set and gives a go/no go
signal for transmission to a P3S.

### Reported Problems

1. Third-Party Plugins (VST / AU)

    An unfrozen track will cause a error (or fail to produce sound) on a P3S if and
    only if it relies on software or routing that the P3S does not support.

    The Push 3 Standalone runs a customized version of Ableton Live that does not
    support third-party VST3, Audio Units (AU), or CLAP plugins.

    If an unfrozen track uses a plugin like Serum, Kontakt, FabFilter, or Valhalla,
    the Push 3 will throw a "Missing Plugin" or "Plugin not available" error when
    loading the set. The track will either be completely silent or replaced by a
    blank placeholder device.

    Freezing renders the track to a temporary audio file, baking the plugin's sound
    into the waveform. The P3S only needs to play back the audio file, completely
    bypassing the need for the missing plugin.

    If any non-Ableton plugin is not on a frozen track then live_set reports the
    problem in great detail.

2. Desktop-Specific External Audio Routing

    If a track's Audio From is set to "Ext. In" and routed to a specific channel of
    a desktop audio interface (e.g., "Ext. In: 3/4" from a Focusrite Scarlett), that
    routing will not exist on the P3S.

    The track will load, but it will be silent because the expected input hardware
    isn't there.

    If the external audio was already recorded into a clip, freezing the track
    converts that external input dependency into a self-contained audio clip.

3. Incompatible or Overloaded Max for Live (M4L) Devices

    While the P3S does support Max for Live, it has less CPU headroom than a modern desktop computer.

    Complex M4L devices might fail to load, throw DSP overload errors, or cause the
    entire set to crash on the standalone unit.

    Freezing an M4L device renders its output to audio, removing the CPU load and
    the need for the Max runtime to process it in real-time.  What is perfectly safe
    to leave unfrozen?

    You do not need to freeze tracks that only use:

    - Native Ableton Instruments: Simpler, Sampler, Drum Rack, Wavetable, Operator,
      etc. (These are built into the Push 3 OS).
    - Native Ableton Effects: EQ Eight, Compressor, Reverb, Delay, etc.
    - External MIDI Hardware: If a track is set to "MIDI To" an external hardware
      synth connected to the Push 3's MIDI out ports, it will work perfectly. The
      Push 3 will just send the MIDI notes out to your gear.


## Installation

Simply type:

```shell
$ gem install live_set
```

If the above does not work because you need to install Ruby, please
[follow these instructions](https://www.mslinn.com/ruby/1000-ruby-setup.html).


## Upgrading

Simply type:

```shell
$ gem upgrade live_set
```


## Usage

The following commands are provided:

- `live_set` reports status of a session file, or converts a Live 12 session file to
  Live 11 format.
- `als_delta` (used when Live is running) shows changes to a session file each
  time the session is saved.
- `generate_xsd` reads one or more Ableton Live sets and generates an XSD.
- `validate_asd` checks that a session file conforms to an XSD schema.

```text
$ live_set
Displays information about a Live set or converts a copy of a Live 12 set in Live 11 format.
Also verifies that 'Ableton Project Info' is in the same directory as the .als file,
and there is no parent directory with a directory of that name.

Syntax: live_set OPTIONS PATH_TO_ALS_FILE

Environment variables used in PATH_TO_ALS_FILE are expanded.

Options are:
  -11 Convert a copy of the Live 12 set to Live 11 format.
  -f If -11 is specified, overwrite any existing Live 11 set. Without it, an existing
     set is left alone.
  -v Show the version of this program.
  -z The time zone the times in the report are written in, e.g. America/Chicago. The
     times are written in the time zone of the computer when it is not given.
  -h Display this help message.

Example:
  live_set -11 -f $path/to/my_set.als
```

```text
$ als_delta
als_delta: Shows changes to an .als file each time a session file is saved.
Press any key to compare with previous version.

Syntax: als_delta OPTIONS PATH_TO_ALS_FILE

Environment variables used in PATH_TO_ALS_FILE are expanded.

Options are:
  -k Keep each backup (default is to delete them)
  -h Display this help message.

Example:
als_delta $path/to/my_v12_set.als
```

```text
Generate_xsd reads one or more Ableton Live sets and generates an XSD with the given name.

Syntax: generate_xsd OPTIONS XSD_FILE_NAME PATH_TO_ALS_FILE...

Environment variables used in XSD_FILE_NAME and PATH_TO_ALS_FILE are expanded.

Options are:
  -f Overwrite any existing xsd.
  -h Display this help message.

Example:
  generate_xsd -f xsd_file_name $path/to/my_v12_set.als
```

```text
$ validate_asd
Validate_asd checks that an Ableton Live set conforms to an XSD schema.

Syntax: validate_asd PATH_TO_ALS_FILE SCHEMA.xsd

Environment variables used in PATH_TO_ALS_FILE are expanded.

Example:
  validate_asd $path/to/my_v12_set.als schema.xsd
```


### The Report

`live_set` writes a report of a set in markdown: the tracks of the set and the groups they
are in, the devices of each of them, the clips and the take lanes, the samples that are not
in the project, and a cross-reference of the tracks and the clips.

The names in the report are written on the colour Live gave the thing, so that the colour of
a track, a group or a clip can be seen at a glance:

- the name is written in a `<code>` element, and the style is on that element and not on a
  `<span>` around it, because a renderer that gives `code` a colour of its own would
  otherwise win;
- the text on a colour is black or white, and how bright the colour looks decides which of
  the two: black on a colour that looks light, and white on a colour that looks dark;
- the tooltip of a name carries the number Live writes for the colour, which is an index
  into the colour menu of Live — the palette can be changed in the Preferences of Live, and
  the default one is in `lib/live_set/live_palette.rb`;
- a track, a group or a device that Push 3 Standalone cannot use is written on the dark
  background `#212121` with white text, and a sample that is not in the project folder is
  written on the dark red `#8B0000`.

The styles are inline, so the report carries them wherever it is rendered. The reports of the
reference sets are in the repository of the reference sets, and
[sets/ANALYSIS.md](https://github.com/mslinn/live_reference_sets/blob/main/sets/ANALYSIS.md)
describes what they hold.


### The sizes and the checksum of a set

A report is evidence: it has to say how big a set is, and it has to show that the set has not
been tampered with.

**The checksums.** A set is a gzipped XML document, and two files with the same content need
not have the same bytes. The report carries both SHA-256 checksums of the set that was read:

- the hash of the **file**, of the `.als` as it is on disk. It changes when anything in the
  file changes, including the compression.
- the hash of the **content**, of the XML the `.als` holds when it is inflated. It says the
  material of the set did not change, however it was compressed.

**The sizes.** Four of them, and the report says what each was computed from:

| The size | What it is |
| --- | --- |
| The set file | the size of the `.als` |
| The expected size of the project | what the project should be, according to the `.als`: the set file, and every sample the set refers to that is in the project, counted once |
| The actual size of the project | what the project is on disk, when the project folder is there |
| The fully resolved size | everything the set draws on: the project, and the assets outside it — the samples in the user library, the Live Packs, the Racks, the Live Clips |

A sample that is not on disk has no size on disk, and the report says so rather than
guessing. A table of the assets says what the sizes are made of: each file, the size Live
recorded for it, the size on disk, where it is, and when it was last changed.

The report says what made it — the version of `live_set`, and where the tool is documented:
<https://www.mslinn.com/av_studio/ableton_live_set.html>.


### Convert

Make the Live 12 set compatible with Live 11 and save as `path/to/my_set_11.als`:

```shell
$ live_set -11 -f path/to/my_set.als
```

The converted set uses the Live 11.3.21 schema. The sub-version is not
configurable. For more infomation, see
[docs/live_11_12_diff.md](docs/live_11_12_diff.md#converting-a-set-to-live-11-uses-a-fixed-schema).


## Experimental features

Ableton Live can be configured to enable experimental and unsupported features through an
`Options.txt` file in its Preferences folder. For example, `-_GroupTrackFreeze` allows a group
track to be bounced as though it were a track.

`live_set` does not search for a file called `Options.txt`.

TODO I am uncomfortable with the following conclusion, depending on the state of
the XML file. If an ALS file is generated somehow that has a frozen group track, we
should respect the XML file. We need to follow through and look for docs and
code that have a different goal, and fix them.

TODO One of the experimental options that might be in effect when saving a Live
set is the ability to save a frozen group track. The group data should be
converted to maintain the integrity of the data. Also see
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
`locate -i "Demo Songs"` finds them.

One Live 11 set is checked in, because no demo set of Live 11 has a return
track: `sets/live_11/projects_and_als/Fascination.als`. It comes from
[owenbush/ableton-inspector](https://github.com/owenbush/ableton-inspector),
which is under the MIT license.


### Run the Tests

```text
$ bundle exec rake test
```


### Debug run

Define the `VO_DEBUGGING` environment variable so the code is loaded from the project
instead of attempting to load the `live_set` gem.

```shell
$ VO_DEBUGGING=true ruby exe/live_set /path/to/my_set.als
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
