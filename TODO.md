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

This is not wrong, but it is confusing. The report should say which sequencer each clip came from,
or should report only the sequencer that is currently in effect: the `MainSequencer` for an
unfrozen track, the `FreezeSequencer` for a frozen one. See `docs/als_format.md` section 11.


### N39. The `-11` conversion does not check that the result can be read by Live 11

`lib/live_set/live_set_class.rb` writes the Live 11 version strings and removes the Live 12-only
elements it knows about. It does not verify that what remains is valid for Live 11, and it does
not check the schema of the result.

`generate_xsd` and `validate_asd` can be used together to check a set against a schema, but
there is no Live 11 schema in the repository to check against. The `after_real_pain.xsd` file
describes a Live 12 set and is known to be wrong about the shape of values — see
`docs/als_format.md` section 3.


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
