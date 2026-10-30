# TODO

The outstanding work of the `live_set` gem, and nothing else.

Every item has an identifier, and the identifiers are stable: the code, the
specs and the documents cite them, so an identifier is never reused, and it
never changes what it means. When an item is completed its entry is deleted,
and anything worth keeping is written up in another Markdown file in `docs/`
and/or the code itself.

The plan for the Live 12 → Live 11 conversion is `docs/fix_plan2.md`. That
document holds the steps of that plan and the work list of the down direction.
This file holds the outstanding work of the gem as a whole, and the two overlap
where an item belongs to the conversion: **T1** is the contract the conversion
has to meet, and **N42** is the lane `Type` risk the conversion carries. Such
an item is described here, and the plan and the code refer to it by its
identifier.

This project was developed for WSL, which implies Windows 10 or 11.
It performs round-trip validation of Live 11 -> Live 12 -> Live 11 sets
using `live_set -11`, followed by running Ableton Live under Windows.


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

The `live_set -11` converter is incomplete and has bugs. The documentation has
errors and omissions. See TODO and FIXME comments.


#### GH1. Real round-trip equivalence

The round-trip test should assert more than `no error` and `End
ExchangeDocument`; it should confirm the converted set opens cleanly, preserves
structure, and does not trigger restore or crash behavior.

#### GH2. Recovery-state fixtures

The harness and parser should be pinned against real recovery and crash cases,
including clean exits, restore prompts, recovery-file moves, and `Restore
Document: Rejected by the user` behavior.

#### GH3. Outcome model and dialog matrix

The harness result model should consistently report `loaded`, `crashed`,
`blocked`, or `unknown`, and each dialog family should correspond to a known
dismiss action and pass/fail classification.

### Other open project work

#### T1. XML-level validation of the Live 11 conversion

The conversion contract should be made explicit by asserting the supported lane types, the expected `ContentLanes` and `ExpressionLanes` structure, and the required absence of unsupported Live 12-only nodes.

#### T5. Tighten conversion check names and scope

The existing specs should be organized around the exact contract they prove: conversion output, Live compatibility, or harness parsing.

#### M11. `LiveScene` dead data path

`LiveScene` is constructed but never used in a meaningful way. This is dead code and should either be removed or turned into a real part of the model.

The class also reads its values the way Slop reads them — `@live_scene.Name`,
`@live_scene.Tempo` — so it only works on an element of a Slop-decorated
document. `LiveSet` decorates the document it reads, so the class works
there, and it raises `NoMethodError` on an element of a plain Nokogiri
document. If the class is kept, it should read its values with `at(...)`, the
way every other class in the gem does.

#### N53. The corpus holds no case for some of what the code has to read

The reporting-model examples read real sets. A case that no set in the
corpus holds is made by copying a real element and changing one value in it,
which is as close to the real thing as the corpus allows. The cases that are
made that way are these, and each of them is a path the code takes that no
real set exercises:

- a frozen track, and a track whose clips are only in its `FreezeSequencer`.
  Every track of every set in the corpus is unfrozen, and every
  `FreezeSequencer` of every track is empty.
- a plug-in nested in a group branch. The corpus holds one group branch, and
  the devices in it are native ones.
- a VST2 plug-in. The only plug-in in the corpus is a VST3 one, so the
  `PluginDesc/VstPluginInfo/PlugName` path is not read by any example.
- a native device with a `Name` element of its own. Every native device in
  the corpus has no `Name`, so its name is the name of the element it is
  written as.
- a `Manufacturer` element. No element in the corpus has one, so the
  manufacturer part of a device's label is never read.
- a clip with no `SampleRef`, and a clip whose `LastModDate` is zero or
  absent.
- a track with no `DeviceChain`.
- a scene with a tempo of its own. Every scene in the corpus has
  `IsTempoEnabled` false.

The work is to get sets that hold these cases: a set with a frozen track, a
set with a VST2 plug-in, and a set with a scene that has a tempo. Live 8 and
Live 9 hold VST2 plug-ins, and their demo sets are not on this machine yet;
the documents say they can be generated, and that has not been done.

#### N36. `als_delta` compares against a backup, not the previous version

The first comparison is effectively against itself because the backup logic does not compare against the prior version in the first run.

#### N10. `LiveTracks#ready_for_p3s?` dead code

This helper is defined but not used; the inline `p3s_tx_msg` logic already covers the relevant behavior.

