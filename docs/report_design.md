# The model behind the report of a set

The report of a set — `live_set -s <set>` — is written from a model of what the set holds.
The model is built once, from the XML of the set; the report asks the model questions and
writes markdown.

This document is the design of that model. It is written before the code, so that the code
can be checked against it.

## Why the model exists

The report was written as one class, `LiveSetReport`, that read the XML itself and kept the
set in arrays and hashes:

```ruby
# what a track was
[kind, name, element, members]

# what a clip was
{ clip: element, file: path, references: [{ clip: element, index: 3, place: 'session view' }] }
```

Everything the report says is then computed from those: the outline of the set, the places
the clips of a track are in, the tracks that hold a clip, the devices of the set and the
tracks they are on. The arithmetic is spread over the whole class, and the same set is read
twice — once by `LiveSetReport` and once by `LiveTrack`, `LiveGroup` and `LiveTracks`, which
know about the audio of the set and its verdict for a transfer to Push 3 Standalone.

The model replaces both: one reading of the set, and one place where the facts about it live.

## The classes

### `LiveTracks` — the set

The model of the set: the tree of its tracks, and the cross-references between them.

| | |
| --- | --- |
| `tracks` | the tracks at the top of the set, in the order Live wrote them |
| `each_track` | every track, with its number, the groups first and then the tracks, and the members of a group after their group |
| `devices` | every device of the set, with the tracks it is on |
| `clips` | every clip of the set, with the tracks that hold it |
| `missing_samples` | the samples of the set that are not in the project, by the pack they are in |

### `LiveTrack` — a track of any kind, group tracks included

One class for every kind of track: a MIDI track, an audio track, a group track, a return
track and the master track. A group track is a track that holds other tracks, and it is
different in three ways, which are questions the class answers rather than cases the report
branches on:

| | |
| --- | --- |
| `kind` | `'MIDI'`, `'Audio'`, `'Group'`, `'Return'` or `'Master'` |
| `name` | the name Live resolved for the track |
| `color` | the number Live writes for the colour of the track |
| `number` | the number of the track in the outline: `1`, `2`, `1.1` |
| `element` | the element of the track in the XML |
| `group?` | true for a group track |
| `members` | the tracks in the group, for a group track |
| `devices` | the devices of the track, and of the group it is in |
| `clips` | the clips of the track, not counting the clips of its take lanes |
| `take_lanes` | the take lanes of the track |
| `frozen?` | true when the track is frozen; a group track never is |
| `soloed?`, `armed?` | the state of the track |
| `problem?` | true when the track cannot be transferred to Push 3 Standalone: it is not frozen, and it has a device Push 3 cannot run |
| `places` | where the clips of the track are, and how many in each place |
| `label` | the name of the track, in the forms a report writes it in |

**A group track.** A group holds no clips of its own, and it cannot be frozen, because only
a track that holds clips can be frozen. Its device chain is nested one level deeper than a
track's — the track's `DeviceChain` holds a `DeviceChain`, which holds the `Devices` — and a
group can be in a group, so the chain can be nested again. The devices of a group process
the audio of the tracks in it, so a plug-in in a group's chain blocks a transfer to Push 3
just as much as one on a track. See `docs/als_notes.md`, "The group tracks" and "The device
chain of a group".

**The devices of a track.** The devices of the group a track is in are the devices of the
track as well: the chain of the group processes the audio of the tracks in it. A report
that names the devices of a track names the group's devices too.

### `LiveClip` — a clip, and the places it is in

A clip is not copied for every place it is in. Every place — a slot of the session view, the
arrangement, a take lane — holds a *reference* to the clip, and the settings of a reference
belong to the reference.

| | |
| --- | --- |
| `name` | the name of the clip |
| `file` | the file the clip plays, or nil when it plays no file |
| `color` | the number Live writes for the colour of the clip |
| `marks` | what is said about the clip: `⚠ not in project`, and the state of it |
| `references` | the references to the clip, one for each place it is in |
| `key` | what makes a clip the same clip: its name, its file, its colour and its state |

The key is what the cross-reference is built on: the clips of the outline and the clips of
the cross-reference are the same clips.

