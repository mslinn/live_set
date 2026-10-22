# `Live_set` [![Gem Version](https://badge.fury.io/rb/live_set.svg)](https://badge.fury.io/rb/live_set)

This software can:

1. Make a copy of an Ableton Live 12 set and save to Live 11 format.

2. Report the version compatibility of an Ableton Live set.

3. Detect environmental problems, for example unwanted directories called
   `Ableton Project Info` in parent directories.

4. Display the location and size of the samples in each track.

5. Show changes that are made to a Live set.

7. Show changes persisted to file storage each time a Live session is saved in real time.

8. Clearly show if a Live set is ready to be transferred to a Push 3 Standalone,
   and what needs to be changed if not.

   a. Detect sets that are too large to be frozen, which means they are too
   large to transfer to Push 3 Standalone.

   b. Detect tracks that have non-Ableton plugins are not frozen, which means
   they are not ready to be transferred to Push 3 Standalone.

   c. Shows clips that are have not been collected within the set&rsquo;s project directory.

This program has successfully converted the Ableton Live 12 demo project to Live
11. Also tested with Live 8.6 session files.

##  Push 3 Standalone (P3S)

An unfrozen track will cause a error (or fail to produce sound) on a P3S if and
only if it relies on software or routing that the P3S does not support.

The scenarios where an unfrozen track will break on the P3S:

1. Third-Party Plugins (VST / AU) - The #1 Cause

    The Push 3 Standalone runs a customized version of Ableton Live that does not
    support third-party VST3, Audio Units (AU), or CLAP plugins.

    If an unfrozen track uses a plugin like Serum, Kontakt, FabFilter, or Valhalla,
    the Push 3 will throw a "Missing Plugin" or "Plugin not available" error when
    loading the set. The track will either be completely silent or replaced by a
    blank placeholder device.

    Freezing renders the track to a temporary audio file, baking the plugin's sound
    into the waveform. The P3S only needs to play back the audio file, completely
    bypassing the need for the missing plugin.

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

Three commands are provided:

* `live_set` reports status of a session file, or converts a Live 12 session file to
  Live 11 format.
* `als_delta` (used when Live is running) shows changes to a session file each
  time the session is saved.
* `validate_asd` checks that a session file conforms to an XSD schema.

```text
$ live_set
Displays information about a Live set or converts a copy of a Live 12 set in Live 11 format.
Also verifies that 'Ableton Project Info' is in the same directory as the .als file,
and there is no parent directory with a directory of that name.

Syntax: live_set OPTIONS PATH_TO_ALS_FILE

Environment variables used in PATH_TO_ALS_FILE are expanded.

Options are:
  -11 Convert a copy of the Live 12 set to Live 11 format.
  -f Overwrite any existing Live 11 set.
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
$ validate_asd
Validate_asd checks that an Ableton Live set conforms to an XSD schema.

Syntax: validate_asd PATH_TO_ALS_FILE SCHEMA.xsd

Environment variables used in PATH_TO_ALS_FILE are expanded.

Example:
  validate_asd $path/to/my_v12_set.als schema.xsd
```


### Report

