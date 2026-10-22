# TODO

Outstanding work on `live_set`. This is a description of work in progress; when
an item is completed its entry is deleted, and anything worth keeping is written
up in `docs/als_format.md` or the code itself.


## Moderate

### M1. The `*_options.rb` files define conflicting global methods

Each of these defines a top-level `parse_options`, `do_parse` and (in two cases) `common`:

| File | Defines |
| --- | --- |
| `lib/live_set/live_set_options.rb:32,49` | `parse_options`, `do_parse` |
| `lib/als_delta/als_delta_options.rb:7,33,48` | `common`, `parse_options`, `do_parse` |
| `lib/generate_xsd/generate_xsd_options.rb:29,52` | `parse_options`, `do_parse` |

They are loaded lazily by `require_directory` inside each command function in `lib/live_set.rb`, so
whichever command runs last wins.

`common` is the worst case: it is defined twice with different bodies —
`lib/live_set.rb:6` and `lib/als_delta/als_delta_options.rb:7`. Neither is called anywhere, so both
are dead code that shadows one another. The `lib/als_delta` version calls `parse_options command`
with an argument, but no `parse_options` in the project accepts an argument, so the mismatch is
latent but a trap.

Additionally each file re-initializes the global `@loglevels` with the same
`unless defined?(@loglevels)` guard, so only the first one loaded has any effect.

Fix: scope each command's option parsing to a module or a class, or rename the methods per command
(`parse_live_set_options`, `parse_als_delta_options`, …). Deleting both `common` methods would
resolve the dead code on its own.


### M5. `als_delta` declares `--loglevel` as `Integer` but validates it as a String

`lib/als_delta/als_delta_options.rb:54` declares `parser.on('-l', '--loglevel LOGLEVEL', Integer, ...)`,
so the option yields an Integer. But the validation at line 43 does
`@loglevel.upcase.to_sym`, which raises `NoMethodError` on an Integer.

The other two commands declare the option as `String` (see `lib/live_set/live_set_options.rb:56` and
`lib/generate_xsd/generate_xsd_options.rb:57`), so `als_delta` is the odd one out.

Also, `lib/als_delta/als_delta_class.rb:12-13` builds a `zdiff` argument from the value:
`"-loglevel #{@options[:loglevel]}"`. `zdiff` accepts only `diff` options, and `diff` has no
`-loglevel` option, so the constructed command would fail regardless. The `-stats` flag appended on
line 13 is also a `diff` option that is not in POSIX `diff` (it is a GNU extension).


### M11. `LiveScene` is constructed but its data is never used

`lib/live_set/live_set_class.rb:46` builds `@scenes = @live_set.Scenes.map { |scene| LiveScene.new scene }`.
`@scenes` is never read again, and `LiveScene` (`lib/live_set/live_set_scene.rb`) only assigns
`@id`, `@name` and `@tempo` in its constructor — it exposes no readers, so the values are
unreachable. The whole class is effectively dead.


## Minor

### N8. `LiveTrack` exposes `clip_slots` but nothing consumes it

`lib/live_set/live_set_track.rb:7` declares `attr_reader :clip_slots`, set on line 24. No other
code reads it.


### N10. `LiveTracks#ready_for_p3s?` is dead code

`lib/live_set/live_set_live_tracks.rb:62-65`. The comment above it explicitly says it is "not used at
present, but it should be". `p3s_tx_msg` implements the same logic inline instead.


### N16. `LiveDevice::PLUGIN_MARKERS` is an unsorted list

`lib/live_set/live_device.rb:14-19` — the entries are grouped by plugin family rather than
alphabetised, and `ClapPlugin`/`PluginId` are on a shared line while the rest are not.


### N17. `LiveDevice#max_for_live?` regex mixes anchors and alternation

`lib/live_set/live_device.rb:43` — `/max\s*for\s*live|\bM4L\b|^Max\b/i`. The `^Max\b` alternative is
anchored to the start of the whole string, so a manufacturer/name like "X Max"
will not match, while `max for live` matches anywhere. Intent is unclear.


### N21. `LiveDevice` targets elements that do not exist in real sets — **LOW PRIORITY**

`LiveDevice` never matches anything, so the Push 3 Standalone "blocking device"
check never runs.  `lib/live_set/live_set_track.rb` finds devices with
`@audio_track.search('.//Device')`, but no real set has a `<Device>` element.
See `docs/als_format.md` section 8 for the evidence and the real structure.

**The fix:** rewrite the class against the real structure.

1. Find devices with `PluginDevice` rather than `Device`.
2. Get the name from `PluginDesc/VstPluginInfo/PlugName`.
3. Establish whether a `PluginDevice` is by definition a third-party plugin, or whether native
   Ableton devices also appear as `PluginDevice` elements. This is the crux: `blocking?` currently
   means "not made by Ableton", and if native devices also appear as `PluginDevice` then the whole
   Push 3 check is wrong, not just the element name. **This needs checking against sets that use
   native devices.**
4. With the manufacturer question settled, `value_of` can collapse into `xml_value` (see
   `lib/common/xml.rb`) plus at most one nested lookup.

`LiveDevice#value_of` keeps its own rules for now, and is the one reader of XML values that does not
use `xml_value`.


### N30. `LiveTrack#initialize` assumes `DeviceChain/MainSequencer/ClipSlotList` exist

`lib/live_set/live_set_track.rb:24` — `@clip_slots = @audio_track.DeviceChain.MainSequencer.ClipSlotList`
uses no safe navigation, unlike the `Log.debug` line above it, which does. A track without a
`DeviceChain` raises `NoMethodError` on `nil`. Write a unit test for a track without a `DeviceChain`
and verify expected results.


### N31. `LiveAudioClip#initialize` assumes `SampleRef` exists

`lib/live_set/live_set_audio_clip.rb:36` — `@file_ref = @audio_clip.SampleRef.FileRef` has no guard.
A clip without a `SampleRef` raises `NoMethodError` on `nil`.


### N36. `als_delta` compares against a backup, not the previous version

`lib/als_delta/als_delta_class.rb:43-58` — the loop backs up the current file and diffs the current
file against that backup, so the first iteration compares the file to itself. The help text says
"compare with previous version", which is accurate only from the second iteration onward.
