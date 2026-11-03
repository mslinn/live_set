# TODO Implementation Plan for`lib/live_set/live_palette.rb`

This is the plan for addressing the TODO comments in
`lib/live_set/live_palette.rb`, and for the serializer classes in
`lib/live_set/serializer/` that are to take the work over from it, and for the
model classes that should be moved into `lib/live_set/model/`.


## The architecture the TODOs describe

The long TODO in `live_palette.rb` states the rules, and the plan obeys them:

- Serializers are objects, initialized with a model instance.
- An outline of class AlsModel was created in lib/live_set/model/als_model.rb
  that holds everything stored in an ALS file. We can call this "the ALS model."
- The ALS model represents the entire XML entity stored in an ALS file. A
  separate serializer class is responsible for generating a markdown
  representation, and includes methods for escaping characters and namespace
  support.
- The serializers mirror the model hierarchy; each model class has a small associated
  serializer class.
- Where several serializers have common behaviour, that behaviour shall be
  extracted into a helper of some sort.
- Test data for serializers requires matching model class instances. For
  efficiency, extract an XML file from the largest Live 12 demo and save it as
  test fixture data. Inflate a test ALS model from the text fixture data, then
  write unit tests the fully exercise each serializer and compare results against
  literal strings.


## TODOs

<!-- markdownlint-disable MD013 MD060 -->
| The TODO, in `live_palette.rb`                                                                                                                                              | What is to be done                                                     | Where it goes                           |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------|-----------------------------------------|
| `LIGHT` — "TODO: delete this stupid idea"                                                                                                                                   | The constant is deleted, and the text on a dark background is white    | `LiveTrackSerializer` writes it         |
| `ICONS` — "TODO Move to a new LiveTrackSerializer class" and "TODO rename to TRACK_TYPE_ICONS"                                                                              | The map of icons moves, and is renamed                                 | `LiveTrackSerializer::TRACK_TYPE_ICONS` |
| `icon_of` — "TODO: rename to icon_for"                                                                                                                                      | The method is renamed                                                  | `LiveTrackSerializer.icon_for`          |
| `icon_of` — "TODO Move to LiveTrackSerializer class. a serializer object initialized with a model instance…"                                                                | The whole of the method moves, with the architecture of the long TODO  | `LiveTrackSerializer`                   |
| `name_span` — "TODO: rename to colored_code"                                                                                                                                | The method is renamed                                                  | `LiveTrackSerializer.colored_code`      |
| `name_span` — "TODO Move to LiveTrackSerializer class"                                                                                                                      | The method moves                                                       | `LiveTrackSerializer`                   |
| `name_span` — "Tries and fails to select a background color based on a foreground color. TODO: add a new parameter for background_color so proper colors can be specified." | The method takes a background colour, and does not try to work one out | `LiveTrackSerializer.colored_code`      |
| `code_span` — "TODO: Move to LiveTrackSerializer class"                                                                                                                     | The method moves                                                       | `LiveTrackSerializer.code_span`         |
| `swatch` — "TODO Move to LiveTrackSerializer class"                                                                                                                         | The method moves                                                       | `LiveTrackSerializer.swatch`            |
| `swatch` — "TODO add another parameter for background color instead of attempting to compute it"                                                                            | The method takes a background colour                                   | `LiveTrackSerializer.swatch`            |
| `text_color` — "TODO: Delete this stupid idea"                                                                                                                              | The method is deleted                                                  | —                                       |
| `brightness` — "TODO: Delete this stupid idea"                                                                                                                              | The method is deleted                                                  | —                                       |
<!-- markdownlint-enable MD013 MD060 -->




## Colors

With `text_color`, `brightness` and `LIGHT` deleted, nothing in the palette works out the
colour of the text on a colour, and the caller says what the background colour is. The one
thing the TODOs do not say is who chooses the colour of the text.

Answer: The default color is the default markdown color. Look at the existing
reports in `$live_reference_sets/sets/live_12/reports` and use those colors for
now. We will optimize them later.

The caller passes the foreground and background colours.
The serializer only writes what it is given:

```ruby
LiveTrackSerializer.colored_code text, color_number: 21, background_color: '#18E9FE',
                                           foreground_color: '#000000'
LiveTrackSerializer.swatch 21, background_color: '#18E9FE', foreground_color: '#000000'
```