#### N37. Frozen-track clip reporting is confusing

The same clip can be encountered through both sequencers and reported more than once. The distinction between source and distinct files should be clarified.

#### N40. Group device chain reporting is incomplete

A group-level device blocking condition is reported on the group, but not on the member tracks that inherit the same signal path.

#### N41. Blocking device on group member is counted twice

A device on both a track and its group results in duplicated reporting for the same underlying problem.

#### N42. Unknown lane `Type` values may crash Live 11

The Live 12 lane numbering is not portable to Live 11, and the round-tripped set keeps lane `Type` values that Live 11 does not understand. This is the main unresolved compatibility risk.

#### N43. `FakeGroup` remains unverified

The claim that a `FakeGroup` routing wrapper exists has not been confirmed from the corpus examined so far.

#### N50. Known crash path missing as a failing regression

The current Live 11 crash behavior should be captured as a compact failing regression fixture before treating a fix as complete.

#### N51. The Push 3 transfer message and the frozen marker have no coverage

The examples that covered `LiveTracks#p3s_tx_msg` and `LiveTrack#show_track` were built out of
stand-ins for `LiveTrack`, `LiveGroup`, `LiveDevice` and `LiveAudioClip`, and out of objects whose
instance variables were set by hand. They were deleted: a stand-in is not the thing it stands in
for, and an object assembled out of parts does not test the constructor.

Neither method is covered now.

`p3s_tx_msg` has to be tested against a real set that has the three things it reports: a clip that
has not been collected, a third-party device on a track that is not frozen, and a third-party
device in the chain of a group. The demo sets are the source of those, and `sets/live_11/` holds
the sets that were checked in.

`show_track` says whether a track is frozen, and a group track cannot be frozen, so the two have
to be told apart. The demo sets have both.

#### N52. The Live 12 version of the Live 11 demo set is not checked in

The round trip needs three files: a set Live 11 wrote, the same set as Live 12 wrote it, and
the set this gem writes when it converts the second one back to the Live 11 format. The second
file has to be made by opening the first in Live 12 and saving it, and it has to be checked in,
so that anyone can run the round trip without opening Live 12.

The conversions directory holds the Live 12 version of the Live 11 Suite demo set, and the
directory is in `.gitignore`. The file is therefore not checked in, and a fresh clone has no
Live 12 set to convert back. The round trip examples cannot run at all.

The file is also not the one the round trip wants. The Live 11 Suite demo set is the largest
of the Live 11 demo sets by content — 14 tracks, a group track, 255 clips, 219 of them in the
arrangement, 6 `Oversampling` elements — but the Live 11 Intro demo set is larger as a file,
and it has clips in take lanes, which the Suite demo set does not have.

The work is to open the Live 11 demo set in Live 12, save it, and check the result in.

The reference sets for Live 11 and Live 12 are both checked in:
`sets/live_11/Fascination.als` and the Live 12 version of it,
`sets/live_12/Fascination_12_converted_by_live Project/Fascination_12_converted_by_live.als`.
The Live 12 version was made by `bin/make_reference_set`, which opens the Live 11 set in
Live 12, waits for Live to say that it has loaded it, and saves it under a name of its own.
The conversion of the second down to the Live 11 format is proved in
`spec/live_set/tx/live_12_fascination_down_spec.rb`. It
is a set by a user of Live rather than a demo set, so the demo set is still wanted: the demo set
is the one whose structure the schema was inferred from, and the Live 12 version of it is what
the round trip opens in Live 11.

#### L1. Live ships its own schemas; use them

Every Live installation carries a directory of schemas of the format, one file per format version, named after the `MinorVersion` of a set. They are Live's own description of the format, and they are more complete than the XSDs this repository infers from the demo sets: 114 of the element names in `schemas/vocab_live11.txt` are in Live's schema for 11.0 and cannot be in the inferred one, because no Live 11 demo set contains them.

What is known is written down in `docs/live_schemas.md`. What is left is to settle whether the files give the nesting and the order of the children of an element, whether every format version a set can name has a file, and what the `Class` and `Type` attributes say about the values an element holds.

Then the version_diff documents should be rebuilt on them. The differences between two versions are currently found by diffing two inferred schemas; diffing two of Live's own would give them directly, and would give them for Live 8, Live 9 and Live 10 as well, which is the work of **D8**. The four final schema files should be checked into `schemas/`, so that a new contributor has them without installing Live.
