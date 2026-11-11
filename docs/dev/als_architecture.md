# ALS Architecture

This document describes how this project uses Ruby classes to model ALS XML
entities, and a high-level description of how serializers generate markdown.

The ALS format changes with every Ableton Live release. The `live_set` project
is designed to handle structural differences in ALS files, such as an element
name that was renamed, or elements that exist in one version but not in another.

## Target Architecture

- Ableton Live sets are stored in ALS files, containing XML.
- This project has (or will have) a model class for every node type in the XML.
  - The ALS XML hierarchy of nodes will be mirrored by the hierarchy of Ruby classes
  defined in this project's `lib/live_set/model` directory.
  - Just as some ALS XML nodes have child collections, the Ruby model classes
    have mirror collections of child models (e.g. LiveTrack contains an
  array of LiveClip.)
- Every model class has an associated serializer class. Another way of saying
  this is: a parallel hierarchy of serializers mirrors the model hierarchy,
  which mirrors the XML structure. The serializer class is responsible for
  generating a markdown representation, and includes methods for escaping
  characters and namespace support. Serializers are initialized from a model
  class instance.
- [Class AlsModel](lib/live_set/model/als_model.rb) holds everything stored in
  an ALS file. We can call this singleton instance "the ALS model."
- Where several serializers have common behaviour, that behaviour shall be
  extracted into a helper of some sort.

### Single Instance Classes

Many ALS XML entities in the `</Ableton>`

## Rubygem Commands

Every command defined by this project is named with the `als_` prefix, and the
class that implements a command is named after the command. The class has a
`run` method that takes the command line arguments, and a `help` method that
prints what the command does and what its options mean.

Commands mix in the `Command` module, defined in `lib/common/command.rb`;
provides functionality common to all commands, including option parsing, and logging.

Every command takes `-l` (or `--log`) with the level of the messages it writes to the
standard error: `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL` or `UNKNOWN`. The help of every
command names the levels.

| Command             | Class             | Function                                                      |
| ------------------- | ------------------| ------------------------------------------------------------- |
| `als_report`        | `AlsReport`       | Writes the report of a set in markdown. See report_design.md. |
| `als_to_version`    | `AlsToVersion`    | Converts a set to another version of the format               |
| `als_delta`         | `AlsDelta`        | Shows the changes to a set each time Live saves it            |
| `als_to_xsd`        | `AlsToXsd`        | Writes a schema of the format from the demo sets              |
| `als_validate`      | `AlsValidate`     | Checks a set against a schema                                 |
| `als_nodes`         | `AlsNodes`        | Shows the nodes of a document that an XPath expression finds  |
| `als_diff`          | `AlsDiff`         | Compares two sets element by element                          |
| `als_release_notes` | `AlsReleaseNotes` | Shows the release notes of a version of Live as markdown      |


## Testing

Standard operating procedure is:

1. For each ALS version that we support (Live 8.4 to 12.x):

   1. Maintain one complete test of the best ALS file we know of that exercises
    each feature. At present we just extract an XML file from the largest Live
    12 demo and save it as test fixture data. Later we will find (or create)
    better test data, and an ALS file for every Live version we support.

   2. Unit tests that fully exercise every leaf node of the serializer class
    tree. (Notify the user of any missing tests)

       1. Inflate test ALS models from the text fixture data

       2. We require unit tests that fully exercise each serializer.

       3. Compare results against literal strings. These strings should be reviewed by a human familiar with CSS.


## Classes

### `AlsModel` — The Entire ALS File

The complete model of the contents of an ALS file: its path, its XML, the times
of the file, and the Live contents of the file, which it holds as `live_set`.

