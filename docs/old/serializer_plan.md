# TODO Implementation Plan for`lib/live_set/live_palette.rb`

This is the plan for preparing the next major version of `live_set`.

## Target Architecture

- Ableton Live sets are stored in ALS files, containing XML.
- This project has (or will have) a model class for every node type in the XML.
  - The ALS XML hierarchy of nodes will be mirrored by the hierarchy of Ruby classes
  defined in this project's `lib/live_set/model` directory.
  - Just as some ALS XML nodes have child collections, the Ruby model classes
    have mirror collections of child models (e.g. LiveMidiTrack contains an
  array of LiveMidiClip.)
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




## Ruby Coding Standards

See `$agent_instructions/ruby_standards.md`


## Testing

Standard operating procedure (SOP) is:

1. For each ALS version that we support (Live 8.4 to 12.x):

   1. Maintain one complete test of the best ALS file we know of that exercises
    each feature. At present we just extract an XML file from the largest Live
    12 demo and save it as test fixture data. Later we will find (or create)
    better test data, and an ALS file for every Live version we support.

      The fixture that is checked in is `spec/fixtures/live_12_suite_demo.xml.gz`:
      the XML of the largest Live 12 demo set, gzipped, because it is 27 MB of
      text. It is read by `LiveFixtures`, in `spec/support/live_fixtures.rb`,
      which gives the document, the text, the path of the file, and the directory
      of the set it is in.

      The set has eighteen tracks, 182 clips and 152 devices, and it has no group
      track: no Live 12 demo set has one. The behaviour of the groups is exercised
      by the reference sets, which are read from disk.

   2. Unit tests that fully exercise every leaf node of the serializer class
    tree. (Notify the user of any missing tests)

       1. Inflate test ALS models from the text fixture data

       2. We require unit tests that fully exercise each serializer.

       3. Compare results against literal strings. These strings should be reviewed by a human familiar with CSS.

The above is not intended to imply that no other tests are required. On the
contrary, SOP requires every class to be designed for testability and to have unit tests.

## TODOs

<!-- markdownlint-disable MD013 MD060 -->
| The TODO, in `live_palette.rb`                                                                                                                                              | What is to be done                                                     | Where it goes                    |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------|-------------------------------------|
| `LIGHT` — "TODO: delete this stupid idea"                                                                                                                                   | The constant is deleted, and the text on a dark background is white    | `LiveMarkup` writes it             |
| `ICONS` — "TODO Move to a new LiveTrackSerializer class" and "TODO rename to TRACK_TYPE_ICONS"                                                                              | The map of icons moves, and is renamed                                 | `LiveMarkup::TRACK_TYPE_ICONS`     |
| `icon_of` — "TODO: rename to icon_for"                                                                                                                                      | The method is renamed                                                  | `LiveMarkup.icon_for`              |
| `icon_of` — "TODO Move to LiveTrackSerializer class. a serializer object initialized with a model instance…"                                                                | The whole of the method moves, with the architecture of the long TODO  | `LiveMarkup`                       |
| `name_span` — "TODO: rename to colored_code"                                                                                                                                | The method is renamed                                                  | `LiveMarkup.colored_code`          |
| `name_span` — "TODO Move to LiveTrackSerializer class"                                                                                                                      | The method moves                                                       | `LiveMarkup`                       |
| `name_span` — "Tries and fails to select a background color based on a foreground color. TODO: add a new parameter for background_color so proper colors can be specified." | The method takes a background colour, and does not try to work one out | `LiveMarkup.colored_code`          |
| `code_span` — "TODO: Move to LiveTrackSerializer class"                                                                                                                     | The method moves                                                       | `LiveMarkup.code_span`             |
| `swatch` — "TODO Move to LiveTrackSerializer class"                                                                                                                         | The method moves                                                       | `LiveMarkup.swatch`                |
| `swatch` — "TODO add another parameter for background color instead of attempting to compute it"                                                                            | The method takes a background colour                                   | `LiveMarkup.swatch`                |
| `text_color` — "TODO: Delete this stupid idea"                                                                                                                              | The method is deleted                                                  | —                                   |
| `brightness` — "TODO: Delete this stupid idea"                                                                                                                              | The method is deleted                                                  | —                                   |
<!-- markdownlint-enable MD013 MD060 -->




## Colors

With `text_color`, `brightness` and `LIGHT` deleted, nothing in the palette works out the colour of the text on a
colour, and the caller says what the background colour is. The one thing the TODOs do not say is who chooses the colour
of the text.

Answer: The default color is the default markdown color. Look at the existing reports in
`$live_reference_sets/sets/live_12/reports` and use those colors for now. We will optimize them later.

The caller passes the foreground and background colours.  The serializer only writes what it is given:

```ruby
LiveMarkup.colored_code text, color_number: 21, background_color: '#18E9FE',
                                   foreground_color: '#000000'
LiveMarkup.swatch 21, background_color: '#18E9FE', foreground_color: '#000000'
```

## Hierarchical Numnbering System

In a hierarchical numbering system, `1.1.2a` represents a specific sub-item nested deep within a structured list or
document outline.

Here is how this specific number breaks down from the top level down to the most specific point:

• 1. — The first main section or chapter.
• 1.1. — The first subsection under main section 1.
• 1.1.2. — The second sub-subsection under subsection 1.1.
• 1.1.2a — The first individual clause, paragraph, or item (denoted by 'a') within sub-subsection 1.1.2.

### Visual Example

To see how this looks in a legal document, technical manual, or project outline:
• 1. Main Heading
 • 1.1 Subheading
  • 1.1.1 Sub-subheading
  • 1.1.2 Sub-subheading
   • 1.1.2a This is the exact item you are looking at.
   • 1.1.2b The next item at this same level.

