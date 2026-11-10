# Fix Plan: the model, the serializers, and the documents that describe them

## Context

The report of a set is written from a model of the set: the model holds the facts, and a
serializer writes them as markdown. The rules of that arrangement are written down in
[`als_architecture.md`](als_architecture.md), "Target Architecture", and in
[`report_design.md`](report_design.md), "Implementation".

The code does not follow those rules everywhere yet, and it says so: there are 45 `TODO` and
`FIXME` comments in 27 files under `lib/`, and four more in `exe/` and `dev/`. Each of them
asks for something. This document gathers them, reads each against the document it cites,
and proposes an order to do them in.

It is a proposal. Nothing here has been agreed to, and the items are not in the order they
were written.

The outstanding work of the gem as a whole is in [`TODO.md`](TODO.md), and the identifiers
there are the ones the code and the documents cite. Where an item of this plan is
outstanding work already logged there, this plan refers to it by its identifier.

## What was read

The comments in the code, and the documents they cite:

| The document | The citations in the code | Its state |
| --- | --- | --- |
| [`als_notes.md`](als_notes.md) | 25 | Corrected in the last four days. The authority on the format. |
| [`report_design.md`](report_design.md) | 14 | Corrected in the last four days. The authority on the model and the report. |
| [`cpfir.md`](cpfir.md) | 8 | Not corrected. Stale. |
| [`glossary.md`](glossary.md) | 4 | Not corrected. Stale. |
| [`conversion.md`](conversion.md) | 4 | Not corrected. Stale. |
| [`serializer_plan.md`](serializer_plan.md) | 3 | Corrected in the last four days. The plan of record for the serializers. |
| [`live_11_12_diff.md`](live_11_12_diff.md) | 3 | Not corrected. Stale. |
| [`als_work.md`](als_work.md) | 2 | Corrected in the last four days. |
| [`TODO.md`](TODO.md) | N41, N56 | Corrected in the last four days. |

The documents that were corrected in the last four days are the corrections, and they are
trusted. The documents that were not are stale, and the work of correcting them is item 8
below.

The headings are what the code cites, so a heading that is renamed breaks the citations.
Four of the headings the code cites no longer exist, because `als_notes.md` was rewritten
underneath the code:

| The citation | Where it is | The heading now |
| --- | --- | --- |
| "Every value is stored in a `Value` attribute" | `lib/live_set/model/live_audio_clip.rb:15` | "Values are stored in `Value` Attributes" |
| "The group tracks" | `lib/live_set/model/live_group.rb:17` | "Group Tracks" |
| "A member track names its group" | `live_group.rb:69`, `live_group.rb:135`, `live_track_facts.rb:156` | "Group Tracks" |
| "The device chain of a group" | `live_device.rb:61`, `live_tracks.rb:268`, `live_track_facts.rb:88` | "Group Device Chain" |

## The principles, and where they are written

- **A model class represents one XML entity, and holds what the XML holds and nothing else.**
  `als_architecture.md`, "Target Architecture"; `report_design.md`, "Implementation".
- **Every collection is a class of its own**, named for the things it holds.
  `als_architecture.md`, "Target Architecture".
- **A model does not write markdown.** "Model classes should not have methods called
  `to_markdown` or `to_number` because that functionality belongs to the corresponding
  serializer class." `report_design.md`, "Implementation".
- **The numbering is added by the serializers.** "Model serializers that process collections
  generate numbered lists and pass them to the child serializers."
  `report_design.md`, "Implementation"; `serializer_plan.md`, "Serializer Responsibilities".
- **A serializer is initialized from a model instance**, and the hierarchy of the serializers
  mirrors the hierarchy of the models. `als_architecture.md`, "Target Architecture".
- **Where several serializers have common behaviour, that behaviour is extracted into a
  helper.** `als_architecture.md`, "Target Architecture".
- **The indent of a thing comes from its number**, and the outline is one list.
  `report_design.md`, "Implementation".
- **The terms are the ones in `glossary.md`.** The glossary is stale; item 8 brings it up to
  date.

