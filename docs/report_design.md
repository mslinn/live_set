# The model behind the report of a set

The report of a set — `als_report -s <set>` — is written from a model of what the set holds.
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
and the tracks they are on. The same set was read twice as well — once by `LiveSetReport` and
once by `LiveTrack`, `LiveGroup` and `LiveTracks`, which know about the audio of the set and
its verdict for a transfer to Push 3 Standalone.

The model replaces both: one reading of the set, and one place where the facts about it live.
`LiveSetReport` is retired with them: the report is the model of the set written as markdown
by the serializer of the model.

## The rules

- **A model represents the XML entity.** It holds what the XML holds and nothing else.
- **A model holds no numbers.** The XML has no notion of a track number or a clip number, so
  no model has one. The serializer generates the numbers, and passes them to the serializers
  of the things under it.
- **A model does not write markdown.** A serializer is an object, initialized with a model
  instance, and it writes the markdown of the model it was given. The serializers mirror the
  model hierarchy: each model class has a small serializer class of its own. A model that
  has a `to_markdown` of its own only delegates to the serializer that writes it.
- **Every collection is a class of its own**, named for the things it holds, and it has a
  serializer of its own.
- **The indent of a thing comes from its number.** The number of a thing in the report says
  how deep it is: `1` is a track at the top of the set, `1.1` is a child of it, and `1a` — a
  device of the track `1` — is a child of it too. The indent is derived from the number, so
  that the number of a thing and the place of it in the outline can never disagree.
- **The outline is one list.** Every line of the outline is a list item of the same kind, so
  that a renderer takes the children of a thing for its content and not for a list of their
  own.

## The classes

### `AlsModel` — the file

The complete model of the contents of an ALS file: its path, its XML, the times of the file,
and the Live contents of the file, which it holds as `live_set`.

The class is in `lib/live_set/model/als_model.rb`, and its serializer,
`AlsModelSerializer`, writes the report of the whole model: the header block, the Push 3
compatibility, the hierarchy of groups, tracks, clips and devices, the missing samples, and
the two cross-references.

### `AlsReport` — the command that writes the report

The report of a set is written by the `als_report` command, and the class that implements it
is `AlsReport`, in `lib/als_report/als_report.rb`. It builds the model of the set — the
`AlsModel` — and asks the serializer of the model for the markdown of it.

### `LiveTracks` — the tracks of the set

The model of the `<Tracks>` element of the XML. It deviates from the usual pattern in that
it has two kinds of child: `LiveMidiTracks` and `LiveAudioTracks`. It also holds the ids of
the tracks, in the order Live wrote them.

| | |
| --- | --- |
| `track_ids` | the ids of the tracks of the set, in the order Live wrote them |
| `midi_tracks` | the MIDI tracks of the set, and the MIDI tracks of a group |
| `audio_tracks` | the audio tracks of the set, and the audio tracks of a group |
| `return_tracks` | the return tracks of the set |
| `groups` | the groups of the set |
| `top_level_tracks` | the tracks that are in no group, in the order Live wrote them |
| `audio_clips` | the clips of the audio side of every track of the set |
| `missing_samples` | the samples of the set that are not in the project, by the pack they are in |

The list of ids is what lets the tracks be written in the order they are found in the ALS
XML: the MIDI tracks and the audio tracks are two collections, and the order of the tracks
of the set is the order of the elements in the file, not the order of the collections.

By default, every track of the set is written in the order it was saved in. The
`--show_midi_and_audio_tracks_separately` option writes the audio tracks and the MIDI
tracks in their own lists instead.

### `LiveMidiTrack`, `LiveAudioTrack`, `LiveReturnTrack`, `LiveMasterTrack` — the tracks

The XML has an element for each kind of track, and the model has a class for each of them:
a `<MidiTrack>` is a `LiveMidiTrack`, an `<AudioTrack>` is a `LiveAudioTrack`, a
`<ReturnTrack>` is a `LiveReturnTrack`, and the `<MasterTrack>` (the `<MainTrack>` in Live
12) is a `LiveMasterTrack`. There is no class for "a track", because there is no element
for one.

