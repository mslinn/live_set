# TODO

Outstanding work on `live_set`. This is a description of work in progress; when
an item is completed its entry is deleted, and anything worth keeping is written
up in `docs/als_format.md` or the code itself.


## Moderate

### M11. `LiveScene` is constructed but its data is never used

`lib/live_set/live_set_class.rb:64` builds `@scenes = @live_set.Scenes.map { |scene| LiveScene.new scene }`.
`@scenes` is never read again, and `LiveScene` (`lib/live_set/live_set_scene.rb`) only assigns
`@id`, `@name` and `@tempo` in its constructor — it exposes no readers, so the values are
unreachable. The whole class is effectively dead.


## Minor

### N10. `LiveTracks#ready_for_p3s?` is dead code

`lib/live_set/live_set_live_tracks.rb`. The comment above it explicitly says it is "not used at
present, but it should be". `p3s_tx_msg` implements the same logic inline instead.


### N36. `als_delta` compares against a backup, not the previous version

`lib/als_delta/als_delta_class.rb:66-81` — the loop backs up the current file and diffs the current
file against that backup, so the first iteration compares the file to itself. The help text says
"compare with previous version", which is accurate only from the second iteration onward.


### N37. A frozen track's clips are reported twice over

A frozen track keeps both sequencers, and the same clip can appear in each. `live_set` now finds
the clips in both, so a track whose audio is in both sequencers is reported with the same file
counted once — `distinct_clips` de-duplicates by path — but the per-source clip counts are higher
than the number of distinct files, and the same file is listed under both the session view and the
arrangement.

For example, one frozen track in the corpus reports 13 session-view clips and 12 arrangement
clips, 25 clip objects in total, but only 14 distinct files.

This is not wrong, but it is confusing. The report should say which sequencer each clip came from,
or should report only the sequencer that is currently in effect: the `MainSequencer` for an
unfrozen track, the `FreezeSequencer` for a frozen one. See `docs/als_format.md` section 11.



### N40. A group's device chain is reported on the group, but the group is not reported on its members

A group track's devices are in its members' signal path, so a plug-in in a group's chain blocks a
transfer to Push 3 Standalone. `live_set` reports that as an error naming the group and the
tracks it affects.

It does not report the group on the member tracks. A track that is in a group with a plug-in is
reported as having no devices of its own, and the reader has to notice the separate error about
the group to know that the track is affected. The per-track advice line — "Track 'VOX 2' is
unfrozen; devices: ..." — omits the group's devices.

Whether the group's devices should also be listed against each member is a question about how the
report should read. See `docs/als_format.md` section 9.3.


### N41. A blocking device on a track that is in a group is reported twice

If a member track has a plug-in of its own, and its group has one too, the report has two errors
for the same track: one naming the track, and one naming the group. That is accurate, but it does
not make the relationship between them clear.


### N42. It is not known whether Live 11 tolerates a lane of an unknown `Type`

The conversion renames `MidiEditorLaneModel` to `ExpressionLane`, and that is all it does to the
lanes. But the two Live versions number their lanes differently within the same family, so a
converted set has lanes that Live 11 has no equivalent for:

| Live version | `ContentLanes` types | `ExpressionLanes` types |
| --- | --- | --- |
| 11 | 4, 5 | 0, 1, 2, 3 |
| 12 | 2, 3, 4 | 0, 1, 2, 3, 5 |

Every Live 11 demo set has the Live 11 set of lanes, and every Live 12 demo set has the Live 12
set, so the lanes are application state rather than a property of the music.

**What a round trip through `live_set -11` establishes.** The Live 11 demo set was opened in
Live 12 and saved, and converting that file back to Live 11 gives:

| | Live 11 original | Live 12 source | Round tripped |
| --- | --- | --- | --- |
| `Creator` | Ableton Live 11.3d1 | Ableton Live 12.4.6 | Ableton Live 11.3.21 |
| `MinorVersion` | `11.0_11300` | `12.0_12402` | `11.0_11300` |
| Lane element name | `ExpressionLane` | `MidiEditorLaneModel` | `ExpressionLane` |
| `Oversampling` values | 5 of `"1"`, 1 of `"0"` | 5 of `"true"`, 1 of `"false"` | 5 of `"1"`, 1 of `"0"` |
| Audio tracks | 14 | 14 | 14 |
| MIDI tracks | 14 | 14 | 14 |
| Group tracks | 1 | 1 | 1 |
| Clips | 255 | 255 | 255 |

The material is untouched, and the two elements that Live 12 spells differently are now spelled
the Live 11 way.