### Usage in This Project

The hierarchical relationships between the ALS model classes and their corresponding serializer classes is reflected in
the markdown generated for the ALS report. Nested XML items stored in the ALS file are reported using a hierarchical
numbering system.

TODO: the following was taken from the `Fascination.md` reference report
($live_reference_sets/sets/live_11/reports/Fascination.md). Notice how it shows references, which we recently learned do
not exist for MIDI. Audio files live in separate files, so ALS XML elements can only point to the audio files. in that
sense audio samples are always references.

```text
ALS_Model
  Group track 1 👥 Group # Drums
  Group Track Device 1a Filter Max for Live ⚠ not usable on Push 3
  Group Track Device 1b DrumBuss Live
  Track 1.1 🎹 MIDI Kontakt 7
    Track Device 1.1a Kontakt 7 VST3 ⚠ not usable on Push 3
    Clip 1.1.1 (×5) Kontakt 7 1 ⚠ missing from project
      References (×5): launch: trigger, warp: none
    Take lane 1.1.1 3-Kontakt 7 1
      Clip 1.1.1.1 (×3) Kontakt 7 1 ⚠ missing from project
        References (×3): launch: trigger, warp: none
```

Notice how Track 1.1 appears beneath Group track 1; That means the track is a member of the group. The hierarchical
numbering (1.1) is consistent with the indentation.

## Serializer Classes

The classes in `lib/live_set/serializer/` are class outlines. The ones below are the classes to
write, and each additional serializer class is agreed with the user before it is written,
as the long TODO asks.

<!-- markdownlint-disable MD013 MD060 -->
| The class                           | It serializes                                                                        | Its model           |
|-------------------------------------|--------------------------------------------------------------------------------------|---------------------|
| `AlsModelSerializer`                | the whole model: the six sections of the report                                      | `AlsModel`          |
| `LiveHeaderSerializer`              | the facts about the set: the version of Live, the computer, the times, the time zone | the set             |
| `P3SCompatibility`                  | the verdict for a transfer to Push 3 Standalone                                      | the set             |
| `LiveGroupSerializer`               | a group: its line, its devices, the tracks in it                                     | `LiveGroup`         |
| `LiveGroupsSerializer`              | the groups of the set                                                                | `LiveGroups`        |
| `LiveMidiTrackSerializer`           | a MIDI track: its line, its devices, its clips, its take lanes                       | `LiveMidiTrack`     |
| `LiveMidiTracksSerializer`          | the MIDI tracks of the set, and of a group                                           | `LiveMidiTracks`    |
| `LiveAudioTrackSerializer`          | an audio track: its line, its devices, its clips, its take lanes                     | `LiveAudioTrack`    |
| `LiveAudioTracksSerializer`         | the audio tracks of the set, and of a group                                          | `LiveAudioTracks`   |
| `LiveReturnTrackSerializer`         | a return track: its line and its devices                                             | `LiveReturnTrack`   |
| `LiveReturnTracksSerializer`        | the return tracks of the set                                                          | `LiveReturnTracks`  |
| `LiveMasterTrackSerializer`         | the master track: its line and its devices                                            | `LiveMasterTrack`   |
| `LiveMasterTracksSerializer`        | the master tracks of the set                                                          | `LiveMasterTracks`  |
| `LiveDeviceSerializer`              | a device                                                                             | `LiveDevice`        |
| `LiveDevicesSerializer`             | the devices of a track, or of a group                                                | `LiveDevices`       |
| `LiveMidiClipSerializer`            | a MIDI clip: its line and its settings                                               | `LiveMidiClip`      |
| `LiveMidiClipGroups`                | the copies of a MIDI clip that are alike, written as one line                        | the MIDI clips      |
| `LiveTakeLanesSerializer`           | the take lanes of a track                                                            | `LiveTakeLanes`     |
| `LiveTakeLaneSerializer`            | a take lane                                                                          | `LiveTakeLane`      |
| `LiveClipsSerializer`               | the MIDI clips of the set                                                            | `LiveClips`         |
| `LiveSamplesSerializer`             | the samples of the set                                                               | `LiveSamples`       |
| `LiveAudioClipSerializer`           | a clip of the audio side of a track: its line, its file, its size and its place       | `LiveAudioClip`     |
| `LiveAudioClipsSerializer`          | the clips of the audio side of a track                                               | `LiveAudioClips`    |
| `LiveAudioTrackSerializer`          | the audio side of a track: the clips of that audio                                   | `LiveAudioTrack`    |
| `LiveMarkup`                        | the markup the report is written with: the colours, the escaping, the icons          | —                   |
| `MissingSamplesSerializer`          | the samples that are not in the project, by pack                                     | `MissingSamples`    |
| `DeviceCrossReferenceSerializer`    | the devices of the set, and the tracks they are on                                   | the set             |
| `TrackClipCrossReferenceSerializer` | the tracks and their clips, and the clips and their tracks                           | the set             |
| `LiveSizesSerializer`         | the four sizes of the set                                                            | `LiveSizes`         |
| `LiveChecksumsSerializer`     | the two checksums of the set                                                         | `LiveChecksums`     |
| `LiveAssetsSerializer`        | the files the set refers to                                                          | `LiveAssets`        |
<!-- markdownlint-enable MD013 MD060 -->

Every serializer is given the hierarchical number of the thing it writes, along with the
model.


## Serializer Responsibilities

The serializers have the following responsibilities:

