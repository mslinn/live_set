# The analyses of the sets

What each set holds, written down.

The analysis of a set is the report `live_set` writes for it: the tracks of the set, the state
of each one, the effects on it, the clips of it, and the tracks that use each clip. The report
is markdown, and it is a document and not the output of a program: it is written to stdout, and
the log of the program is written to stderr and is never markdown.

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

The report of a single set is written by:

```shell
bundle exec ruby exe/live_set -s sets/live_11/Fascination.als
```

## What the reports hold

- **The facts about the set**: the version of Live that wrote it, the machine it is on, where it
  is, and the times of the set and of the project folder it is in. Live writes no date of its
  own in a set, so the dates are the dates of the files.
- **The verdict for a transfer to Push 3 Standalone**, with the errors and the advice that go
  with it.
- **The tracks**, in a table: the state of each one (frozen, off, soloed, armed), the color of
  it, and how many clips it holds. The members of a group are under the group.
- **The clips**, under the track they are on: the name of each, its color, its state (disabled,
  how it is launched, whether it is linked, whether it is warped), and the file it refers to.
- **The cross-reference**: every clip of the set, and the tracks that use it. A clip that is on
  more than one track is marked, because the set shares it.

The color of a track or a clip is the number Live writes for it, and the number is an index into
the palette of Live's color menu. The palette is in `lib/live_set/live_palette.rb`, and it is
Live's default: the palette can be changed in the Preferences of Live.

The tables are HTML, and not markdown, because the cell of the color is filled with the color,
and a markdown table has no way of saying that.