### `LiveReference` — one place a clip is in

| | |
| --- | --- |
| `place` | where the reference is: `session view`, `arrangement`, `take lane 1.1` |
| `settings` | the settings of the reference: how it is launched, how its sample is warped |
| `clip` | the clip it refers to |

The references that have the same settings are one line, with the number of them, and the
lines are ordered by the number of references, so that the ones with the most come first.

### `LiveTakeLane` — a take lane of a track

| | |
| --- | --- |
| `name` | the name of the lane |
| `number` | the number of the lane, after the number of the track: `1.1.1` |
| `clips` | the clips of the lane |

A lane holds the takes of a recording, and the track holds the clips that are heard.

### `LiveDevice` — a device of a track

The class exists. It gains the tracks the device is on, and the kind of the device, and the
plug-in format of it.

### The name of a thing

A name in a report is written in three ways: plain, when the report sorts by it or counts
it; in code type, when the report points at a file; and on the colour Live gave the thing,
when the report shows the colour of the thing. The thing knows how to write its own name —
`label.plain`, `label.code` and `label.on_color` — so that every place a report names a
thing writes it the same way.

The name of a thing is **not** a class of its own: it is a part of the thing that has it.

## What the report does with the model

The report is a writer of markdown. It asks the model for what it needs, and it writes:

| Section of the report | What it asks the model |
| --- | --- |
| The facts about the set | the files of the project, the time zone, the version of Live that wrote the set |
| The verdict for a transfer to Push 3 | the tracks that are problems, and the clips that are not collected |
| The outline | the tracks, and for each of them its devices, its clips and its take lanes |
| The missing samples | the samples that are not in the project, by the pack they are in |
| The device cross-reference | the devices, and the tracks they are on |
| The track and clip cross-reference | the tracks and their clips, and the clips and their tracks |

## What the model replaces

In `LiveSetReport`:

- `track_tree` and `build_track_tree` — the tree of tracks, and the numbers of them
- `each_track` and `each_numbered_track` — the tracks, and the numbers of them
- `clips_of_track`, `clip_group_lines`, `grouped_clips`, `identity_of`, `clip_key` — the clips of a track, and what makes a clip the same clip
- `clip_places_of_track` — the places the clips of a track are in, and how many in each
- `tracks_of_clips` and `holds_of` — the tracks that hold each clip
- `device_uses` — the devices of the set, and the tracks they are on
- `problem_for?`, `frozen?`, `soloed?`, `armed?` — the state of a track, and whether it is a problem

And the reading of the XML that `LiveTrack`, `LiveGroup` and `LiveTracks` do for the
verdict: the same set, read twice.

## How the change is made

1. **`LiveTrack` becomes the model of a track of any kind.** It keeps what it has — the
   devices, the audio clips, the name, the frozen state — and gains what the report needs:
   the kind, the colour, the number, the members, the clips of every kind, the take lanes,
   and the answers to the questions the report asks. The group track becomes a track with
   members, and `LiveGroup` is folded into it.
2. **`LiveClip` becomes the model of a clip.** It keeps the file, the size and whether the
   file is collected, and gains the name, the colour, the marks, the references and the key.
3. **`LiveTracks` becomes the model of the set.** It holds the tree, and it answers the
   cross-reference questions: the devices and their tracks, the clips and their tracks, the
   places of a track, the missing samples.
4. **`LiveSetReport` writes markdown and nothing else.** It reads no XML, and it computes no
   counts. Every method that is left in it is a section of the report.
5. **The verdict moves into the model.** `LiveTracks#verdict_markdown` uses the same track
   objects the outline uses, so a track that the outline says is a problem is the same
   track the verdict says is a problem.

## Open questions

- Does `LiveTrack` keep its name, or is the model of a track called something else, since
  `LiveSet` is taken by the command that runs the program?
- The verdict is written in markdown by `LiveTracks`, and the report is written in markdown
  by `LiveSetReport`. Should the verdict be part of the report — one writer of markdown —
  and the model return the facts the verdict is written from?
- The reference sets are checked in, and their reports with them. The change must not
  change what the reports say, apart from what was asked for: the colours, and the names in
  the cross-reference tables.