1. **The numbering is generated by the serializer.** The XML has no notion of a
   track number, or a clip number, etc, so model classes do not contain any
   sequence information. The top-level serializer
   (lib/live_set/serializer/als_model_serializer.rb) iterates through its child
   serializers. Each child serializer is passed a hierachical number (e.g.  "1.2.3")
   and responsible for incrementing the counters for its children. Examples:

   a. The serializer for the first group track numbers its devices from the
   group track number: "1a", "1b".

   b. A clip serializer for track 1.2 would be passed "1.2.1" for the first clip
   of tha track, "1.2.2" for the second clip of that track, etc.

2. **Every serializer indents its own lines.** It is given the indentation to write with,
   and it passes its own indentation, two spaces more, to the serializers it calls.
3. **A track serializer writes the line of its track** — the number, the icon, the kind, the
   name on its colour, and the states — and then the devices, the clips and the take lanes
   under it.

A serializer is given what it cannot know by itself. A device serializer is given the
device and whether the track it is on is frozen: a device on a frozen track is written in
the ordinary way and carries no warning, because freezing a track renders its devices away,
and the device alone does not say so.

**The track serializer writes the name and the hierarchical number of a device; the device
serializer writes the device.** The report writes a device of a track as `Track Device
1.1a`, and a device of a group as `Group Track Device 1a`: the name depends on the kind of
the track, which only the track serializer knows, and the hierarchical number is the number
the track serializer gives it. The device serializer writes the device itself — its name on
the background of the thing Push 3 cannot use, the kind of device it is, and the warning.

The outline is written by AlsModelSerializer, which iterates through the groups and the
top-level tracks, and passes each of them along with a hierarchical base number to the
serializer.

## The models the serializers need

A model is a model of the XML contents. There is more than one model class, and there is
more than one kind of thing in a set: a track, a group, a clip, a device, a sample, a
scene. Each class models the part of the XML it is about.

The XML has an element for each kind of track, and the model has a class for each of them:
a `<MidiTrack>` is a `LiveMidiTrack`, an `<AudioTrack>` is a `LiveAudioTrack`, a
`<ReturnTrack>` is a `LiveReturnTrack`, and the `<MasterTrack>` (the `<MainTrack>` in Live
12) is a `LiveMasterTrack`. There is no class for "a track", because there is no element
for one.

The models are not serializers. They represent the XML entity, and the serializers write
them.

| The model | It holds | It comes from |
| --- | --- | --- |
| `LiveMidiTrack` | the name, the colour, the devices, the MIDI clips, the take lanes and the state of a MIDI track | `LiveTrack`, and the track handling in `LiveSetReport` |
| `LiveAudioTrack` | the name, the colour, the devices, the MIDI clips, the audio clips, the take lanes and the state of an audio track | `LiveTrack`, and the track handling in `LiveSetReport` |
| `LiveReturnTrack` | the name, the colour, the devices and the state of a return track | `LiveTrack`, and the track handling in `LiveSetReport` |
| `LiveMasterTrack` | the name, the colour, the devices and the state of the master track | `LiveTrack`, and the track handling in `LiveSetReport` |
| `LiveGroup` | a model of the track group in the XML: the group, its devices, and the tracks in it | the class that exists |
| `LiveDevice` | a device of a chain: its name, its kind, its plug-in format, and whether Push 3 Standalone can run it | `LiveDevice`, the class that exists |
| `LiveMidiClip` | one MIDI clip in the file: its name, its colour, its launch mode, its warp mode, its notes, and the place it is in | the clip handling in `LiveSetReport` |
| `LiveAudioClip` | a clip of the audio side of a track: its name, its colour, its file, its size, whether the file is collected, its launch mode, its warp mode, and the place it is in | `LiveAudioClip`, the class that exists |
| `LiveAsset` | one file the set refers to: the path as the set writes it, how the path was resolved, the size Live recorded, the size on disk, where it is, and when it was last changed | the `FileRef` elements of the set |
| `LiveSizes` | the four sizes of the set: the set file, the expected size of the project, the actual size of the project, and the fully resolved size | the sizes of the files of the set |
| `LiveChecksums` | the hash of the file, and the hash of the content the file holds | the set |
| `LiveTakeLane` | a take lane of a track: its name, and the clips of it | `take_lanes_of` in `LiveSetReport` |
| `LiveSample` | a sample of the set, its file, and the pack it is in | the sample handling in `LiveSetReport` |
| `MissingSamples` | the samples that are not in the project, by pack | `missing_samples_markdown` in `LiveSetReport` |
| `HeaderBlock` | the facts about the set | `metadata_markdown` in `LiveSetReport` |

Every collection of a model is a class of its own, named for the things it holds, and each
of them has a serializer of its own:

| The collection | It holds | Its serializer |
| --- | --- | --- |
| `LiveTracks` | the `<Tracks>` element of the set: the MIDI tracks, the audio tracks, the return tracks and the groups | `LiveTracksSerializer` |
| `LiveMidiTracks` | the MIDI tracks of the set, and the MIDI tracks of a group | `LiveMidiTracksSerializer` |
| `LiveAudioTracks` | the audio tracks of the set, and the audio tracks of a group | `LiveAudioTracksSerializer` |
| `LiveReturnTracks` | the return tracks of the set | `LiveReturnTracksSerializer` |
| `LiveMasterTracks` | the master track of the set | `LiveMasterTracksSerializer` |
| `LiveGroups` | the groups of the set | `LiveGroupsSerializer` |
| `LiveDevices` | the devices of a track, or of a group | `LiveDevicesSerializer` |
| `LiveTakeLanes` | the take lanes of a track | `LiveTakeLanesSerializer` |
| `LiveClips` | the MIDI clips of the set, and the MIDI clips of a track | `LiveClipsSerializer` |
| `LiveSamples` | the samples of the set | `LiveSamplesSerializer` |
| `LiveAudioClips` | the clips of the audio side of a track | `LiveAudioClipsSerializer` |
| `LiveAssets` | the files the set refers to | `LiveAssetsSerializer` |