The two documents that state the principles disagree about the name of one method: the design
says `to_number`, the code says `number_of`. The name is settled when the method moves.

## The work

### 1. The model and the serializer boundary

Eight model classes still write markdown, and three of them also number the things they
write:

| The class | The methods | Who calls them |
| --- | --- | --- |
| `LiveMidiTrack` | `to_markdown(number)` | `LiveMidiTracks#to_markdown` |
| `LiveAudioTrack` | `to_markdown(number)` | `LiveAudioTracks#to_markdown` |
| `LiveReturnTrack` | `to_markdown(number)` | `LiveReturnTracks#to_markdown` |
| `LiveMasterTrack` | `to_markdown(number)` | `AlsModelSerializer#master_section` |
| `LiveMidiTracks` | `to_markdown`, `number_of` | `LiveTracks#separate_markdown` |
| `LiveAudioTracks` | `to_markdown`, `number_of` | `LiveTracks#separate_markdown` |
| `LiveReturnTracks` | `to_markdown`, `number_of` | nothing |
| `LiveTracks` | `to_markdown`, `ordered_markdown`, `separate_markdown`, `numbered_tracks_of_the_set`, `each_numbered_track` | `AlsModelSerializer`, `LiveClips`, `LiveTrackClipCrossReference`, `TrackClipCrossReferenceSerializer` |

The numbering the collections do is already done in the serializer layer:
`LiveTrackCollectionSerializer#number_of` is the same method, in the right place. The
group serializer uses it (`LiveGroupSerializer:94`); the tracks of the set do not.

**Proposed.** A `LiveTracksSerializer` writes the tracks of the set: it numbers them, it
writes them in the order Live wrote them, and it writes the two lists when the
`--show_midi_and_audio_tracks_separately` option is given. The eight methods above are
deleted from the models, and the models keep the facts they hold: `track_ids`,
`top_level_tracks`, `groups_of_the_set`, `tracks_by_id`.

The three cross-references that number the tracks (`LiveClips`, `LiveTrackClipCrossReference`,
`TrackClipCrossReferenceSerializer`) are given the numbered tracks by the serializer that
numbers them, so that the number of a track is made in one place.

### 2. One name of a track

The name of a track, on the colour Live gave it, is written four times:

| The copy | Where |
| --- | --- |
| `LiveMarkup.track_name_markdown` | `lib/live_set/serializer/live_markup.rb` |
| `LiveTracks#track_label` | `lib/live_set/model/live_tracks.rb:193` |
| `DeviceCrossReferenceSerializer#track_label` | `lib/live_set/serializer/device_cross_reference_serializer.rb:57` |
| `TrackClipCrossReferenceSerializer#track_label` | `lib/live_set/serializer/track_clip_cross_reference_serializer.rb` |

Three of them carry a TODO that says the code is identical and should be consolidated. It
is: the four differ only in the details.

**Proposed.** `LiveMarkup.track_name_markdown` is the one copy, and the other three call it.
The copy in the model goes with it: a model does not write markdown.

### 3. The verdict

`LiveTracks#p3s_errors` and `LiveTracks#p3s_advice` build the sentences the verdict is made
of, and the sentences begin with `" - "`, a markdown list marker. `P3SCompatibility` then
strips the marker again with a regular expression, so that the marker can be written
properly:

```ruby
errors.each { |error| lines << "- #{error.sub(/\A\s*-\s*/, '')}" }
```

**Proposed.** The model holds the facts of the verdict — the track, the device, the reason —
and `P3SCompatibility` writes the sentences. The regular expression goes.

### 4. The report's own wording and markup

| The comment | Where | What it asks for |
| --- | --- | --- |
| FIXME | `live_master_track_serializer.rb:26` | The word "Master" appears twice in a section of one line. The comment shows the HTML it should be. |
| TODO | `live_markup.rb:228` | The background of a track P3S cannot use should come from a style sheet. |
| TODO | `live_markup.rb:260` | The "solo" marker needs a style sheet too. |
| TODO | `live_audio_clip_serializer.rb:48` | The decoration of a warning is in the clip serializer, and the assets serializer wants it. |
| TODO | `live_assets_serializer.rb:94` | The same, from the other side. |

