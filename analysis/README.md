# The analyses of the sets

What each set holds, written down.

The analysis of a set is the report `live_set` writes for it: the tracks of the set, the state of
each one, the effects on it, and the clips of it. The report is markdown, and it is a document
and not the output of a program: it is written to stdout, and the log of the program is written
to stderr and is never markdown.

## How they are made

```shell
bundle exec ruby bin/make_analysis
```

The tool reads every set under `sets/` and writes the report of each one into `analysis/`, one
file per set, named after the set, in a directory named for the version of Live the set is in:

```text
sets/live_11/Fascination.als
analysis/live_11/Fascination.md
```

A single set can be analysed instead of a directory of them:

```shell
bundle exec ruby bin/make_analysis "sets/live_11/Fascination.als"
```

The demo sets of Live are installed with Live and are not checked in, but their analyses are.

## What the reports hold

- **The facts about the set**: the version of Live that wrote it, the machine it is on, where it
  is, the time zone the times are written in, and the times of the set and of the project it is
  in. Live writes no date of its own in a set, so the dates are the dates of the files.
  "Project last modified" is the time of the most recently changed file of the project, and the
  file is named. The times are written in the time zone of the computer, or in the time zone
  that `-z` asks for:

  ```shell
  bundle exec ruby exe/live_set -s -z America/Chicago sets/live_11/Fascination.als
  ```

- **The verdict for a transfer to Push 3 Standalone**, with the errors and the advice that go
  with it. The clips that are not collected are counted and not named: a demo set holds dozens
  of them, and the list of them says nothing that the count does not. The count links to the
  missing samples.
- **The tracks, as an outline** (`## Groups/Tracks/Clips/Devices`). Everything in the set is
  numbered by the path of the tree it is in: the groups at the top of the set are numbered from
  one, and the tracks at the top of the set are numbered from one as well; a track in a group is
  numbered after the group and after itself, as 1.1; the devices of a track are numbered after
  the track and after the device, as 1.1a; and the clips of a track are numbered after the
  track and after the clip, as 1.1.1.

  ```text
  - Group track 1  `# Drums`  👥 Group
    - Group Track Device 1a  Filter  Max for Live  ⚠ not usable on Push 3
    - Group Track Device 1b  DrumBuss  native device
    - Track 1.1  `Kontakt 7`  🎹 MIDI
      - Track Device 1.1a  Kontakt 7  plug-in  ⚠ not usable on Push 3
      - Clip 1.1.1  `Kontakt 7 1`  ⚠ not in project, launch: trigger, linked, warped  × 8
  ```

  The colour of a track, a group and a clip is the background of its name, and the number Live
  writes for the colour is in the tooltip of the name. The text on the colour is the
  complementary colour, made as dark or as light as it has to be to be read on it: the contrast
  ratio of the two decides, and every colour of Live's palette has a text colour that reaches
  the 4.5 to 1 that the WCAG asks for.

  A track, a group and a device that Push 3 Standalone cannot use — one that is not frozen and
  that has a device Push 3 cannot run — is written on the dark background `#212121` instead of
  the colour of the thing.

  A clip of a set of Live 11 or Live 12 has no devices of its own: the devices that shape the
  sound of a clip are the devices of the track it is on, and the devices of a sample are in the
  file of the sample and not in the set.

  The marks on a clip: `⚠ not in project` when the sample is not in the folder of the project,
  `launch:` how the clip is launched, `linked` when the clip shares its sample with the other
  clips of a linked group, `warped` when the sample is time-stretched, and `warp:` the warp mode
  of the sample and the number Live writes for it. A clip that is on a track more than once is
  listed once, with the number of copies.
- **The missing samples** (`## Missing Samples`): the samples of the set that are not in the
  project, grouped by the pack they are in. Live writes the absolute path of a sample in the
  set, and the path of the pack it is in is in it.
- **The devices** (`## Device Cross-Reference`): every device of the set, and the tracks it is
  on. A device of a group is on the group and on the tracks in the group, because the chain of
  the group processes the audio of the tracks in it.
- **The clips** (`## Track / Clip Cross Reference`): every clip of the set, and the tracks that
  use it. The clips are the clips of the outline above: a clip is the same clip when it has the
  same name, the same file, the same colour and the same state. A clip that is on more than one
  track is marked, because the set shares it.

The colour of a track or a clip is the number Live writes for it, and the number is an index into
the palette of Live's colour menu. The palette is in `lib/live_set/live_palette.rb`, and it is
Live's default: the palette can be changed in the Preferences of Live.