`MissingSamples` is the part of `LiveSamples` that is not in the project, so it is a view of
the collection and not a collection of its own.

### `LiveTracks` and the order of the tracks

`LiveTracks` is the model of the `<Tracks>` element of the XML, and it deviates from the
usual pattern in that it has two kinds of child: `LiveMidiTracks` and `LiveAudioTracks`.
It also holds the ids of the tracks of the set, in the order Live wrote them.

The list of ids is what lets the tracks be written in the order they are found in the ALS
XML: the MIDI tracks and the audio tracks are two collections, and the order of the tracks
of the set is the order of the elements in the file, not the order of the collections.

By default, every track of the set is written in the order it was saved in. The
`--show_midi_and_audio_tracks_separately` option writes the audio tracks and the MIDI
tracks in their own lists instead, and the return tracks and the master track have lists of
their own either way.

The hierarchy of the model is mirrored by the hierarchy of the markdown, and the
indentation of the report and the numbers of the report agree: a track numbered `1.1` is a
member of the group numbered `1`.

```text
LiveTracks#to_markdown                    the tracks of the set, in the order Live wrote them
├── LiveMidiTracks#to_markdown            the MIDI tracks
│   └── LiveMidiTrack#to_markdown         a MIDI track
│       └── LiveMidiTrackSerializer#to_markdown
├── LiveAudioTracks#to_markdown           the audio tracks
│   └── LiveAudioTrack#to_markdown        an audio track
│       └── LiveAudioTrackSerializer#to_markdown
└── LiveGroupSerializer#to_markdown       a group
    └── LiveMidiTracks#to_markdown        the MIDI tracks of the group
        └── LiveMidiTrack#to_markdown     a MIDI track of the group
            └── LiveMidiTrackSerializer#to_markdown
```

Each link in the chain delegates to the next: a collection writes its members by asking
each of them for its markdown, and a track asks the serializer of a track for its markdown.
The serializer is the only thing that writes the markup.

### There is no clip reference in the format

A clip belongs to a place. The Session View and the Arrangement View "each hold individual
collections of clips" (Live Concepts), and a Session clip copied into the Arrangement is an
independent Arrangement clip.

The file agrees. One clip of the Live 11 reference set, `3-Kontakt 7 1`, is written out as
nine complete `MidiClip` elements, eight of them with the same forty-seven note events and
one with nineteen; an audio clip, `Pink Noise - EDMtips.com`, is written out eleven times,
each with its own `Id` and its own `SampleRef`. `LomId` is `0` throughout and ties nothing
together.

What is referenced rather than copied is the sample: the audio of a set is in files beside
it, and each clip holds the pointer to the file in its `<SampleRef>`. Several clips can
point at the same file, and each can play it differently — reversed, warped differently,
trimmed — without touching the file. The notes of a MIDI clip are in the element, so they
are copied with it.

`LomId` is the identifier the Live Object Model uses while Live is running; it is `0` in
the elements of a saved set, and it is not a key that ties the copies of a clip together.

So a clip is one clip in the file, with its own settings and its own place, and there is
no clip reference: the launch mode and the warp mode belong to the clip element they
are written in. A MIDI clip is `LiveMidiClip`, and it holds notes; the clip of the audio
side of a track is `LiveAudioClip`, and it holds a file, its size, and whether the file is
collected.

The grouping of the copies that are the same clip — the report's `Clip 1.1 (×7)` — is the
report's own, and belongs to the report and not to the model.

`LiveSetReport` names these classes in its own TODO, at the top of the file, and its
organisation comment shows where each one goes in the report:

```text
Header block
Push 3 Standalone compatibility
LiveGroup
  LiveTrack & devices
    TakeLanes & ClipReferences
    ClipReferences & devices
Missing samples
Device / track cross reference
Track / clip cross reference
```

`docs/report_design.md` describes the same design in more detail, and the two documents
should agree.

## What the models do not yet know

This project has several executables, and every one of them is named with the `als_`
prefix, and the class that implements a command is named after the command:
`als_report` writes the report of a set, `als_delta` diffs two sets, `als_to_xsd`
writes a schema of the format, `als_validate` checks a set against a schema,
`als_to_version` converts a set to another version of the format, and `als_nodes`,
`als_diff` and `als_xsd_order` are the tools for looking inside a set. Every command
extends the `Command` module, in `lib/common/command.rb`, which holds the parsing of the
options and the handling of the errors of the parser. See `docs/index.md`, "The commands".

**The converter needs a complete model of the XML.** A set cannot be converted from Live 12
to Live 11 by a model that has not read what Live 12 wrote: whatever the model does not
parse is whatever the conversion loses. So the model of the XML, taken as a whole, has to
be complete for that work, and "the model" means that, not any one class.

**That is not what the reporting task needs.** A report needs the tracks, the groups, the
clips, the references, the take lanes, the devices, the samples and the states of a set,
and nothing else. The present work is the report, and the models are written for it.

**Where the reporting models do not parse something, the code says so.** The note is left
where the parsing would have been:

```ruby
# not implemented: parsing of elements AutomationEnvelopes and MidiClip, and attributes
# Clip.Type and Track.TrackGroupId
```

Every such note is a statement of what the model does not know, and the notes together are
the work list of the converter. They are written as the models are written, and they are
the first thing the converter asks for.

The parts of a set that the report does not read today, and that the notes will name as
they are written:

- the automation envelopes of a track, and the parameters of its devices
- the mixer of a track: its volume, its pan, and its sends
- the scenes of a set, and the scene grid
- the markers of the arrangement, and the warp markers of a sample
- the templates, the user presets, and the Racks of a set
- the parts of the XML that hold the state of the Live window itself, rather than of the
  set: the selected track, the unfolded state of the browser, the zoom of the arrangement

## The icon of Live 12's master track

Live 12 writes a `MainTrack`, the report calls its kind `Main`, and `ICONS` has no `Main`,
so `icon_of` logs a warning and writes the bomb. Live 11's `MasterTrack` is in the map and
gets the fader.

`Main` is given the fader, the icon of the master track. The kind of the track is what Live
calls it — `Master` in Live 11, `Main` in Live 12 — so the report says what Live says, and
the icon says what the thing is. The map is written in step 2, with the rest of the
formatting.

## The unit tests for the serializers

Every serializer gets a spec, and the expected values in the specs are the markdown the
program writes today.

**The expected values are the output as it is.** The report of every set of the reference
sets is generated as the work goes, and the lines of those reports are copied into the
specs, whole and literal. A spec is not a pattern and not a fragment: the line the
serializer is to write is there in full, in a heredoc, so that it can be read.

**The styles are in the expected values.** A coloured name carries its CSS inline, so the
expected markdown carries it too. The colours of a name, the tooltip that holds the number
Live writes for the colour, and the alignment of the chip are all visible in the spec.

**Why they are written this way.** The specs are how the markdown is to be looked at. The
expected value in a spec is the markdown, so a change to the markdown is a change to the
spec, and the diff of the spec is the change to the report. The specs are where the
markdown is tuned.

**One spec per serializer**, in `spec/live_set/serializer/`:

| The spec | It asserts |
| --- | --- |
| `als_model_serializer_spec.rb` | the whole report |
| `live_header_serializer_spec.rb` | the facts about the set |
| `p3s_compatibility_spec.rb` | the verdict, and the errors and the advice that go with it |
| `live_group_serializer_spec.rb` | the line of a group, its devices, and the tracks in it |
| `live_groups_serializer_spec.rb` | the groups of the set |
| `live_track_serializer_spec.rb` | the line of a track, and its devices, its clips and its take lanes under it |
| `live_tracks_serializer_spec.rb` | the tracks of a group, under the group |
| `live_device_serializer_spec.rb` | the line of a device, and the two ways a device is written: one that Push 3 can run, and one that it cannot |
| `live_devices_serializer_spec.rb` | the devices of a track, under the track |
| `live_clip_serializer_spec.rb` | the line of a clip, and the settings of it |
| `live_take_lane_serializer_spec.rb` | the line of a take lane, and its clips under it |
| `live_take_lanes_serializer_spec.rb` | the lanes of a track, under the track |
| `live_clips_serializer_spec.rb` | the clips of the set |
| `live_samples_serializer_spec.rb` | the samples of the set |
| `missing_samples_serializer_spec.rb` | the samples that are not in the project, by pack |
| `device_cross_reference_serializer_spec.rb` | the devices of the set, and the tracks they are on |
| `track_clip_cross_reference_serializer_spec.rb` | the tracks and their clips, and the clips and their tracks |

The audio clips have no spec, because no serializer writes them: nothing in the report
writes the clips of the audio side of a track, and the clips of the report are the clip
references.

**The models in the specs come from a real set.** The specs build their models from sets of
the reference sets — the Live 11 demo set, the Live 12 one, and the factory default set —
so that the expected values are the values of a real set and not of a hand-made one. The
specs use the same code the report uses to build the models; nothing is mocked.

The spec of a serializer is written with its model, in step 3 and step 4: the model of
`LiveClipReference`, `LiveTakeLane`, `LiveTakeLanes`, `LiveGroupTrack` and `LiveTrack` is
written before the serializer that writes it.

**The report as a whole has a spec of its own.** One spec asserts that the report of a set
is the report that is checked in, so that a change to any part of it cannot slip through
the specs of the parts. The checked-in reports are the ones `dev/generate_reference_als_reports`
writes, and the spec reads them from the repository of the reference sets.

**The fixture.** The model of a set is inflated from the XML of a real set, and the XML of
the largest Live 12 demo is the fixture: it is saved under `spec/fixtures/`, gzipped,
because it is 3.9 MB compressed and tens of megabytes of XML when it is inflated. A spec
inflates the model from the fixture, so the specs need neither Live nor the reference sets
installed, and the expected values are the values of a real set and not of a hand-made one.

**The specs are written before the serializers are finished.** Each serializer is written to
its spec, and the markdown in the tests is reviewed for quality. The class outlines
already say "TODO Write unit tests", and that is where the tests go.

**The specs of the work that is not done yet fail, and that is what they are for.** The
spec of `AlsModel` pins the four values the model of a file holds, and the specs of the
serializers pin the markdown they are to write. They fail until the model and the
serializers are written, in steps 3 and 4: they are the specification of the work, not a
regression. The specs of the code that exists — the spec of the report — pass, and rubocop
is run after the specs that are to pass have passed.

## The work in the serializer outlines

The classes in `lib/live_set/serializer/` are outlines. Seven of them have a class, a
constructor, a `to_markdown` that returns nothing, and a comment with the sample usage of
the serializer and the TODO "Write unit tests". Two of them have example code in
`to_markdown` — the delegation to the serializers of the things they hold — and
`LiveTakeLanesSerializer` has one line of it. Each of them is implemented completely in
step 4, with the model it serializes and a spec of its own; none of them is left as an
outline.

The example code shows how the serializers are to be used, and it has these faults, which
are fixed as it is implemented:

- `LiveTrackSerializer#to_markdown` refers to `group_track_devices_markdown`, which does not
  exist there, and it iterates `@track.clip_references` to write the devices of the track.