Report the version of the [Ableton Live 12 Demo Project](https://help.ableton.com/hc/en-us/articles/209774005-Location-of-the-default-Demo-Set):

```text
$ live_set "$ableton_media/Projects/Ableton Live 12 Demo Project/Ableton Live 12 Demo.als"
/mnt/e/media/Ableton/Projects/Ableton Live 12 Demo Project/Ableton Live 12 Demo.als
  Created by Ableton Live 12.0.1
  Major version 5
  Minor version v12.0_12049
  SchemaChangeCount 7
  Revision dc76d800e94bdd5e2d8f0f72ef4d056a634a8cd7
Warning: This set should not be transferred to Push 3 Standalone.
 - Some non-frozen tracks have non-Ableton plugins.
Total set size: 312.5 MB
4 tracks:
  Track 'Vocal Main' **not frozen** (12 clips, totaling 154.0 MB)
    Samples/Imported/Vocal Patience Main.wav   12.8 MB  2024-01-31 22:00:34
    Samples/Imported/Vocal Patience Main.wav   12.8 MB  2024-01-31 22:00:34
    Samples/Imported/Vocal Patience Main.wav   12.8 MB  2024-01-31 22:00:34
    Samples/Imported/Vocal Patience Main.wav   12.8 MB  2024-01-31 22:00:34
    Samples/Imported/Vocal Patience Main.wav   12.8 MB  2024-01-31 22:00:34
    Samples/Imported/Vocal Patience Main.wav   12.8 MB  2024-01-31 22:00:34
    Samples/Imported/Vocal Patience Main.wav   12.8 MB  2024-01-31 22:00:34
    Samples/Imported/Vocal Patience Main.wav   12.8 MB  2024-01-31 22:00:34
    Samples/Imported/Vocal Patience Main.wav   12.8 MB  2024-01-31 22:00:34
    Samples/Imported/Vocal Patience Main.wav   12.8 MB  2024-01-31 22:00:34
    Samples/Imported/Vocal Patience Main.wav   12.8 MB  2024-01-31 22:00:34
    Samples/Imported/Vocal Patience Main.wav   12.8 MB  2024-01-31 22:00:34

  Track 'Vocal Harmony' **not frozen** (12 clips, totaling 154.0 MB)
    Samples/Imported/Vocal Patience Harmony.wav   12.8 MB  2024-01-31 22:00:04
    Samples/Imported/Vocal Patience Harmony.wav   12.8 MB  2024-01-31 22:00:04
    Samples/Imported/Vocal Patience Harmony.wav   12.8 MB  2024-01-31 22:00:04
    Samples/Imported/Vocal Patience Harmony.wav   12.8 MB  2024-01-31 22:00:04
    Samples/Imported/Vocal Patience Harmony.wav   12.8 MB  2024-01-31 22:00:04
    Samples/Imported/Vocal Patience Harmony.wav   12.8 MB  2024-01-31 22:00:04
    Samples/Imported/Vocal Patience Harmony.wav   12.8 MB  2024-01-31 22:00:04
    Samples/Imported/Vocal Patience Harmony.wav   12.8 MB  2024-01-31 22:00:04
    Samples/Imported/Vocal Patience Harmony.wav   12.8 MB  2024-01-31 22:00:04
    Samples/Imported/Vocal Patience Harmony.wav   12.8 MB  2024-01-31 22:00:04
    Samples/Imported/Vocal Patience Harmony.wav   12.8 MB  2024-01-31 22:00:04
    Samples/Imported/Vocal Patience Harmony.wav   12.8 MB  2024-01-31 22:00:04

  Track 'Vocal Hum' **not frozen** (1 clips, totaling 2.9 MB)
    Samples/Imported/Vocal Patience Hum.wav    2.9 MB  2024-01-31 22:03:22

  Track 'Vocal Adlib' **not frozen** (2 clips, totaling 1.7 MB)
    Samples/Imported/Vocal Patience Adlib.wav  827.9 kB  2024-01-31 22:00:22
    Samples/Imported/Vocal Patience Adlib.wav  827.9 kB  2024-01-31 22:00:22
```

A [bug](https://github.com/mslinn/live_set/issues/2) has been logged for the
above output.

### Convert

Make the Live 12 set compatible with Live 11 and save as `path/to/my_set_11.als`:

```shell
$ live_set -11 -f path/to/my_set.als
```


## Development

After checking out this git repository, install dependencies by running `bin/setup`:

```text
$ git clone https://github.com/mslinn/live_set
$ cd live_set
$ bin/setup
$ code .  # Run Visual Studio Code
```


### The File Format

[als_format.md](als_format.md) documents the parts of the Ableton Live `.als` format that this
project reads, based on a survey of 460 real sets. `bin/als_files` re-runs the survey.


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