**Proposed.** The two warning TODOs are one piece of work: the decoration of a warning is one
method, in the helper both serializers use. The two style-sheet TODOs are questions, not
work: markdown has no style sheet, and the report is written in markdown. They are answered
in the document, and the comments are replaced by the answer.

The FIXME of the master track is work: the section is written by its serializer, and the
serializer writes one line.

### 5. The facts the model gets wrong or does not have

| The comment | Where | What it asks for |
| --- | --- | --- |
| TODO | `live_track_facts.rb:24`, `live_group.rb:49` | `group?` returns a constant. It should examine the track type. |
| TODO N41 | `live_track_facts.rb:178` | A device on both a track and its group is counted twice as a blocking device. |
| TODO N56 | `live_track_facts.rb:145` | `LinkedTrackGroupId` is in no set of the corpus. The report prints the id, and says what is known and what is not. |
| TODO | `live_midi_track.rb:30` | `set_directory` is not used by `LiveMidiTrack`. |
| TODO | `live_project_info.rb:63` | The warnings are logged as well as written in the report. They should not be logged when the report is being written. |
| TODO M11 | `TODO.md` | `LiveScene` is constructed in `AlsReport` and never used. |

**Proposed.** `group?` is one method on `LiveTrackFacts` that reads the kind of the track,
and the two copies go. The unused parameter of `LiveMidiTrack` is deleted, and the call sites
are corrected. The `@scenes` of `AlsReport` is deleted: a scene is either reported or not
built, and reporting it is item 1 of **D1** in `TODO.md`, which is a larger piece of work and
is not part of this plan.

N41 and N56 are logged in `TODO.md` and are questions about the format that need Live to
answer them. They stay open; what this plan does is make sure the report says what is known
about them.

### 6. The conversion

| The comment | Where | What it asks for |
| --- | --- | --- |
| FIXME | `live_11_and_12.rb:607` | `oversampling` does not test the version before it writes a value. |
| FIXME | `live_11_and_12.rb:617` | `audio_out_target` does not test the version before it writes a value. |
| FIXME | `live_11_and_12.rb:671` | "Live 12 leaves the question out" — what does that mean? |
| TODO | `live_11_and_12.rb:578` | The special transformations could be sorted alphabetically. |

**Proposed.** The two version FIXMEs are the same defect, and `docs/conversion.md` says what
the rule is: a transformation that renames an element matches either spelling and emits the
other, and a transformation that is conditioned on the direction says so. `oversampling` and
`audio_out_target` are of that kind, and they are written as if they were not. The third
FIXME is a sentence that says nothing; the fact it is attached to is that Live 12 leaves the
`NeedRefreeze` element out of the clip slots it writes, and Live 11 does not have the
question. That sentence is written out, and the fact is stated in `live_11_12_diff.md`.

### 7. The commands

| The comment | Where | What it asks for |
| --- | --- | --- |
| TODO | `als_to_xsd.rb:9` | Make it a library, so it can be called from other code. |
| TODO | `als_to_xsd.rb:34` | Return an error code instead of calling `exit`. |
| TODO | `exe/als_to_xsd:3` | The same, from the command. |
| TODO | `exe/als_delta:9` | The same, of `als_delta`. |
| TODO | `exe/als_xsd_order:7` | The command should be deleted: it was written for one spec that does not need a command line. |
| TODO | `als_diff.rb:32` | Compare attributes as well. |
| TODO | `als_delta_options.rb:8` | Document where the backups are stored, and how to change that location. |
| TODO | `als_release_notes.rb` | Decide how to resolve `docs/release_notes/`. |
| TODO | `demo_sets.rb:29` | Discover where the factory packs are stored, instead of hard-coding the directories. |
| TODO | `common/xml.rb:13` | "What does this comment mean?" — the comment above it. |
| TODO | `dev/generate_xsds:29` | The repository of the reference sets was reorganized. Is `CONVERSIONS_DIR` still right? |