- `LiveGroupTrackSerializer#to_markdown` has no header line, and the TODO says what it
  should be: `Group track 1 👥 Group # Drums`.
- `AlsModelSerializer#to_markdown` writes the hierarchy by calling `to_markdown` on a model —
  `LiveGroupTrack.new(@als_model)` — which is the one thing the architecture says never
  happens. The top-level serializer iterates the groups and the top-level tracks, and each
  of them, with its base number, is written by the serializer that writes it:

  ```ruby
  groups = @als_model.groups.map { |group, index| LiveGroupTrackSerializer.new(group, index + 1).to_markdown }
  tracks = @als_model.tracks.map { |track, index| LiveTrackSerializer.new(track, index + 1).to_markdown }
  ```

- `LiveTakeLanesSerializer#to_markdown` calls `to_markdown` on the model objects it holds —
  `@take_lanes.map(&:to_markdown)` — which is the same fault; it delegates each lane to
  `LiveTakeLaneSerializer`.
- The model of `LiveGroupTrackSerializer` is named `LiveGroupTrack` in that file. The model
  is `LiveGroup`, which is reworked in step 3 to expose the tracks of the group, and the
  serializer is given the group and the number to write it under.

## The text that changes with this work

- **The legend the report writes** — the `LEGEND` constant of
  `lib/live_set/live_set_report.rb` — says that every place a clip is in "holds a reference
  to it", and that the settings of a reference belong to the reference and not to the clip.
  There is no reference in the format: each place holds its own clip, and the settings
  belong to the clip element they are written in. The legend says that instead, and the
  reports of the reference sets are regenerated, so the new wording is in them. The item is
  **N57** in `TODO.md`.
- **The lines under a clip** read `References (×5): launch: trigger, warp: none`. They are the
  copies of the clip and the settings they differ in, so they are not references. The word
  changes, and the count of the copies stays.
- **The example in "Hierarchical Numnbering System"** shows those lines, and is written in
  the new wording. The tooltip of a name keeps the wording the palette writes now,
  `Live color 1`.
- **The reports of the reference sets** are regenerated, so the legend and the tables of the
  reports change with it.

## The questions that are still open

Two of them are in the standing list, and each is a question rather than a piece of work:

- **N58** — should each asset of a set carry a hash of its own? The assets table carries the
  size of each file, and a hash would notice a file that has changed and kept its size.
- **N59** — should the report carry a checksum of the tool that made it? The report says the
  version of `live_set` and where the tool is documented; a checksum would say which code
  produced the report.

Both are in `TODO.md`.

## The identity of a MIDI clip

A MIDI clip has no file, so its identity is its content. The name of a clip is never part of
it: two clips that hold the same notes under different names are the same material.

There are three definitions of "the same", and the report can be asked for any of them:

| The definition | Two MIDI clips are the same when |
| --- | --- |
| `notes` | they hold the same note events: pitch, time, duration, velocity, probability, and whether the note is enabled. The note ids are left out, since they are ids. |
| `keys` | they hold the same note events and the same key tracks |
| `loop` | they hold the same note events, the same key tracks, and the same loop markers |

The choice is an option of the program:

```shell
als_report -s path/to/my_set.als -i notes
```

and the default is `notes`.

**What it changes in the report.** The grouping of the clips of a track is by
identity, so the clips that are alike are presented as one line with a count. In
the Live 11 reference set the nine copies of `3-Kontakt 7 1` are one line today,
because the key is the name, the colour and the marks — and eight of them hold
forty-seven notes while one holds nineteen.  Under `notes` they are two lines.

**And a section that crosses the tracks of the set.** A new section, `## Identical MIDI
Clips`, lists every group of MIDI clips of the set that hold the same notes, and where each
of them is: the track, and the place in the track. It is the one place where the material
of a set is compared across the set rather than within a track.

The identity of an audio clip does not change: it is its file, with its colour and its
marks.

## The sizes and the checksum of a set

The report is evidence. It has to say how big a set is, and it has to show that the set has
not been tampered with, so that the opinions drawn from it survive cross-examination.

### The checksum

The report carries two checksums of the set, both SHA-256:

- **the hash of the file**, of the `.als` as it is on disk. It changes when anything changes
  in the file, including the compression.
- **the hash of the content**, of the XML the `.als` holds when it is inflated. A set is a
  gzip file, and two files with the same content need not have the same bytes: a set that was
  recompressed has the same content and a different file. XML hash says the
  material did not change; the hash of the file says the file did not change.

Both are of the set that was read, and the report says which is which.

### The sizes

Four sizes, and the report says what each one was computed from, and what could not be
computed:

| The size | What it is | How it is computed | What it needs |
| --- | --- | --- | --- |
| The set file | the size of the `.als` | the file on disk | the set |
| Expected Project Size | what the project should be, according to the `.als`: the set file, and every sample the set refers to that is in the project, counted once | the sizes Live recorded in `OriginalFileSize`, and the size on disk where Live recorded zero | the set |
| Actual Project Size | what the project is, on disk | the files in the project folder | the project folder |
| Fully Resolved Size | everything the set draws on: the project, and the assets outside it — the samples in the user library, the Live Packs, the Racks, the Live Clips | the expected size, with the assets outside the project added | the set, and the files outside the project |

A sample that is not on disk has no size on disk, and the report says so rather than
guessing at one. A project folder that is not there has no actual size, and the report says
that instead of the expected one.

### The assets

Every external asset of a set is named by a `FileRef` — the same element a sample is
referenced by, whether the asset is a sample or a device preset. The Live 11 reference set
has 124 of them, and the paths they name take four shapes:

| The path | What it is |
| --- | --- |
| relative to the set | an asset in the project folder |
| absolute | an asset in the user library, or in the Core Library of the Live installation |
| relative, with `..` in it | an asset outside the project folder, in the folder the set was made in |
| a folder | a folder rather than a file, and not an asset at all |

A table of the assets says what the sizes are made of: each one, the path as it is written,
how the path was resolved, the size Live recorded for it, the size on disk, where it is — in
the project, in the user library, in the Core Library, or missing — and when it was last
changed. The reader can add the columns up.

So the fully resolved size is computed over every `FileRef` of the set: the path is
resolved, the size on disk is taken, and what is not there is reported as not there.

### The tool

The report says what made it: the version of `live_set`, and where the tool is documented —
<https://www.mslinn.com/av_studio/ableton_live_set.html> — so that a report can be traced to
the program that wrote it.

## The steps

Each step leaves the program working, and the reports unchanged.

1. **The model classes move into `lib/live_set/model/`.** The move is mechanical and changes
   no behaviour, so the nine specs of the models and the 23 checked-in reports are its
   proof; it needs no tests of its own. It comes first, because everything after it then
   happens in the layout the project ends up with.

   | From | To | Class |
   | --- | --- | --- |
   | `lib/live_set/live_device.rb` | `lib/live_set/model/live_device.rb` | `LiveDevice` |
   | `lib/live_set/live_set_audio_clip.rb` | `lib/live_set/model/live_audio_clip.rb` | `LiveAudioClip` |
   | `lib/live_set/live_set_group.rb` | `lib/live_set/model/live_group.rb` | `LiveGroup` |
   | `lib/live_set/live_set_scene.rb` | `lib/live_set/model/live_scene.rb` | `LiveScene` |
   | `lib/live_set/live_set_track.rb` | `lib/live_set/model/live_track.rb` | `LiveTrack`, which the steps of the work later split into `LiveMidiTrack`, `LiveAudioTrack`, `LiveReturnTrack` and `LiveMasterTrack` |
   | `lib/live_set/live_tracks.rb` | `lib/live_set/model/live_tracks.rb` | `LiveTracks` |

   and their nine specs move with them into `spec/live_set/model/`, renamed the same way:
   `spec/live_set/live_set_track_audio_clips_spec.rb` becomes
   `spec/live_set/model/live_track_audio_clips_spec.rb`, and so on.

   Three things the move breaks, and what is done about each:

   a. **The new directories are loaded.** `require_directory` globs `dir/*.rb`
      and does not recurse (`lib/common/util.rb:37`), so `lib/live_set.rb`
      requires `live_set/model`, `live_set/serializer` and `live_set/tx` as well
      as `live_set` itself. What is left is that each file in them requires what
      it uses: the model files use `LiveDevice`, `LiveTrack` and `LiveGroup`
      without requiring them today (`live_set_track.rb:34`,
      `live_set_group.rb:41`, `live_tracks.rb:4`), and the specs require the
   files one at a time (`require 'live_set/live_set_track'`), so the files have
      to stand on their own.  b. **`lib/common/xml.rb:102` reaches
      `LiveDevice::CONTAINER_ELEMENTS`** — a dependency of `lib/common` on a
      model class, and `lib/common` is loaded before the model. It works today
      only because the constant is looked up when the method is called. The
      device-chain walk moves into the model layer: `xml_chain_devices`
   (`lib/common/xml.rb:99`) and the container-element filter become part of the
      model of a track, and `lib/common/xml.rb` keeps the XML helpers that are
      not about devices.  c. **The load order.** Today the files lean on
      alphabetical order: `live_device.rb` sorts before `live_set_track.rb`, and
      `live_tracks.rb` after both. The explicit requires of (a) make the order
      irrelevant.

   Two small things the move touches: the `require` lines of the seven specs
   that name the moved files, and the `CustomTransform` map in `.rubocop.yml:99`
   that names the old file names (the cop is disabled, but the map should not be
   stale).

   What the move does not do: it does not move `verdict_markdown` out of
   `LiveTracks` — that belongs to `P3SCompatibility`, and it is the business of
   the serializer step; and it does not retire `LiveSetReport`, which is the
   business of the last step.  `Rakefile:21` (`load 'live_set/version.rb'`,
   which is at `lib/live_set/version.rb`) is a pre-existing bug and is not
   touched by this.

2. **The formatting moves from the palette to `LiveMarkup`.**
   `LivePalette` keeps `COLORS` and `color_of`, and loses `LIGHT`, `ICONS`,
   `icon_of`, `name_span`, `code_span`, `text_color` and `brightness`. The
   markup written is the markup written today, so the report does not change.
   The log is required by the serializer. A spec for the serializer.
3. **The models are written**, one at a time, each with a spec: `LiveMidiClip` and
   `LiveClipSettings` first, because the clip lines carry the most detail, then
   `LiveTakeLane` and `LiveTakeLanes`, then `LiveMidiClip`, then the tracks and
   `LiveGroup`. Each model leaves a note where it does not parse something, as
   above.
4. **The serializers are written**, one at a time, each with a spec, and the
   report calls each one in place of the method it replaces. The report shrinks
   as they arrive. Each new serializer class is agreed with the user before it
   is written. The spec of a serializer is written before the serializer is
   finished, and the expected values in it are the markdown as it is at that
   moment.
