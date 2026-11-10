# TODO

The scope of this document is restricted to the outstanding work of the `live_set` gem.

Every TODO item has an identifier, and the identifiers are stable: the code, the
specs and the documents cite them, so an identifier is never reused, and its
meaning never changes. When an item is completed
anything worth keeping is written up in another Markdown file in `docs/` and/or
the code itself, then the entry is deleted from this file.

This project was developed for WSL, which implies Windows 10 or 11. Ruby, Bash and
PowerShell are the principal languages in use for this project.


## Latest Thoughts

## Main Topics Discussed

- Simple operations, such as changing a set’s displayed name or copying a MIDI
  map between sets, should modify the relevant XML directly rather than require
  parsing the entire file into an object model.
- Reporting is expected to provide substantially more value than converting.
  Convert only the entities needed to make reports efficient; converting the
  complete set is not a priority.
- An end-user command should open Live 12, gather required content, ensure
  anything that needs freezing is frozen, save the set, and send it to Push 3.
- The next major commands should show real-time changes and compare two or more
  sets. Organize contributions by party in separate subdirectories, with support
  for a generic number of parties rather than only two. Show differences in
  timeline order, and report only changes—not the full report—to keep output
  readable.
- Detect possible changes made to audio files outside Live by comparing file
  sizes and dates with their recorded
  values. Verify whether Live updates sample parameters when a changed file is
  next opened.

### Priorities

1. Complete reporting.
2. Add real-time change reporting
3. timeline-sorted comparisons across
   multiple parties.
4. Investigate reliable detection of external audio-file changes.
5. Implement end-user Push 3 preparation and transfer workflow.


## Reverse Engineering Work