## Serializer Classes

The classes in `lib/live_set/serializer/` are placeholders, and the five below have been
agreed with the user, as the long TODO asks.

<!-- markdownlint-disable MD013 MD060 -->
| The class                           | It serializes                                                                        | Its model           |
|-------------------------------------|--------------------------------------------------------------------------------------|---------------------|
| `AlsModelSerializer`                | the whole model: the six sections of the report                                      | `AlsModel`          |
| `LiveHeaderSerializer`              | the facts about the set: the version of Live, the computer, the times, the time zone | the set             |
| `P3SCompatibility`                  | the verdict for a transfer to Push 3 Standalone                                      | the set             |
| `LiveGroupSerializer`               | a group: its line, its devices, the tracks in it                                     | `LiveGroup`         |
| `LiveGroupsSerializer`              | the groups of the set                                                                | `LiveGroups`        |
| `LiveTrackSerializer`               | a track: its line, its devices, its clips, its take lanes                            | `LiveTrack`         |
| `LiveTracksSerializer`              | the tracks of the set, and of a group                                                | `LiveTracks`        |
| `LiveDeviceSerializer`              | a device                                                                             | `LiveDevice`        |
| `LiveDevicesSerializer`             | the devices of a track, or of a group                                                | `LiveDevices`       |
| `LiveClipSerializer`                | a clip: its line, its file, and its settings                                          | `LiveClip`          |
| `LiveTakeLanesSerializer`           | the take lanes of a track                                                            | `LiveTakeLanes`     |
| `LiveTakeLaneSerializer`            | a take lane                                                                          | `LiveTakeLane`      |
| `LiveClipsSerializer`               | the clips of the set                                                                 | `LiveClips`         |
| `LiveSamplesSerializer`             | the samples of the set                                                               | `LiveSamples`       |
| `LiveAudioClipsSerializer`          | the clips of the audio side of a track                                               | `LiveAudioClips`    |
| `MissingSamplesSerializer`          | the samples that are not in the project, by pack                                     | `MissingSamples`    |
| `DeviceCrossReferenceSerializer`    | the devices of the set, and the tracks they are on                                   | the set             |
| `TrackClipCrossReferenceSerializer` | the tracks and their clips, and the clips and their tracks                           | the set             |
<!-- markdownlint-enable MD013 MD060 -->

Every serializer is given the hierarchical number of the thing it writes, along with the
model, and the constructors of the placeholders are written that way already.


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

The outline is written by AlsModelSerializer, which iterates through the groups and the
top-level tracks, and passes each of them along with a hierarchical base number to the
serializer.

## The models the serializers need

A model is a model of the XML contents. There is more than one model class, and there is
more than one kind of thing in a set: a track, a group, a clip, a device, a sample, a
scene. Each class models the part of the XML it is about.

The models are not serializers. They represent the XML entity, and the serializers write
them.

| The model | It holds | It comes from |
| --- | --- | --- |
| `LiveTrack` | the kind, the name, the colour, the devices, the clips, the take lanes, the members and the state of a track | `LiveTrack`, `LiveGroup`, and the track handling in `LiveSetReport` |
| `LiveGroup` | a model of the track group in the XML: the group, its devices, and the tracks in it | the class that exists |
| `LiveDevice` | a device of a chain: its name, its kind, its plug-in format, and whether Push 3 Standalone can run it | `LiveDevice`, the class that exists |
| `LiveClip` | one clip in the file: its name, its file, its colour, its marks, its launch mode, its warp mode, its notes, and the place it is in | the clip handling in `LiveSetReport` |
| `LiveTakeLane` | a take lane of a track: its name, and the clips of it | `take_lanes_of` in `LiveSetReport` |
| `LiveSample` | a sample of the set, its file, and the pack it is in | the sample handling in `LiveSetReport` |
| `MissingSamples` | the samples that are not in the project, by pack | `missing_samples_markdown` in `LiveSetReport` |
| `HeaderBlock` | the facts about the set | `metadata_markdown` in `LiveSetReport` |
| `LiveAudioClip` | a clip of the audio side of a track: its file, its size, and whether the file is collected | `LiveAudioClip`, the class that exists |