| | |
| --- | --- |
| `kind` | `'MIDI'`, `'Audio'`, `'Return'`, `'Master'` or `'Main'` |
| `name` | the name Live resolved for the track |
| `user_name` | the name the user typed for the track |
| `color` | the number Live writes for the colour of the track |
| `devices` | the devices of the track itself |
| `chain_devices` | every device in the chain of the track, at any depth |
| `clips` | the MIDI clips of the track, not counting the clips of its take lanes |
| `audio_clips` | the clips of the audio side of the track (an audio track only) |
| `take_lanes` | the take lanes of the track |
| `group_id` | the id of the group the track is in, or nil when it is in no group |
| `frozen?` | true when the track is frozen |
| `soloed?`, `armed?`, `off?` | the state of the track |
| `problem?` | true when the track cannot be transferred to Push 3 Standalone: it is not frozen, and it has a device Push 3 cannot run |

**A MIDI track and an audio track.** A MIDI track holds MIDI clips and plays no file. An
audio track plays files, and it can hold MIDI clips as well. The clips of the audio side of
a track are `LiveAudioClip`, and they say where the file is, how big it is, and whether it
is in the project.

**The devices of a track.** The devices of the group a track is in are the devices of the
track as well: the chain of the group processes the audio of the tracks in it. A report
that names the devices of a track names the group's devices too.

### `LiveGroup` — a group of the set

A model of the track group in the XML: the group, its devices, and the tracks in it. The
members of a group are MIDI tracks and audio tracks, and each of them is a model of its own
kind.

**A group track.** A group holds no clips of its own, and it cannot be frozen, because only
a track that holds clips can be frozen. Its device chain is nested one level deeper than a
track's — the track's `DeviceChain` holds a `DeviceChain`, which holds the `Devices` — and a
group can be in a group, so the chain can be nested again. The devices of a group process
the audio of the tracks in it, so a plug-in in a group's chain blocks a transfer to Push 3
just as much as one on a track. See [als_notes.md](als_notes.md), "The group tracks" and "The
device chain of a group".

### `LiveDevice` — a device of a chain

Its name, its kind, its plug-in format, and whether Push 3 Standalone can run it. A device
on a frozen track is written in the ordinary way and carries no warning, because freezing a
track renders its devices away, so the serializer of a device is told whether the track is
frozen.

### `LiveMidiClip` — one MIDI clip in the file

A clip belongs to a place. Every place — a slot of the session view, the arrangement, a take
lane — holds the whole clip, and the settings of it belong to it. There is no reference to
a clip in the format. See [als_notes.md](als_notes.md), "Every place holds its own clip".

A MIDI clip holds notes and plays no file. The clip of the audio side of a track is
`LiveAudioClip`, and it is a different thing: it holds a file.

| | |
| --- | --- |
| `name` | the name of the clip |
| `color` | the number Live writes for the colour of the clip |
| `launch_mode` | how the clip is launched |
| `warp_mode` | how the clip's sample is warped, and whether it is warped at all |
| `notes` | the notes of the clip |
| `place` | where the clip is: `session view`, `arrangement`, `take lane 1.1` |

Two clips that carry the same name, file, colour and state are alike, and the report counts
them together. That grouping is the report's own, and it is done in the report.

### `LiveAudioClip` — a clip of the audio side of a track

The file the clip plays, and the facts about that file: where it is, how big it is, and
whether it is in the project.

| | |
| --- | --- |
| `name` | the name of the clip |
| `file` | the file the clip plays, relative to the project |
| `path` | the path Live wrote for the file, which says which pack it is in |
| `absolute_path` | where the file is, resolved against the directory of the set |
| `file_size` | the size of the file, as Live recorded it, and as it is on disk |
| `color` | the number Live writes for the colour of the clip |
| `marks` | what is said about the clip: `⚠ missing from project`, and the state of it |
| `launch_mode` | how the clip is launched |
| `warp_mode` | how the clip's sample is warped, and whether it is warped at all |
| `place` | where the clip is: `session view`, `arrangement`, `take lane 1.1` |

### `LiveAudioTrack` — the audio side of a track

The name and the colour of the track, and the clips of that audio. The line of the track
itself is written by the serializer of the track.

### `LiveTakeLane` — a take lane of a track

Its name, and the clips of it. A lane holds the takes of a recording, and the track holds
the clips that are heard.

### `LiveSample` — a file of the set