[`gui_harness`](https://github.com/mslinn/gui_harness) is the basis for the
reverse engineering of the Ableton Live XML format.

At a high level, the GUI harness does the following:

1. Launch a live app
2. Inspect the process-owned windows
3. Read visible dialog text
4. Classify the dialog family
5. Dismiss the correct control
6. Report the outcome.


### Outstanding work

The commands in `exe/` are now usable, however minor bugs are expected, and all
bugs musts of course be logged in this file and fixed.

The documentation (mostly in top-level markdown files and the `docs/` directory
tree) likely has errors, omissions and inconsistencies; these must also be
logged and fixed. See TODO and FIXME comments throughout the project.

Ignore the contents of `docs/old/` unless historical information is required.

The TODO itens are listed in the suggested order of completion:


#### D1. Required Model Classes, Serializers, and Specs

Implement models, serializers, and specs for the following:

- Track mixer: volume, pan, and sends
- Device parameters
- Scenes and the scene grid
- Sample warp markers
- Automation envelopes of a track
- Arrangement markers
- Set templates?
- User presets?
- Racks
- State of the Live window, including the selected track, browser unfolded
  state, the arrangment zoom. This model class might not be included when
  computing equivalence between sets.

#### FU1. The values to compute

the report has none of these today

- LiveTrackFacts#device_summary — split into the blocking devices (the plug-ins) and the M4L devices. It lists every
  device in the chain today, native ones included.

#### T5. Tighten conversion check names and scope

The existing specs should be organized around the exact contract they prove:
conversion output, Live compatibility, or harness parsing.

#### T1. XML-level validation of the Live 11 conversion

The conversion contract should be made explicit by asserting the supported lane
types, the expected `ContentLanes` and `ExpressionLanes` structure, and the
required absence of unsupported Live 12-only nodes.

#### GH1. Round-trip Equivalence

For each reference set, the round-trip test should assert more than just `no
error` and `End ExchangeDocument`; it should also confirm the converted set
preserves XML structure, and opens cleanly in the appropriate version of Ableton
Live without triggering a crash.

#### M11. Use `LiveScene`

`LiveScene` is constructed but never used in a meaningful way. This should
either be included as part of the model and reported.

The class reads its values the way Slop reads them — `@live_scene.Name`,
`@live_scene.Tempo` — so it only works on an element of a Slop-decorated
document. This is undesirable. `LiveSet` decorates the document it reads, so the
class works there, and it raises `NoMethodError` on an element of a plain
Nokogiri document.

The fix: The class should read its values with `at(...)`, like every other class
in this gem.


#### X1. New Command to Copy

[Ableton Live stores MIDI mapping per
set.](https://help.ableton.com/hc/en-us/articles/360000038859-Making-custom-MIDI-Mappings)
Yes, it can be defined in the default set.  However, Live does not provide a way
to copy MIDI mappings between sets.

In the ALS XML, the per-set mappings are under `<MidiMappings>`. Each assignment
is a `<MidiMapping>` child. We should check the reference sets for each version
to verify that `<MidiMappings>` and its children did not change from version to
version.

If no change, or if the ALS file versions are the same, we just need to copy
some or all of the `<MidiMappings>` element structure from one set to another.

The new `als_copy_midi_mapping` command syntax:

```text
als_copy_midi_mapping [OPTIONS] src_als dst_als

Where OPTIONS is:

-h/--help   Display this message
-c/--copy   TODO figure out how to specify one mapping or a subset of all mappings
-l/--list   Display the complete MIDI maps for both files
```

#### N53. Corpus Lacks Complete Test Data

Test ALS files must be created that contain:

- a frozen track, and a track whose clips are only in its `FreezeSequencer`.  At
  present, no track of any set in the corpus is frozen, and every
  `FreezeSequencer` of every track is empty.
- a plug-in nested in a group branch. The corpus holds one group branch, and
  the devices in it are native ones.
- a VST2 plug-in. The only plug-in in the corpus is a VST3, so the
  `PluginDesc/VstPluginInfo/PlugName` path is not read by any example.
- a native device with a `Name` element of its own. Every native device in
  the corpus has no `Name`.
  TODO How can a user add such a device to the reference set?
- a Device `Manufacturer` element. No element in the corpus has one, so the
  manufacturer part of a device's label is never read.
- a clip without a `SampleRef`
- a clip whose `LastModDate` is zero or absent.
- a track without a `DeviceChain`.
- a scene with a tempo of its own. Every scene in the corpus has `IsTempoEnabled` false.

Also, Live 8 and Live 9 demo sets have been installed but are not in
`$live_reference_sets/sets/` yet.


#### N36. `als_delta` compares against a backup, not the previous version

The first comparison is effectively against itself because the backup logic does
not compare against the prior version in the first run. Use `gui_harness` to run
als_delta and summarize changes in the ALS XML when the harness performs the
following automated tasks ()

See [OSC](docs/osc.md) for information about how to automate Ableton Live from
Ruby using OSC.


#### N10. `LiveTracks#ready_for_p3s?` dead code

This helper is defined but not used; the inline `p3s_tx_msg` logic already
covers the relevant behavior.


#### N37. Frozen-track clip reporting is confusing

The same clip can be encountered through both sequencers and reported more than
once. The distinction between source and distinct files should be clarified.

#### N40. Group device chain reporting is incomplete

A group-level device blocking condition is reported on the group, but not on the
member tracks that inherit the same signal path.

#### N41. Blocking device on group member is counted twice

A device on both a track and its group results in duplicated reporting for the
same underlying problem.

#### N42. Unknown lane `Type` values may crash Live 11

The Live 12 lane numbering is not portable to Live 11, and the round-tripped set
keeps lane `Type` values that Live 11 does not understand. This is the main
unresolved compatibility risk.

#### N43. `FakeGroup` remains unverified

The claim that a `FakeGroup` routing wrapper exists has not been confirmed from
the corpus examined so far.

#### N50. Known crash path missing as a failing regression

The current Live 11 crash behavior should be captured as a compact failing
regression fixture before treating a fix as complete.

#### N51. The Push 3 transfer message and the frozen marker have no coverage

There are no unit tests that covere `LiveTracks#p3s_tx_msg` and `LiveTrack#show_track`

`p3s_tx_msg` has to be tested against a real set that has the three things it
reports: a clip that has not been collected, a third-party device on a track
that is not frozen, and a third-party device in the chain of a group. The demo
sets for Live 11 and 12 should be examined for such a set.

`show_track` says whether a track is frozen, and a group track cannot be frozen,
so the two have to be told apart. The demo sets have both.

#### N52. Successful Round-Trip from Live 11, to Live 12, and back to Live 11

The round trip needs three files:

1. A Live 11 set
   (`$live_reference_sets/<wbr>sets/<wbr>live_11/<wbr>experiments/<wbr>projects_and_als/<wbr>Fascination.als`);
   this set was created by a Live user and is not an official Live demo set.

2. The same set upgraded by Live 12 and saved to
   `$live_reference_sets/<wbr>sets/<wbr>live_12/experiments/projects_and_als/<wbr>Fascination_12_converted_by_live
   Project/`. The conversion was automated by
   `$live_set/<wbr>dev/<wbr>make_reference_set`.

3. The set this gem writes when it converts the upgrade set back to the Live 11
   format. The `als_to_version` command can perform this conversion.

The work is to convert of the Live 12 version back to the Live 11 format and
verify that the XML is well-formed and Ableton Live 11 can read the set back.
There is a spec for this:
`$live_set/<wbr>spec/<wbr>live_set/<wbr>tx/<wbr>live_12_fascination_down_spec.rb`.

#### N54. Live 8, Live 9 and Live 10 cannot be authorized

Every version of Live registers the file types of its sets when it starts, and that registration
needs the permission of an administrator. On this machine only Live 11 and Live 12 can be
authorized. Live 8, Live 9 and Live 10 start, but they cannot save sets: the registration cannot
be completed for them, so a set they are given is never written back.

The licences were the other half of it, and they are in place: the account holds the Suite
licence of every version from Live 8 to Live 12, and Ableton added the licences of Live 8
Suite, Live 9 Suite and Live 10 Suite on 4 November 2026. Live 9 Standard was installed in
the place of Live 9 Suite, and it is to be replaced by it. The versions are downloaded from
the Ableton download archive, and an offline authorization is tried when the online one does
not work. See `docs/als_work.md`, "The licences".

What is left is the registration, which the licences do not help with: until it is done for
those versions, the round trip through them cannot be proved by running Live, and the
examples that need them are the ones that are skipped.

The prompt is per version, and it only comes once per version: the first time a version runs it
asks, switching to another version asks again for that version, and running a version again does
not ask, provided the user accepted the first time. `docs/live_control_plan.md` describes the
behavior and what the harness does with it.

The prompt no longer stops the work: the harness writes a per-user registration of the
`ableton:` protocol before it starts Live, and takes it away when the run is over, so that the
version of Live that is about to run is the one the registration names and no prompt comes. That
is in the `gui_harness` project, in `docs/elevation.md`.

#### N55. The A/B program of nearly-empty sets

The program is in `docs/ab_test_plan.md`: nearly-empty Live 11 sets, one thing in each, written
by Live 11 and by Live 12 and compared, with the bridge and the version_diff document brought
up to date with what the comparison shows.

The first case is made: `sets/live_11/projects_and_als/one_midi_track_only_11 Project/one_midi_track_only_11.als`,
a Live 11.3.43 set with one MIDI track, the two return tracks, and no audio track. Its Live 12
counterpart has not been made yet.

Three questions are open, and they are the questions the first cases have to answer:

- What happens when every track is removed? The interface will not delete the last track that is
  left, so a set with no tracks has to be written by hand to find out.
- Will Live 11 and Live 12 load a programmatically created empty Live set? Live is strict about
  the sets it opens, and a set that Live rejects is a file and not a case.
- Can the MIDI track be deleted when it is the only track left? That settles whether Live
  protects the arrangement from being emptied, or protects an audio track from being the last
  one.

#### N56. `LinkedTrackGroupId` is not exercised by any set in the corpus

A track's `LinkedTrackGroupId` holds the id of the group of tracks it is linked to, and `-1`
means it is linked to no other. Linking is done with the Link Tracks command, in the context menu
of the head of a track in the arrangement view: the editing of the tracks of a group is locked
together, so that moving and resizing the clips, selecting, editing the time, splitting and
consolidating, the fades, arming and the take lanes of one of them happen to all of them at
once. See "Linked-Track Editing" in the manual of Live 12, section 6.14:
https://www.ableton.com/en/live-manual/12/arrangement-view/#linked-track-editing

The element is of Live 11 and later: it is in the schemas of Live 11 and Live 12, and in none of
the schemas of Live 8, 9 and 10. The groups themselves are held by the set, in
`LiveSet/LinkedTrackGroups`, a list whose items are `LinkedTrackGroup` elements, each with a
`Uuid`. See `C:\ProgramData\Ableton\Live 12 Suite\Resources\Schema\12.0_12402.txt`, lines 511,
521, 3790-3792 and 3867.

**Nothing in the corpus exercises it.** Every track of every set that could be reached has `-1`:
1,554 sets under the Ableton installations, `/mnt/m`, `/mnt/e` and `/mnt/f`, 220 under the user
profile, and about fifteen fixtures in the public repositories. The 871 of them that have a
`<LinkedTrackGroups />` element have an empty one. So the report cannot show a linked group, and
what it prints for the element is the id, with a comment that says what is known and what is
not.

What is not known, and what is left:

- What the integer of a track is in relation to the list of groups in the set. The items of the
  list are keyed by a `Uuid` and the reference is an integer, so the integer is probably an index
  into the list, but no sample confirms it.
- What a non-empty `<LinkedTrackGroups>` block looks like in a file that Live wrote.
- Whether the integer of a cluster is stable from one save of the set to the next, or is
  renumbered each time. That decides whether the report should print the integer at all, or only
  say that the track is linked with others.
- Whether two tracks of the same cluster always carry the same integer. The description of the
  feature says that they do; no set shows it.

The one way to close the gap is for Live to write such a set: open a set in Live 11 or Live 12,
select two or more tracks in the arrangement view, use Link Tracks on them, save, and look at
what is written. The set to use is a scratch copy of a small one — the factory default set of
Live 11 or Live 12 is enough, since two of its tracks can be linked.

#### N57. The legend of the report describes clip references, and there are none

The legend the report writes — the `LEGEND` constant of
`lib/live_set/serializer/als_model_serializer.rb` —
says that a clip is its name and the file it plays, and that every place a clip is in — a
slot of the session view, the arrangement, a take lane — holds a *reference* to it, and that
the settings of a reference belong to the reference and not to the clip.

**There is no clip reference in the format.** A clip belongs to a place, and each place holds
the whole clip. The Session View and the Arrangement View "each hold individual collections
of clips" (Live Concepts), and a Session clip copied into the Arrangement is an independent
Arrangement clip. The set that is checked in shows it: the clip `3-Kontakt 7 1` is written
out as eight complete `MidiClip` elements, seven of them with the same forty-seven
`MidiNoteEvent` elements, and the audio clip `Pink Noise - EDMtips.com` is written out as
eleven complete `AudioClip` elements, each with its own `Id` and its own `SampleRef`.
`LomId` is `0` throughout and is the identifier the Live Object Model uses while Live is
running; it ties nothing together. What is referenced rather than copied is the sample: the
audio is in files beside the set, and several clips can point at the same file and play it
differently. See `docs/als_notes.md`, "Every place holds its own clip", and `docs/glossary.md`,
"Clip".

What is left:

- The wording of the legend, and the wording of the lines under a clip, which the report
  calls "References (×7): launch: trigger, warp: none". The report groups the clips of a
  track that are alike — the same name, file, colour and state — and counts them; the
  settings they differ in are given under them. That grouping is the report's own, and the
  report should say so rather than describe a reference that the format does not have.
- The model. `LiveClip` is one clip in the file, with its own settings and its own place, and
  there is no `LiveClipReference` and no `LiveClipSettings`. `docs/report_design.md` and
  `docs/serializer_plan.md` say so; the code does not yet.
- The reports of the reference sets carry the old legend, and are regenerated when the
  wording changes.

#### N58. Should each asset of a set carry a hash of its own?

The report is to carry a table of the assets of a set — every `FileRef` of it, which is 124
in the Live 11 reference set — with the path as it is written, how the path was resolved, the
size Live recorded, the size on disk, where the file is, and when it was last changed. That
table is the evidence behind the sizes the report gives.

A hash of each file would be stronger evidence than a size: a file that has changed and keeps
its size would not be noticed by the size alone. The sets of the corpus are checked in, so the
hashes could be checked in as well, and a set could be compared with the copy that was taken.

What is open:

- Whether the report computes a hash of each asset at all. The cost is a read of every file
  the set draws on, and a set can draw on a whole library.
- Whether the hash is of the file as it is on disk, or of the content Live recorded. Live
  records a `CRC` of each sample — `OriginalCrc` — and what that CRC is a checksum of is not
  yet known, so it cannot be compared with a hash of the file without knowing what it covers.
- Whether the hashes are of the assets only, or of the set file as well. The set file has the
  two SHA-256 checksums the plan gives it: of the file, and of the content.

#### N59. Should the report carry a checksum of the tool that made it?

The report says what made it: the version of `live_set`, and where the tool is documented,
<https://www.mslinn.com/av_studio/ableton_live_set.html>. A report is evidence, and evidence
is stronger when the program that wrote it can be identified exactly.

What is open:

- Whether the report carries a checksum of the tool — of the gem, of the file it was run
  from, or of the model — and of what: the gem as installed, the working copy, or the
  version.
- Whether the checksum is of the tool or of the model, or of both.
- Whether it is wanted at all, given that the version of the tool is already in the report and
  the version is what identifies a release of the gem.

#### N60. The report should fold when a reader clicks a node

A reader of the report should be able to click on a node — an `<li>` element of the HTML
that the markdown becomes — and have the children of that node hidden. Clicking the node
again shows them again.

Clicking the name of a group folds the whole group: its tracks, their devices, their clips
and their take lanes all become invisible, and only the name of the group is left. Clicking
the name of a track folds that track and the things under it; clicking the name of a clip
folds it.

The default is the report in full: nothing is folded, and nothing is hidden, until the
reader folds it.

What it needs:

- The markdown has to become HTML that has the structure to fold: a list item for each
  track, group and clip, with the children of a node inside it.
- The folding needs a little JavaScript, or CSS alone — a `<details>` element folds its
  children without any script at all, and the report is read in a browser as often as it is
  read in an editor.

#### L1. Live ships its own schemas; use them

Every Live installation carries a directory of schemas of the format, one file
per format version, named after the `MinorVersion` of a set. They are Live's own
description of the format, and they are more complete than the XSDs this
repository infers from the demo sets: 114 of the element names in
`$live_reference_sets/xsd/vocab_live11.txt` are in Live's schema for 11.0 and cannot be in the
inferred one, because no Live 11 demo set contains them.

What is known is written down in `$live_reference_sets/docs/live_schemas.md`. What is left is to
settle whether the files give the nesting and the order of the children of an
element, whether every format version a set can name has a file, and what the
`Class` and `Type` attributes say about the values an element holds.

Then the version_diff documents should be rebuilt on them. The differences
between two versions are currently found by diffing two inferred schemas;
diffing two of Live's own would give them directly, and would give them for Live
8, Live 9 and Live 10 as well, which is the work of **D8**. The four final
schema files should be checked into `$live_reference_sets/xsd/`, so that a new contributor has
them without installing Live.