**What it does not establish.** The lanes are not reconciled, and there is no way to reconcile
them, because the `Type` values are not portable: there is no mapping from a Live 12 lane to a
Live 11 lane, since the two versions number them differently within the same family. The
round-tripped file therefore has three lanes Live 11 has never seen, and has lost one that it
has:

| | Live 11 original | Round tripped | |
| --- | --- | --- | --- |
| `ContentLanes` | 4, 5 | 2, 3, 4 | `Type` 2 and 3 are unknown to Live 11; `Type` 5 is lost |
| `ExpressionLanes` | 0, 1, 2, 3 | 0, 1, 2, 3, 5 | `Type` 5 is unknown to Live 11 |

**The test has been run, and the answer is no.** The round-tripped file was opened in Live 11
Suite 11.3.43, and Live 11 **crashed** on it:

> A serious program error has occurred.
> Live will shut down after this message box is closed.

This is the file produced by the current code, which **translates** the lanes rather than
removing them. Its contents at the time of the crash were:

| | |
| --- | --- |
| `Creator` | Ableton Live 11.3.21 |
| `MinorVersion` | `11.0_11300` |
| `ContentLanes` | 3 × `ExpressionLane`, `Type` 2, 3, 4 |
| `ExpressionLanes` | 5 × `ExpressionLane`, `Type` 5, 0, 1, 2, 3 |
| `Oversampling` | 5 of `"1"`, 1 of `"0"` |
| `InstrumentMeld`, `Roar`, `MxPatchRef` | none |
| Tracks and clips | 14 audio, 14 MIDI, 1 group, 255 clips |

**So neither of the two possible treatments works.** Removing the lanes crashes Live 11, and
translating them crashes Live 11 too, because the translated file still has lanes of an unknown
`Type`.

Live 11's own log records the crash:

```
2026-10-22T16:22:56.753332: info: Default App: Begin ExchangeDocument
2026-10-22T16:22:58.144252: info: Exception: Windows Exception
2026-10-22T16:22:58.144280: info: Exception: Fatal Error: Unhandled exception
```

The load got as far as `Begin ExchangeDocument`, and the exception followed a second later. For
contrast, the original Live 11 demo set loads cleanly, through `Begin ExchangeDocument` and
`End ExchangeDocument`, with no exception.

**What the crash is caused by is not yet known.** The `Type` values are the obvious suspect,
but the file also differs from a Live 11 set in other ways — the `Creator` says 11.3.21 rather
than 11.3d1, the `Revision` hash is one the current code hardcodes, and `SchemaChangeCount` is
`3`. A crash in `Begin ExchangeDocument` could be any of these. **The conversion is not yet
known to produce a set that Live 11 can open**, and until it does, N42 is not closed.

**Reproducing the test.** The round-tripped file is produced from the Live 12 version of the
Live 11 demo set, which lives in a Project folder beside the Live 11 demo sets:

```shell
$ cd "/mnt/c/ProgramData/Ableton/Live 11 Suite/Resources/Core Library/Lessons/Demo Songs"
$ live_set -11 -f "Ninajirachi - In The Rain (Live 11 Suite Demo) converted to Live 12 Project/Ninajirachi - In The Rain (Live 11 Suite Demo) converted to Live 12.als"
```

That writes `…converted to Live 12_11.als` in the same folder. The `-f` is needed only because
the file has already been written once; without it the command stops and leaves the existing
file alone.

To open it in Live 11 and see the crash, run the executable directly:

```shell
$ "/mnt/c/ProgramData/Ableton/Live 11 Suite/Program/Ableton Live 11 Suite.exe" \
    "Ninajirachi - In The Rain (Live 11 Suite Demo) converted to Live 12 Project/Ninajirachi - In The Rain (Live 11 Suite Demo) converted to Live 12_11.als"
```

Live writes its own log, which records the load and the exception:

```
~/AppData/Roaming/Ableton/Live 11.3.43/Preferences/Log.txt
```

See `docs/als_format.md` sections 2.4 and 2.5.


### N43. A `FakeGroup` element has been claimed but never found

There is a claim that the `.als` format uses a `<FakeGroup>` element — a phantom routing target
that wraps a group inside another group. No such element has been found in any set examined:
460 sets, the 61,000-line `evasiva.xml` test file in `pyableton`, and the source of five
`.als`-parsing projects. The specific elements the claim names — `TrackWrapperType` and
`RoutingTarget` — are also absent.

A nested group and a top-level group have identical child elements, which is the strongest
evidence against a structural wrapper.

This is recorded as an open question rather than a settled one, because the corpus is one
person's collection. **A set containing a `FakeGroup` element would settle it.** See
`docs/als_format.md` section 9.2.1.
