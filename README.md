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


### Sample Report

The report of a set is markdown. It names the tracks of the set, the state of each one, the
effects on it, and the clips of it, as an outline: everything in the set is numbered by the
path of the tree it is in, the colour of each thing is the background of its name, and the
take lanes of a track are under the track. It is written to stdout, and the log of the
program is written to stderr and is never markdown.

Report the version of the Live 12 Standard demo set:

```markdown
# `Chuck Sutton - Patience (Live 12 Standard Demo).als`

|||
|:-|-:|
|Directory|`/mnt/c/ProgramData/Ableton/Live 12 Suite/Resources/Core Library/Lessons/Demo Songs`|
|Format|12.0_12402|
|On Computer|Bear (FC6C93DD-4C5E-B619-A95F-047C164F69AA)|
|Project created|2026-09-16 14:11:47|
|Project last modified|`Chuck Sutton - Patience (Live 12 Suite Demo).als`<br>2026-07-02 20:37:30|
|Report generated|Generated 2026-11-01 13:30:18 by live_set v0.2.5|
|Revision|42bc084cd8152e4fb737ef3fefd04b2bea5320e7|
|SchemaChangeCount|1|
|Set created|2026-09-16 14:11:47|
|Set last modified|2026-07-02 20:37:30|
|Time zone|America/New_York (UTC-4)|
|Written by|Ableton Live 12.4d1|

## Push 3 Standalone

❌ Warning: This set should not be transferred to Push 3 Standalone.
- [5 clips have not been collected.](#missing-samples)
- Track 'Vocal Main' is unfrozen; devices: Eq8, Vocoder, Reverb, GrainDelay, AutoPan
- Track 'Vocal Harmony' is unfrozen; devices: Eq8, Vocoder, Reverb, GrainDelay, AutoPan
- Track 'Vocal Hum' is unfrozen; devices: Reverb
- Track 'Vocal Adlib' is unfrozen; devices: StereoGain, Echo, AutoFilter

A clip is its name and the file it plays. Live writes a copy of a clip for every place it is in — the session view, the arrangement, a take lane — and the copies are the references to the clip. The settings of a reference — how it is launched, how its sample is warped — belong to the reference and not to the clip, and are given on the references. The take lanes of a track are under the track. The mark `⚠ not in project` means the sample is not in the folder of the project, and the set is not self-contained.

- Track 1  🎹 MIDI  <span style="background-color:#D3E499;color:#6648CE" title="color 32"><code>Coffee Leaf</code></span>  🔴 armed
  - Track Device 1a  <code>Drift</code>  native device
  - Track Device 1b  <code>StereoGain</code>  native device
  * Clip 1.1 (×6)  <span style="background-color:#D3E499;color:#6648CE" title="color 32"><code>Coffee Lead</code></span>  <span style="background-color:#8B0000;color:#FFFFFF">⚠ not in project</span>
    * References (×6): warps: launch: trigger
  - Take lane 1.1  Drift
    * Clip 1.1.1 (×1)  <span style="background-color:#D3E499;color:#6648CE" title="color 32"><code>Drift</code></span>  <span style="background-color:#8B0000;color:#FFFFFF">⚠ not in project</span>
      * References (×1): warps: launch: trigger
  - Take lane 1.2  Drift 2
    * Clip 1.2.1 (×1)  <span style="background-color:#D3E499;color:#6648CE" title="color 32"><code>Drift 2</code></span>  <span style="background-color:#8B0000;color:#FFFFFF">⚠ not in project</span>
    ... the rest of the tracks ...
## Missing Samples

|Pack|Samples|
|:-|:-|
|Core Library|`Vocal Patience Main.wav`, `Vocal Patience Harmony.wav`, `Vocal Patience Hum.wav`, `Vocal Patience Adlib.wav`|

```

The analyses of the sets are in the repository of the reference sets, in the reports directory of
the version of each set.

A [bug](https://github.com/mslinn/live_set/issues/2) has been logged for the
above output.

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