Every collection of a model is a class of its own, named for the things it holds, and each
of them has a serializer of its own:

| The collection | It holds | Its serializer |
| --- | --- | --- |
| `LiveTracks` | the tracks of the set, and the tracks of a group | `LiveTracksSerializer` |
| `LiveGroups` | the groups of the set | `LiveGroupsSerializer` |
| `LiveDevices` | the devices of a track, or of a group | `LiveDevicesSerializer` |
| `LiveTakeLanes` | the take lanes of a track | `LiveTakeLanesSerializer` |
| `LiveClips` | the clips of the set, and the clips of a track | `LiveClipsSerializer` |
| `LiveSamples` | the samples of the set | `LiveSamplesSerializer` |
| `LiveAudioClips` | the clips of the audio side of a track | `LiveAudioClipsSerializer` |

`LiveTracks` is the class that exists. `MissingSamples` is the part of `LiveSamples` that is
not in the project, so it is a view of the collection and not a collection of its own.

### There is no clip reference in the format

A clip belongs to a place. The Session View and the Arrangement View "each hold individual
collections of clips" (Live Concepts), and a Session clip copied into the Arrangement is an
independent Arrangement clip.

The file agrees. One clip of the Live 11 reference set, `3-Kontakt 7 1`, is written out as
eight complete `MidiClip` elements, seven of them with the same forty-seven note events; an
audio clip, `Pink Noise - EDMtips.com`, is written out eleven times, each with its own
`Id` and its own `SampleRef`. `LomId` is `0` throughout and ties nothing together.

What is referenced rather than copied is the sample: the audio of a set is in files beside
it, and each clip holds the pointer to the file in its `<SampleRef>`. Several clips can
point at the same file, and each can play it differently — reversed, warped differently,
trimmed — without touching the file. The notes of a MIDI clip are in the element, so they
are copied with it.

`LomId` is the identifier the Live Object Model uses while Live is running; it is `0` in
the elements of a saved set, and it is not a key that ties the copies of a clip together.

So `LiveClip` is one clip in the file, with its own settings and its own place, and there is
no `LiveClipReference` and no `LiveClipSettings`: the launch mode and the warp mode belong
to the clip element they are written in.

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

This project has several executables: `live_set` writes the report of a set, `als_delta`
diffs two sets, `generate_xsd` writes a schema of the format, `validate_asd` checks a set
against a schema, and one of them converts a set between two versions of Live.

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

## What is broken now, and what is to be decided about it

Three things were found while the plan was written. None of them is fixed; they are part of
the plan, and two of them need a decision.

1. **The program does not run.** The palette's `name_span` takes `p3s_incompatible:` where
   the report passes `dark:`, so `live_set -s <set>` raises
   `ArgumentError: unknown keyword: :dark`. The checked-in reports and the specs were made
   against the older markup: the palette now writes `title="Live color 32"` where the
   report wrote `title="color 32"`, and `background-color: #…; color: #…` where it wrote
   `background-color:#…;color:#…`.

   **To be decided:** whether the report's calls are corrected first, as a step of their
   own, so that the program runs again and the reports can be regenerated; or whether the
   program stays broken until step 1 replaces those calls with `colored_code`.

2. **The palette does not require the log, and `icon_of` calls `Log.warn`.** The method
   raises `NameError` when the palette is loaded on its own. The serializer that takes the
   icons requires the log.

3. **Live 12's master track has no icon.** Live 12 writes a `MainTrack`, the report calls
   its kind `Main`, and `ICONS` has no `Main`, so `icon_of` logs a warning and writes the
   bomb. Live 11's `MasterTrack` is in the map and gets the fader.

   **To be decided:** the icon for `Main`, or whether the report calls the kind of the
   master track `Master` in both versions, so that the map needs no second entry.

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

**The report as a whole has a spec of its own.** One spec asserts that the report of a set
is the report that is checked in, so that a change to any part of it cannot slip through
the specs of the parts. The checked-in reports are the ones `bin/generate_reference_als_reports`
writes, and the spec reads them from the repository of the reference sets.

