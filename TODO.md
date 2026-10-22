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

**What a round trip through `live_set -11` establishes.** Converting the Live 12 version of the
Live 11 demo set back to Live 11 produces a file that is a Live 11 set in every respect that can
be checked without Live 11:

- the `Creator` and `MinorVersion` are Live 11's,
- the lanes are named `ExpressionLane`, as Live 11 names them,
- the `Oversampling` values are `"1"` and `"0"`, in the same tally as the original Live 11 file —
  5 of `"1"` and 1 of `"0"`,
- the tracks, the clips and the group are all the same: 14 audio tracks, 14 MIDI tracks, 1 group
  track and 255 clips.

**What it does not establish.** The round-tripped file has `ContentLanes` of `Type` 2 and 3, and
an `ExpressionLanes` of `Type` 5. Live 11 has no lanes of those types, so the file contains
lanes Live 11 has never seen, and it has lost Live 11's `ContentLanes` of `Type` 5.

**The question that is still open:** does Live 11 open a set with a lane of an unknown `Type`
without complaint, and if it does, what does it do with that lane?

**The test that answers it:** open the round-tripped file in Live 11 and look at the lanes. The
file is produced by converting the Live 12 set, which is inside a Project folder beside the
Live 11 demo sets:

```shell
$ cd "/mnt/c/ProgramData/Ableton/Live 11 Suite/Resources/Core Library/Lessons/Demo Songs"
$ rake install     # in the live_set repository, so the command runs the current code
$ live_set -11 "Ninajirachi - In The Rain (Live 11 Suite Demo) converted to Live 12 Project/Ninajirachi - In The Rain (Live 11 Suite Demo) converted to Live 12.als"
```

That writes `…converted to Live 12_11.als` in the same folder.

**A first attempt crashed Live 11**, and the reason is worth recording. That attempt was made
with a `live_set` that removed the lanes entirely rather than translating them, and Live 11
crashed with "A serious program error has occurred" on opening the result. So **removing the
lanes is not an option** — Live 11 does not tolerate a set with no `ContentLanes` and no
`ExpressionLanes` any more than it tolerates one with lanes of an unknown `Type`.

The file produced by the current code, which translates rather than removes, has been written
and has not been opened in Live 11 yet. That is the test:

```shell
$ cd "/mnt/c/ProgramData/Ableton/Live 11 Suite/Resources/Core Library/Lessons/Demo Songs"
$ live_set -11 -f "Ninajirachi - In The Rain (Live 11 Suite Demo) converted to Live 12 Project/Ninajirachi - In The Rain (Live 11 Suite Demo) converted to Live 12.als"
```

It writes `…converted to Live 12_11.als` beside the set it was given. The file has the Live 11
version strings, the lanes are named `ExpressionLane`, the `Oversampling` values are 5 of `"1"`
and 1 of `"0"`, and the tracks, clips and group are unchanged. The lanes are `ContentLanes` of
`Type` 2, 3 and 4, and an `ExpressionLanes` of `Type` 5 — the unknown ones.

See `docs/als_format.md` section 2.4.


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