5. **The report is left as a writer.** What is left of `LiveSetReport` is the
   header block and the four tables, and the header block becomes `HeaderBlock`
   when the models are in place. This phase is not complete until the user is
   able to run reports and is happy with the displayed reports, with the
   understanding that MIDI clips may not be properly represented yet in the
   report.

   **What the phase turned out to be.** Every one of the TODOs in
   `live_set_report.rb` is done: the header block is `HeaderBlock`, the verdict
   is `P3SCompatibility`, the clips are `LiveMidiClip` and `LiveAudioClip`, the
   devices are `LiveDevice` and `LiveDevices`, the samples are `LiveSample` and
   `MissingSamples`, and the tree of the tracks is `LiveTracks` and `LiveGroup`.
   What was left of `LiveSetReport` was a second writer of the report: it read
   the XML, built the model by hand, and wrote the same six sections that
   `AlsModelSerializer` writes from the model. Two writers of one document is
   one too many, so `LiveSetReport` is retired, and the report is the model of
   the set written as markdown by the serializer of the model:

   ```text
   AlsReport#show
     └── AlsModelSerializer#to_markdown      the title and the six sections
         ├── LiveHeaderSerializer#to_markdown        the header block
         ├── P3SCompatibility#to_markdown           the verdict
         ├── AlsModelSerializer#hierarchy_markdown   the outline of the tracks
         ├── MissingSamplesSerializer#to_markdown    the samples that are not in the project
         ├── LiveSamplesSerializer#to_markdown       the samples of the set
         ├── DeviceCrossReferenceSerializer#to_markdown
         └── TrackClipCrossReferenceSerializer#to_markdown
   ```

   The reports of the reference sets do not change.
6. **The identity of a MIDI clip is its content.** The model computes the
   identity of a MIDI clip under the definition that is asked for — `notes`,
   `keys` or `loop` — and the name is never part of it. The option is parsed by
   `live_set_options.rb` and is passed to the model. The grouping of the clips
   of a track is by identity, and a new section, `## Identical MIDI Clips`, with
   a serializer of its own, crosses the tracks of the set.
7. **The sizes and the checksum of the set.** The model computes the four sizes
   and the two checksums, and the report carries them: the size of the set file,
   the expected size of the project, the actual size of the project when the
   project folder is there, and the fully resolved size; the hash of the file
   and the hash of the content. A table of the assets says what the sizes are
   made of. The header block says what made the report and where the tool is
   documented.

   **What the phase turned out to be.** Four classes of the model and three
   serializers, and three sections of the report:

   | The model | It holds | Its serializer |
   | --- | --- | --- |
   | `LiveAsset` | one file the set refers to: the path as the set writes it, how the path was resolved, the size Live recorded, the size on disk, and when it was last changed | `LiveAssetsSerializer` |
   | `LiveAssets` | every file the set refers to, each file once | `LiveAssetsSerializer` |
   | `LiveSizes` | the four sizes of the set | `LiveSizesSerializer` |
   | `LiveChecksums` | the hash of the file, and the hash of the content | `LiveChecksumsSerializer` |

   The sections are `## Set Sizes` and `## Set Checksums`,
   after the header block, and `## Set Assets` at the end of the
   report.

   A size that could not be computed says so: a project folder that is not there
   has no actual size, and the report says that instead of the expected one. An
   asset that is not on disk has no size on disk, and the report says that
   rather than guessing at one.

## The evidence that nothing has broken

- The 23 reports under `sets/*/reports/` of the reference sets are regenerated
  after every step, and diffed. The report must not change, except for what is
  asked for.
- The spec of the report as a whole compares the report of a set with the report
  that is checked in.
- The specs of the serializers hold the expected markdown, whole and literal, so
  a change to the markdown shows up in the diff of the spec that expects it.
- The specs of the report (`spec/live_set/live_set_show_spec.rb`) are the other check.
- `bundle exec rubocop` is clean after every step, and the specs pass before it
  is run.

## The other TODOs in the code

These are not in `live_palette.rb`, and are not part of this plan, but they are
the same work and are listed here so that they are not lost. Every one of them
is done, and the file they were in is gone:

| Where | The TODO | What it became |
| --- | --- | --- |
| `live_set_report.rb:17` | create the classes: `HeaderBlock`, `P3SCompatible`, `LiveClip`, `LiveClipReference`, `LiveClipSettings`, `LiveDevice`, `LiveSample`, `MissingSamples` | `HeaderBlock`, `P3SCompatibility`, `LiveMidiClip`, `LiveAudioClip`, `LiveClipSettings`, `LiveDevice`, `LiveSample`, `MissingSamples` |
| `live_set_report.rb:708` | `states_of` should take a `LiveTrack` instead of an XML element, and move to the `LiveTrack` class | `LiveMarkup.states_of`, which takes a track of any kind |
| `live_set_report.rb:714` | `frozen?` is a built-in method of `Object` in Ruby; the method should be part of the `LiveTrack` class | `LiveTrackFacts#frozen?` |
| `live_set_report.rb:716-719` | `frozen?`, `soloed?`, `armed?` and `off?` should be methods of the track | `LiveTrackFacts` |
| `live_set_report.rb:801` | `missing_samples_markdown` should move to a `MissingSamples` class | `MissingSamplesSerializer` |
| `live_set_report.rb:838`, `:862` | the device methods should move to a `LiveDevices` class, and be renamed to `markdown` | `LiveDevices`, `LiveDeviceCrossReference` and `DeviceCrossReferenceSerializer` |
| `live_set_report.rb:1095` | `track_tree` should move to a `LiveTracks` class, and be renamed to `tree`; `LiveTracks` would be a collection of `LiveTrack` objects, and `LiveTrack` a wrapper around a track element | `LiveTracks`, the model of the `<Tracks>` element, holding `LiveMidiTracks` and `LiveAudioTracks` |
| `live_set_report.rb:1113` | `build_track_tree` should move to a `LiveGroup` class, and be renamed | `LiveGroup` |
| `live_set_report.rb:1356` | `mark` should be renamed to `checkmark` | `LiveMarkup.swatch` |