**The specs are written before the serializers are finished.** Each serializer is written to
its spec, and the spec is where the new markdown is seen first. The placeholder classes
already say "TODO Write unit tests", and that is where the tests go.

## The work in the serializer placeholders

The classes in `lib/live_set/serializer/` are placeholders: each has a class, a
constructor, and a `to_markdown` that returns nothing. Each carries the TODO "Write unit
tests".

Three of them have mistakes that are fixed as they are written:

- `LiveTrackSerializer#to_markdown` refers to `group_track_devices_markdown`, which does not
  exist there, and it iterates `@track.clip_references` to write the devices of the track.
- `LiveGroupTrackSerializer#to_markdown` has no header line, and the TODO says what it
  should be: `Group track 1 👥 Group # Drums`.
- `AlsModelSerializer#to_markdown` writes the hierarchy by calling `to_markdown` on a model,
  which is the one thing the architecture says never happens. The hierarchy is written by
  the group serializer, which is given the ALS model:

  ```ruby
  hierarchical_entities = LiveGroupTrackSerializer.new(@als_model).to_markdown
  ```

  The group serializer is given the ALS model, so it is the one that iterates the groups and
  the top-level tracks, and passes each of them, with its base number, to the serializer
  that writes it.

The name `LiveGroupTrack` in that file is a typo for `LiveGroup`, the class that exists, and
is corrected. The sample usage in that file also names an argument the existing class does
not take: `LiveGroup` is built from a group element and the tracks of the set, and the
serializer is given the group and the number to write it under.

## The text that changes with this work

- **The legend the report writes** — the `LEGEND` constant of
  `lib/live_set/live_set_report.rb` — says that every place a clip is in "holds a reference
  to it", and that the settings of a reference belong to the reference and not to the clip.
  There is no reference in the format: each place holds its own clip, and the settings
  belong to the clip element they are written in. The legend says that instead, and the
  reports of the reference sets are regenerated, so the new wording is in them. The item is
  **N57** in `TODO.md`.
- **The reports of the reference sets** are regenerated, so the legend and the tables of the
  reports change with it.

## The documentation

The facts that were learned while this plan was written are in the documents, so that they
are not lost when the plan is executed:

| What was learned | Where it is written down |
| --- | --- |
| Every place holds its own clip; there is no clip reference in the format; the sample is what is referenced | `docs/als_notes.md`, "Every place holds its own clip" |
| The colour of a track or a clip is a number that indexes the colour menu of Live | `docs/als_notes.md`, "The colour of a track or a clip" |
| What a clip is, and what alike clips are | `docs/glossary.md`, "Clip" |
| How the report writes a name: the style on the `code` element, black or white by brightness, the tooltip with the number | `README.md`, "The Report" |
| The model, its classes, and the rules the models and the serializers follow | `docs/report_design.md` |
| The work itself | this document |

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
   | `lib/live_set/live_set_track.rb` | `lib/live_set/model/live_track.rb` | `LiveTrack` |
   | `lib/live_set/live_tracks.rb` | `lib/live_set/model/live_tracks.rb` | `LiveTracks` |

   and their nine specs move with them into `spec/live_set/model/`, renamed the same way:
   `spec/live_set/live_set_track_audio_clips_spec.rb` becomes
   `spec/live_set/model/live_track_audio_clips_spec.rb`, and so on.

   Three things the move breaks, and what is done about each:

   a. **The new directories are loaded.** `require_directory` globs `dir/*.rb` and does not
      recurse (`lib/common/util.rb:37`), so `lib/live_set.rb` requires `live_set/model`,
      `live_set/serializer` and `live_set/tx` as well as `live_set` itself. What is left
      is that each file in them requires what it uses: the model files use `LiveDevice`,
      `LiveTrack` and `LiveGroup` without requiring them today (`live_set_track.rb:34`,
      `live_set_group.rb:41`, `live_tracks.rb:4`), and the specs require the files one at a
      time (`require 'live_set/live_set_track'`), so the files have to stand on their own.
   b. **`lib/common/xml.rb:102` reaches `LiveDevice::CONTAINER_ELEMENTS`** — a dependency of
      `lib/common` on a model class, and `lib/common` is loaded before the model. It works
      today only because the constant is looked up when the method is called. The
      device-chain walk moves into the model layer: `xml_chain_devices`
      (`lib/common/xml.rb:99`) and the container-element filter become part of the model of
      a track, and `lib/common/xml.rb` keeps the XML helpers that are not about devices.
   c. **The load order.** Today the files lean on alphabetical order: `live_device.rb`
      sorts before `live_set_track.rb`, and `live_tracks.rb` after both. The explicit
      requires of (a) make the order irrelevant.

   Two small things the move touches: the `require` lines of the seven specs that name the
   moved files, and the `CustomTransform` map in `.rubocop.yml:99` that names the old file
   names (the cop is disabled, but the map should not be stale).

   What the move does not do: it does not move `verdict_markdown` out of `LiveTracks` —
   that belongs to `P3SCompatibility`, and it is the business of the serializer step; and
   it does not retire `LiveSetReport`, which is the business of the last step.
   `Rakefile:21` (`load 'live_set/version.rb'`, which is at `lib/live_set/version.rb`) is a
   pre-existing bug and is not touched by this.