**Proposed.** The two TODOs of `als_to_xsd` are one piece of work: the code that builds a
schema moves into a library, and the command becomes a thin wrapper that returns an error
code. The same is done for `als_delta`, and `als_xsd_order` is deleted with the references
to it — in the README, in `docs/index.md`, and in the spec that needs it. The other five are
small: each is either a sentence in a document, or a small method. The `xml.rb` comment asks
a question of a comment that has outlived its subject; the comment is read, and either
rewritten or deleted.

### 8. The documentation

About 40% of the documentation has been corrected in the last four days. The other 60% is
stale, and it is not all of it: some of the stale parts are in the documents that were
corrected.

**Proposed.** The corrections are made in this order:

1. **The citations the code makes.** The four headings in the table above are renamed in the
   code, or the headings are restored in `als_notes.md`. The two file paths that do not exist
   anywhere — `lib/live_set/live_palette.rb`, cited by `live_device_serializer.rb:1` and
   `p3s_compatibility.rb:1` — are corrected to `lib/live_set/model/live_palette.rb`, and the
   two TODOs that cite them are deleted: the work they describe, moving the formatting out
   of the palette, is done.
2. **The file references the documents make.** Seventeen of them name files that no longer
   exist: `lib/live_set/live_set_report.rb` (in `als_notes.md`, `serializer_plan.md` and
   `TODO.md`), `lib/live_set/model/live_track.rb` (in `als_notes.md` and
   `serializer_plan.md`), the six model files that moved and the palette that moved with
   them (in `serializer_plan.md`), `lib/als_report/als_model_serializer.rb` (in
   `als_architecture.md`), `lib/live_set/xml_diff.rb` (in `cpfir.md`), and the specs that
   were renamed or moved. Each is corrected to the file that is there now, or the sentence is
   rewritten.
3. **The stale documents.** `cpfir.md`, `glossary.md`, `conversion.md`, `ab_test_plan.md` and
   `live_11_12_diff.md` are read against the code and corrected. `glossary.md` comes first:
   it defines the terms the other documents use, and the plan of record says so.
4. **`docs/serializer_plan.md`.** It is the plan of record, and the work it describes has
   been done: the steps 1 to 5 and 7 are finished, and the step 6 — the identity of a MIDI
   clip — is not. The plan is rewritten to say what is left, and the parts that are done are
   deleted.
5. **`docs/index.md` and the README.** The index links to `live_schemas.md`, which is in the
   repository of the reference sets and not here. The README describes the report of a set
   before the seven changes of this autumn; it is brought up to date with the report as it
   is written now.

`docs/old/` is left alone: `TODO.md` says to ignore it unless historical information is
required.

## The steps

Each step leaves the program working, and the reports of the reference sets unchanged except
for what the step asks for.

1. **The stale citations are corrected.** The four headings, the two file paths, and the
   seventeen file references. No behaviour changes; the diff is in the comments and in the
   documents. — **Done.** The four headings are the ones `als_notes.md` has now; the two
   file paths are the palette's; the file references are corrected, and the two tables of
   `serializer_plan.md` that name files which have moved or been retired now say so.
2. **`LiveMarkup.track_name_markdown` is the one name of a track.** The three copies call it,
   and the copy in the model goes. — **Done.** `LiveMarkup.track_name_markdown` writes the
   name, and takes `in_a_cell` for the tables of the cross-references. The two
   cross-reference serializers and the verdict in `P3SCompatibility` call it; the three copies
   are gone. The name of a thing is now a fact of the model: `display_name` is on
   `LiveTrackFacts` and on `LiveGroup`, and `LiveMarkup.display_name` is gone.
3. **The model classes lose their markdown.** `LiveTracksSerializer` is written, with a spec,
   and the eight methods are deleted from the models. The numbering of the tracks is made in
   one place, and the three cross-references that number tracks are given the numbered
   tracks. — **Done.** `LiveTracksSerializer` numbers the tracks at the top of the set and
   the members of the groups, and `LiveGroupSerializer#numbered_members` makes the numbers
   of the members, so that the outline and the cross-reference agree by construction. The
   models lost `to_markdown` (eight classes), `number_of` (three collections) and
   `LiveTracks#each_numbered_track`. `LiveClips` and `LiveClipsSerializer` were dead, and
   are deleted. The cross-reference is given the numbered tracks instead of making them.