The file on disk, and the pack it is in. Several clips can point at the same file, and each
can play it differently — reversed, warped differently, trimmed — without touching the file.

| | |
| --- | --- |
| `path` | the path Live wrote for the file, which says which pack it came from |
| `relative_path` | the path of the file relative to the project folder |
| `in_set?` | true when the relative path resolves within the set |
| `found?` | true when the file is on disk |
| `pack`, `pack_path` | the pack the file came from, and the path of it |
| `library` | the library of Live the file came from: the user library, or the Core Library |
| `collected?` | true when the file was copied into the project's `Samples/Imported/` folder |

### `LiveOrigin` — where a file comes from

The path Live wrote for a file says where the file was when the set was saved: in the
project, in the user library, in the Core Library of Live, or in a pack. The content of a
pack is under a folder of its own — `Samples`, `Sounds`, `IRs`, `Devices`, `Racks`,
`Presets` — and the pack is the folder above it. The libraries of Live are not packs.

See [als_notes.md](als_notes.md), "Where a file comes from".

### `LivePack` — a pack the set refers to

The name of the pack, the path of the folder of it, and whether the pack is on this machine.

### `LivePacks` — the packs of the set

The packs the set refers to, the ones that are on this machine, and the ones that are not. A
pack that is not installed is not a fault of the set: the set names the file, and the pack
holds it.

### `MissingSamples`

The samples of the set that are not in the project, by the pack they are in. It is the part
of the samples that is missing, so it is a view of that collection and not a collection of
its own.

### `LiveAsset` — a file the set refers to

One `FileRef` of the set: the path as the set writes it, how the path was resolved, the
size Live recorded for it, the size on disk, where it is, and when it was last changed.

### `LiveSizes` — the sizes of the set

The four sizes: the set file, the expected size of the project, the actual size of the
project, and the fully resolved size. Each of them says what it was computed from, and a
size that could not be computed says so.

### `LiveChecksums` — the checksums of the set

File hash, and the hash of the content the file holds when it is inflated.

### `LiveProjectInfo` — the 'Ableton Project Info' folders around the set

The folders of that name in the directory of the set and in its parent directories, and what
is wrong with them. The folders are a fact about the machine the report is made on, and not
about the set, so the report says what it found and what it means: Live gets confused by a
folder of that name in a parent folder of the folder of the project. See
[als_notes.md](als_notes.md), "The 'Ableton Project Info' folder".

### `HeaderBlock` — the facts about the set

The version of Live that wrote the set, the computer it is on, the times of the set and of
the project it is in, and the time zone the times are written in.

## The collections

| The collection | It holds |
| --- | --- |
| `LiveTracks` | the `<Tracks>` element of the set: the MIDI tracks, the audio tracks, the return tracks and the groups |
| `LiveMidiTracks` | the MIDI tracks of the set, and the MIDI tracks of a group |
| `LiveAudioTracks` | the audio tracks of the set, and the audio tracks of a group |
| `LiveReturnTracks` | the return tracks of the set |
| `LiveMasterTracks` | the master track of the set |
| `LiveGroups` | the groups of the set |
| `LiveDevices` | the devices of a track, or of a group |
| `LiveTakeLanes` | the take lanes of a track |
| `LiveClips` | the MIDI clips of the set, and the MIDI clips of a track |
| `LiveSamples` | the samples of the set |
| `LiveAudioClips` | the clips of the audio side of a track |
| `LiveAssets` | the files the set refers to |

## What the model replaces

In `LiveSetReport`, which is retired:

- `track_tree` and `build_track_tree` — the tree of tracks
- `each_track` and `each_numbered_track` — the tracks
- `clips_of_track`, `clip_group_lines`, `grouped_clips`, `identity_of`, `clip_key` — the
  clips of a track, and what makes two clips alike
- `clip_places_of_track` — the places the clips of a track are in, and how many in each
- `tracks_of_clips` and `holds_of` — the tracks that hold each clip
- `device_uses` — the devices of the set, and the tracks they are on
- `problem_for?`, `frozen?`, `soloed?`, `armed?`, `off?` — the state of a track, and whether
  it is a problem

And the reading of the XML that `LiveTrack`, `LiveGroup` and `LiveTracks` did for the
verdict: the same set, read twice.
