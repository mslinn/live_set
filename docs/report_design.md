# The model behind the report of a set

The report of a set — `live_set -s <set>` — is written from a model of what the set holds.
The model is built once, from the XML of the set; the report asks the model questions and
writes markdown.

This document is the design of that model. The plan of the work is in
[serializer_plan.md](serializer_plan.md), which is the plan of record.

## Why the model exists

The report was written as one class, `LiveSetReport`, that read the XML itself and kept the
set in arrays and hashes:

```ruby
# what a track was
[kind, name, element, members]

# what a clip was
{ clip: element, file: path, references: [{ clip: element, index: 3, place: 'session view' }] }
```

Everything the report says is computed from those, in the report: the outline of the set,
the places the clips of a track are in, the tracks that hold a clip, the devices of the set
and the tracks they are on. The same set is read twice as well — once by `LiveSetReport` and
once by `LiveTrack`, `LiveGroup` and `LiveTracks`, which know about the audio of the set and
its verdict for a transfer to Push 3 Standalone.

The model replaces both: one reading of the set, and one place where the facts about it live.

## The rules

- **A model represents the XML entity.** It holds what the XML holds and nothing else.
- **A model holds no numbers.** The XML has no notion of a track number or a clip number, so
  no model has one. The serializer generates the numbers, and passes them to the serializers
  of the things under it.
- **A model does not write markdown.** A serializer is an object, initialized with a model
  instance, and it writes the markdown of the model it was given. The serializers mirror the
  model hierarchy: each model class has a small serializer class of its own.
- **Every collection is a class of its own**, named for the things it holds, and it has a
  serializer of its own.

## The classes

### `AlsModel` — the file

The complete model of the contents of an ALS file: its path, its XML, the times of the file,
and the Live contents of the file, which it holds as `live_set`.

The class is in `lib/live_set/model/als_model.rb`, and its serializer,
`AlsModelSerializer`, writes the report of the whole model: the header block, the Push 3
compatibility, the hierarchy of groups, tracks, clips and devices, the missing samples, and
the two cross-references.

### `LiveSet` — the Live contents of the file

The tracks, the groups, the devices, the clips and the samples of the set. `LiveSet` is the
name of the command that runs the program — `lib/live_set/live_set_class.rb` — and that is
the class the command is; the model of the contents of a set is `AlsModel`.

### `LiveTracks` — the tracks of the set, and the tracks of a group

| | |
| --- | --- |
| `tracks` | the tracks at the top of the set, in the order Live wrote them |
| `members` | the tracks in a group |
| `devices` | the devices of the set, with the tracks they are on |
| `clips` | the clips of the set, with the tracks they are in |
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
| `element` | the element of the track in the XML |
| `group?` | true for a group track |
| `members` | the tracks in the group, for a group track |
| `devices` | the devices of the track, and of the group it is in |
| `clips` | the clips of the track, not counting the clips of its take lanes |
| `take_lanes` | the take lanes of the track |
| `frozen?` | true when the track is frozen; a group track never is |
| `soloed?`, `armed?`, `off?` | the state of the track |
| `problem?` | true when the track cannot be transferred to Push 3 Standalone: it is not frozen, and it has a device Push 3 cannot run |

**A group track.** A group holds no clips of its own, and it cannot be frozen, because only
a track that holds clips can be frozen. Its device chain is nested one level deeper than a
track's — the track's `DeviceChain` holds a `DeviceChain`, which holds the `Devices` — and a
group can be in a group, so the chain can be nested again. The devices of a group process
the audio of the tracks in it, so a plug-in in a group's chain blocks a transfer to Push 3
just as much as one on a track. See [als_notes.md](als_notes.md), "The group tracks" and "The
device chain of a group".

**The devices of a track.** The devices of the group a track is in are the devices of the
track as well: the chain of the group processes the audio of the tracks in it. A report
that names the devices of a track names the group's devices too.

### `LiveGroup` — a group of the set

A model of the track group in the XML: the group, its devices, and the tracks in it.

### `LiveDevice` — a device of a chain

Its name, its kind, its plug-in format, and whether Push 3 Standalone can run it. A device
on a frozen track is written in the ordinary way and carries no warning, because freezing a
track renders its devices away, so the serializer of a device is told whether the track is
frozen.

### `LiveClip` — one clip in the file

A clip belongs to a place. Every place — a slot of the session view, the arrangement, a take
lane — holds the whole clip, and the settings of it belong to it. There is no reference to
a clip in the format. See [als_notes.md](als_notes.md), "Every place holds its own clip".

| | |
| --- | --- |
| `name` | the name of the clip |
| `file` | the file the clip plays, or nil when it plays no file |
| `color` | the number Live writes for the colour of the clip |
| `marks` | what is said about the clip: `⚠ not in project`, and the state of it |
| `launch_mode` | how the clip is launched |
| `warp_mode` | how the clip's sample is warped, and whether it is warped at all |
| `place` | where the clip is: `session view`, `arrangement`, `take lane 1.1` |

Two clips that carry the same name, file, colour and state are alike, and the report counts
them together. That grouping is the report's own, and it is done in the report.

### `LiveTakeLane` — a take lane of a track

Its name, and the clips of it. A lane holds the takes of a recording, and the track holds
the clips that are heard.

### `LiveSample` — a file of the set

The file on disk, and the pack it is in. Several clips can point at the same file, and each
can play it differently — reversed, warped differently, trimmed — without touching the file.

### `MissingSamples`

The samples of the set that are not in the project, by the pack they are in. It is the part
of the samples that is missing, so it is a view of that collection and not a collection of
its own.

### `HeaderBlock` — the facts about the set

The version of Live that wrote the set, the computer it is on, the times of the set and of
the project it is in, and the time zone the times are written in.

## The collections

| The collection | It holds |
| --- | --- |
| `LiveTracks` | the tracks of the set, and the tracks of a group |
| `LiveGroups` | the groups of the set |
| `LiveDevices` | the devices of a track, or of a group |
| `LiveTakeLanes` | the take lanes of a track |
| `LiveClips` | the clips of the set, and the clips of a track |
| `LiveSamples` | the samples of the set |
| `LiveAudioClips` | the clips of the audio side of a track |

## What the model replaces

In `LiveSetReport`:

- `track_tree` and `build_track_tree` — the tree of tracks
- `each_track` and `each_numbered_track` — the tracks
- `clips_of_track`, `clip_group_lines`, `grouped_clips`, `identity_of`, `clip_key` — the
  clips of a track, and what makes two clips alike
- `clip_places_of_track` — the places the clips of a track are in, and how many in each
- `tracks_of_clips` and `holds_of` — the tracks that hold each clip
- `device_uses` — the devices of the set, and the tracks they are on
- `problem_for?`, `frozen?`, `soloed?`, `armed?`, `off?` — the state of a track, and whether
  it is a problem

And the reading of the XML that `LiveTrack`, `LiveGroup` and `LiveTracks` do for the
verdict: the same set, read twice.