4. **The verdict holds facts, not sentences.** `LiveTracks` holds the track, the device and
   the reason; `P3SCompatibility` writes them. — **Done.** `LiveTracks` holds
   `blocking_tracks`, `blocking_groups`, `max_for_live_tracks` and `max_for_live_groups`;
   `LiveGroup` holds `affected_track_names`; `P3SCompatibility` writes the sentences, and the
   regular expression that stripped the list marker is gone. The verdict reads the facts of
   the whole file as well: the version of Live that wrote the set
   (`HeaderBlock#live_version`), the packs the set refers to (`LivePacks`), the size of the
   project (`LiveSizes`), and the clips of the session view
   (`LiveTracks#session_view_clips`).
5. **The warning decoration is one method**, in the helper the clip serializer and the
   assets serializer both use.
6. **The model is corrected.** `group?` is one method; the unused parameter of
   `LiveMidiTrack` is deleted; the unused scenes of `AlsReport` are deleted; the master
   track section is written as its FIXME says it should be. — **Done.**
   `LiveTrackFacts#group?` reads the kind of the track, and `LiveGroup` includes
   `LiveTrackFacts`, so the two copies are one; the unused `set_directory` parameter of
   `LiveMidiTrack` and of `LiveMidiTracks` is gone, and the call sites are corrected; the
   section of the master track is the heading of the section and the number of the track,
   and the word "Master" is not in the line of the track as well.
7. **The conversion is corrected.** The two version FIXMEs, the sentence that says nothing,
   and the sorting of the special transformations.
8. **The commands are corrected.** `als_to_xsd` becomes a library with a thin wrapper, and
   the five small items are done.
9. **The documents are brought up to date.** The order of item 8 above.

## The proof

- The specs of the models and the serializers pass, and the spec of the report as a whole
  passes: `bundle exec rspec spec/live_set spec/als_report`. The end-to-end conversion spec,
  `spec/live_set/tx/live_conversion_spec.rb`, is not run here: it takes a long time, and it
  fails for a reason of its own.
- `bundle exec rubocop` is clean.
- The reports of the reference sets are regenerated and diffed:
  `ruby dev/generate_reference_als_reports`. The report must not change, except for what the
  step asks for.
- Every TODO and FIXME that is done is deleted, and every TODO item that is done is deleted
  from `TODO.md`, in the manner `TODO.md` describes.

## The questions that are still open

These are questions, not work. They are in `TODO.md`, and this plan does not answer them.

- **N57** — the legend of the report describes clip references, and there are none. The
  legend and the lines under a clip are to be reworded. The model part of it is done: there
  is no `LiveClipReference` and no `LiveClipSettings`. The wording is not.
- **N58, N59** — should each asset carry a hash of its own, and should the report carry a
  checksum of the tool that made it?
- **N60** — the report should fold when a reader clicks a node.
- **The identity of a MIDI clip** — `notes`, `keys` or `loop` — is the step 6 of
  `serializer_plan.md`, and it is not done. The section it adds, `## Identical MIDI Clips`,
  is not in the report.
- **The devices of a Max for Live device.** The report says a Max for Live device is not
  usable on the P3S Standalone, and the FIXME in the spec of the group serializer says that
  is wrong: they are supported, with less headroom. **Answered:** a Max for Live device is
  advice and not an error. The P3S Standalone runs one, and the report names the devices of
  the set that use one, so that they can be frozen if they overload the P3S. The device is
  recognized by the element it is written as — `MxDeviceAudioEffect`, `MxDeviceMidiEffect`,
  or `MxDeviceInstrument` — and by nothing else.
- **The sections of the report.** `report_design.md` lists `## Referenced Packs` as a section
  of its own, and the report writes it as `### Referenced Packs` under `## Test Environment`.
  One of the two is wrong.