2. **The formatting moves from the palette to `LiveTrackSerializer`.** `LivePalette` keeps
   `COLORS` and `color_of`, and loses `LIGHT`, `ICONS`, `icon_of`, `name_span`,
   `code_span`, `text_color` and `brightness`. The markup written is the markup written
   today, so the report does not change. The log is required by the serializer. A spec for
   the serializer.
3. **The models are written**, one at a time, each with a spec: `LiveClipReference` and
   `LiveClipSettings` first, because the clip lines carry the most detail, then
   `LiveTakeLane` and `LiveTakeLanes`, then `LiveClip`, then `LiveTrack` and
   `LiveGroup`. Each model leaves a note where it does not parse something, as above.
4. **The serializers are written**, one at a time, each with a spec, and the report calls
   each one in place of the method it replaces. The report shrinks as they arrive. Each new
   serializer class is agreed with the user before it is written. The spec of a serializer
   is written before the serializer is finished, and the expected values in it are the
   markdown as it is at that moment.
5. **The report is left as a writer.** What is left of `LiveSetReport` is the header block
   and the four tables, and the header block becomes `HeaderBlock` when the models are in
   place.

## The evidence that nothing has broken

- The 23 reports under `sets/*/reports/` of the reference sets are regenerated after every
  step, and diffed. The report must not change, except for what is asked for.
- The spec of the report as a whole compares the report of a set with the report that is
  checked in.
- The specs of the serializers hold the expected markdown, whole and literal, so a change
  to the markdown shows up in the diff of the spec that expects it.
- The specs of the report (`spec/live_set/live_set_show_spec.rb`) are the other check.
- `bundle exec rubocop` is clean after every step, and the specs pass before it is run.

## The other TODOs in the code

These are not in `live_palette.rb`, and are not part of this plan, but they are the same
work and are listed here so that they are not lost:

| Where | The TODO |
| --- | --- |
| `live_set_report.rb:17` | create the classes: `HeaderBlock`, `P3SCompatible`, `LiveClip`, `LiveClipReference`, `LiveClipSettings`, `LiveDevice`, `LiveSample`, `MissingSamples` |
| `live_set_report.rb:708` | `states_of` should take a `LiveTrack` instead of an XML element, and move to the `LiveTrack` class |
| `live_set_report.rb:714` | `frozen?` is a built-in method of `Object` in Ruby; the method should be part of the `LiveTrack` class |
| `live_set_report.rb:716-719` | `frozen?`, `soloed?`, `armed?` and `off?` should be methods of the track |
| `live_set_report.rb:801` | `missing_samples_markdown` should move to a `MissingSamples` class |
| `live_set_report.rb:838`, `:862` | the device methods should move to a `LiveDevices` class, and be renamed to `markdown` |
| `live_set_report.rb:1095` | `track_tree` should move to a `LiveTracks` class, and be renamed to `tree`; `LiveTracks` would be a collection of `LiveTrack` objects, and `LiveTrack` a wrapper around a track element |
| `live_set_report.rb:1113` | `build_track_tree` should move to a `LiveGroup` class, and be renamed |
| `live_set_report.rb:1356` | `mark` should be renamed to `checkmark` |