The class is in `lib/live_set/model/als_model.rb`, and its serializer,
`AlsModelSerializer`, writes the report of the whole model. See the [Report Sections](report_design.md#report-sections).

### `AlsReport` — Report Writer

The [`als_report` command](../exe/als_report) generates a report of a set in
markdown format. The top-level implementation class is `AlsReport`, defined in
[`lib/als_report/als_report.rb`](../lib/als_report/als_report.rb). It builds the
model of the entire set (`AlsModel`) and uses `AlsModelSerializer`, defined in
[`lib/live_set/serializer/als_model_serializer.rb`](../lib/live_set/serializer/als_model_serializer.rb),
to generate markdown.

### Collections

| The collection     | It holds                                                                                               |
| ------------------ | ------------------------------------------------------------------------------------------------------ |
| `LiveTracks`       | the `<Tracks>` element of the set: the MIDI tracks, the audio tracks, the return tracks and the groups |
| `LiveMidiTracks`   | the MIDI tracks of the set, and the MIDI tracks of a group                                             |
| `LiveAudioTracks`  | the audio tracks of the set, and the audio tracks of a group                                           |
| `LiveReturnTracks` | the return tracks of the set                                                                           |
| `LiveGroups`       | the groups of the set                                                                                  |
| `LiveDevices`      | the devices of a track, or of a group                                                                  |
| `LiveTakeLanes`    | the take lanes of a track                                                                              |
| `LiveSamples`      | the samples of the set                                                                                 |
| `LivePacks`        | the packs the set refers to                                                                            |
| `LiveAudioClips`   | the clips of the audio side of a track                                                                 |
| `LiveAssets`       | the files the set refers to                                                                            |

### `LiveTracks` — Non-Standard Model Class

The `LiveTracks` class models the ALS XLM `<Tracks>` element. It deviates from
the usual pattern in that it has several types of child classes, including
`LiveMidiTracks` and `LiveAudioTracks`. `LiveTracks` also holds a list of track ids in
the order Live wrote them.

|                    |                                                                             |
| ------------------ | --------------------------------------------------------------------------- |
| `track_ids`        | the ids of the tracks of the set, in the order Live wrote them              |
| `midi_tracks`      | the MIDI tracks of the set, and the MIDI tracks of a group                  |
| `audio_tracks`     | the audio tracks of the set, and the audio tracks of a group                |
| `return_tracks`    | the return tracks of the set                                                |
| `groups`           | the groups of the set                                                       |
| `top_level_tracks` | the tracks that are in no group, in the order Live wrote them               |
| `audio_clips`      | the clips of the audio side of every track of the set                       |
| `blocking_tracks`  | the tracks that stop the set from being transferred, and the devices that do |
| `blocking_groups`  | the groups that stop the set from being transferred, and the devices that do |

By default, every track of the set is reported in the order it was found in the
ALS XML. The `als_report --show_midi_and_audio_tracks_separately` option writes
the audio tracks and the MIDI tracks in separete lists instead.

#### Track Types

The ALS XML has an element for each kind of track, and the model has a class for each of them:

- XML element `<MidiTrack>` is modeled by `LiveMidiTrack`
- XML element `<AudioTrack>` is modeled by `LiveAudioTrack`
- XML element `<ReturnTrack>` is modeled by `LiveReturnTrack`
- XML element `<MasterTrack>` (renamed to `<MainTrack>` in Live 12) is modeled
  by `LiveMasterTrack`.

Each of these classes is enriched by mixing in [`LiveTrackFacts`](../lib/live_set/model/live_track_facts.rb).

|                             |                                                                                                                         |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `kind`                      | `MIDI`, `Audio`, `Return`, `Master` or `Main`                                                                           |
| `name`                      | the name Live resolved for the track                                                                                    |
| `user_name`                 | the name the user typed for the track                                                                                   |
| `color`                     | the number Live writes for the colour of the track                                                                      |
| `devices`                   | the devices of the track itself                                                                                         |
| `chain_devices`             | every device in the chain of the track, at any depth                                                                    |
| `clips`                     | the MIDI clips of the track, not counting the clips of its take lanes                                                   |
| `audio_clips`               | the clips of the audio side of the track (an audio track only)                                                          |
| `take_lanes`                | the take lanes of the track                                                                                             |
| `group_id`                  | the id of the group the track is in, or nil when it is in no group                                                      |
| `frozen?`                   | true when the track is frozen                                                                                           |
| `soloed?`, `armed?`, `off?` | the state of the track                                                                                                  |
| `problem?`                  | true when the track cannot be transferred to P3S: it is not frozen, and it has a device Push 3 cannot run |

A MIDI track contains MIDI clips, which are stored in the ALS XML.

An audio track plays audio files, which are not contained in the ALS XML. The
audio clips are modeled by `LiveAudioClip`, and they say where the file is, how
big it is, and whether it is present in the project or is missing.

TODO Examine the XML and the report to ensure the following explanation is
correct and the report represents the facts:

The devices for track group are applied to the tracks in the group. group
devices are included with the devices of each group track: the chain of
the group processes the audio of the tracks in it. A report that names the
devices of a track names the group's devices too.

#### `LiveGroup`

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

#### `LiveDevice` — a device of a chain

Its name, its kind, its plug-in format, and whether P3S can run it. A device
on a frozen track is written in the ordinary way and carries no warning, because freezing a
track renders its devices away, so the serializer of a device is told whether the track is
frozen.

#### `LiveMidiClip` — one MIDI clip in the file

A clip belongs to a place. Every place — a slot of the session view, the arrangement, a take
lane — holds the whole clip, and the settings of it belong to it. There is no reference to
a clip in the format. See [als_notes.md](als_notes.md), "Every place holds its own clip".

A MIDI clip holds notes and plays no file. The clip of the audio side of a track is
`LiveAudioClip`, and it is a different thing: it holds a file.

| Attribute     | Description                                                       |
| ------------- | ----------------------------------------------------------------- |
| `name`        | the name of the clip                                              |
| `color`       | the number Live writes for the colour of the clip                 |
| `launch_mode` | how the clip is launched                                          |
| `warp_mode`   | how the clip's sample is warped, and whether it is warped at all  |
| `notes`       | the notes of the clip                                             |
| `place`       | where the clip is: `session view`, `arrangement`, `take lane 1.1` |

Two clips that carry the same name, file, colour and state are alike, and the report counts
them together. That grouping is the report's own, and it is done in the report.

#### `LiveAudioClip` — a clip of the audio side of a track

The file the clip plays, and the facts about that file: where it is, how big it is, and
whether it is in the project.

| Attribute       | Description                                                       |
| --------------- | ----------------------------------------------------------------- |
| `name`          | the name of the clip                                              |
| `file`          | the file the clip plays, relative to the project                  |
| `path`          | the path Live wrote for the file, which says which pack it is in  |
| `absolute_path` | where the file is, resolved against the directory of the set      |
| `file_size`     | the size of the file, as Live recorded it, and as it is on disk   |
| `color`         | the number Live writes for the colour of the clip                 |
| `marks`         | what is said about the clip: `⚠ missing`, and the state of it     |
| `launch_mode`   | how the clip is launched                                          |
| `warp_mode`     | how the clip's sample is warped, and whether it is warped at all  |
| `place`         | where the clip is: `session view`, `arrangement`, `take lane 1.1` |

#### `LiveAudioTrack` — the audio side of a track

The name and the colour of the track, and the clips of that audio. The line of the track
itself is written by the serializer of the track.

#### `LiveTakeLane` — a take lane of a track

Its name, and the clips of it. A lane holds the takes of a recording, and the track holds
the clips that are heard.

#### `LiveSample` — a file of the set

The file on disk, and the pack it is in. Several clips can point at the same file, and each
can play it differently — reversed, warped differently, trimmed — without touching the file.

| Attribute           | Description                                                                   |
| ------------------- | ----------------------------------------------------------------------------- |
| `path`              | the path Live wrote for the file, which says which pack it came from          |
| `relative_path`     | the path of the file relative to the project folder                           |
| `pack`, `pack_path` | the pack the file came from, and the path of it                               |
| `library`           | the library of Live the file came from: the user library, or the Core Library |
| `collected?`        | true when the file was copied into the project's `Samples/Imported/` folder   |

#### `LiveOrigin` — where a file comes from

The path Live wrote for a file says where the file was when the set was saved: in the
project, in the user library, in the Core Library of Live, or in a pack. The content of a
pack is under a folder of its own — `Samples`, `Sounds`, `IRs`, `Devices`, `Racks`,
`Presets` — and the pack is the folder above it. The libraries of Live are not packs.

See [als_notes.md](als_notes.md), "Where a file comes from".

#### `LivePack` — a pack the set refers to

The name of the pack, the path of the folder of it, and whether the pack is on this machine.

#### `LivePacks` — the packs of the set

The packs the set refers to, the ones that are on this machine, and the ones that are not. A
pack that is not installed is not a fault of the set: the set names the file, and the pack
holds it.

#### `MissingSamples`

The samples of the set that are not in the project, by the source they come from. It is the
part of the samples that is missing, so it is a view of that collection and not a collection
of its own.

#### `LiveAsset` — a file the set refers to

One `FileRef` of the set: the path as the set writes it, how the path was resolved, the
size Live recorded for it, the size on disk, where it is, and when it was last changed.

It also says whether the reference is of a sample — the `FileRef` of a `SampleRef` is — and
which pack or library the file came from.

#### `LiveSizes` — the sizes of the set

The four sizes: the set file, the expected size of the project, the actual size of the
project, and the fully resolved size. Each of them says what it was computed from, and a
size that could not be computed says so.

#### `LiveChecksums` — the checksums of the set

File hash, and the hash of the content the file holds when it is inflated.

#### `LiveProjectInfo` — the 'Ableton Project Info' folders around the set

The folders of that name in the directory of the set and in its parent directories, and what
is wrong with them. The folders are a fact about the machine the report is made on, and not
about the set, so the report says what it found and what it means: Live gets confused by a
folder of that name in a parent folder of the folder of the project. See
[als_notes.md](als_notes.md), "The 'Ableton Project Info' folder".

#### `HeaderBlock` — the facts about the set

The version of Live that wrote the set, the computer it is on, the times of the set and of
the project it is in, and the time zone the times are written in.
