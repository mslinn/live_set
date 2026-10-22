# TODO

Inconsistencies found while reviewing the structure and implementation of `live_set`.

Severity key: **Severe** = the code is broken or will produce wrong results; **Moderate** = works but
contradicts another part of the project or is likely to break; **Minor** = cosmetic or inconsistent
style. Minor issues are reported but were deliberately not acted on.

---

## Severe

### S3. `define_audio_clips` relies on Slop accessors whose shape varies by Live version and by child count

**No change made — recommendations only, per instruction.**

#### The defect

`lib/live_set/live_set_audio_track.rb:34-36`:

```ruby
clip_slots.ClipSlot.filter_map do |clip_slot|
  inner = clip_slot.ClipSlot || clip_slot
```

Two separate Slop behaviours combine badly here.

**(a) The return type of a Slop accessor depends on how many matching children exist.**
`Nokogiri::Decorators::Slop#method_missing` (`slop.rb:19-36`) does:

```ruby
list = xpath("./#{name}")
super if list.empty?
list.length == 1 ? list.first : list
```

So a Slop accessor returns:

- a **single `Nokogiri::XML::Element`** when exactly one child matches,
- a **`Nokogiri::XML::NodeSet`** when two or more match,
- and raises `NoMethodError` when none match (via `super`).

> **Correction:** an earlier revision of this report stated the 2+ case returns a plain Ruby
> `Array`. That is wrong — `xpath` returns a `NodeSet`, and `NodeSet` *does* respond to
> `filter_map` and yields child elements. The `Array` in the error messages comes from
> `Nokogiri::XML::Node#each`, which yields `[name, value]` **attribute pairs** (see
> `Nokogiri::XML::PP::Node#each`). The behaviour matrix below is the verified one.

The verified matrix, confirmed by `spec/live_set/live_set_audio_track_clip_slots_spec.rb`:

| Layout | Clip slots | `clip_slots.ClipSlot` returns | `filter_map` iterates | Result |
| --- | --- | --- | --- | --- |
| Live 8 (nested) | 0 | raises `NoMethodError` | — | raises at line 34 |
| Live 8 (nested) | 1 | `Element` | attribute pairs | raises at line 36 (`Array`) |
| Live 8 (nested) | 2+ | `NodeSet` | child elements | **works** |
| Live 12 (flat) | 0 | raises `NoMethodError` | — | raises at line 34 |
| Live 12 (flat) | 1 | `Element` | attribute pairs | raises at line 36 (`Array`) |
| Live 12 (flat) | 2+ | `NodeSet` | child elements | raises at line 36 (nested accessor) |

The single-slot case fails because `Nokogiri::XML::Node` includes `Enumerable` (via
`Nokogiri::XML::PP::Node`) whose `#each` yields `[name, value]` attribute pairs, not child
elements — so `filter_map` receives `[name, value]` arrays and line 36 calls `.ClipSlot` on one.

**(b) The Live 8 vs Live 12 nesting difference is handled by a fallback that is itself
fragile.** The two layouts are:

Live 8 (per `als_notes.md:279-283`):

```xml
<ClipSlot Id="14">
  <LomId Value="0"/>
  <ClipSlot>
    <Value>
      <AudioClip .../>
    </Value>
  </ClipSlot>
</ClipSlot>
```

Live 12 (flat):

```xml
<ClipSlot Id="14">
  <LomId Value="0"/>
  <Value>
    <AudioClip .../>
  </Value>
</ClipSlot>
```

The current code guesses with `inner = clip_slot.ClipSlot || clip_slot`. Because `clip_slot.ClipSlot`
is a Slop accessor, in the Live 8 case with 2+ slots it returns the nested `<ClipSlot>` element
(single match) — correct. In the Live 12 case it raises `NoMethodError` (no matching child) rather
than returning `nil`, so the `||` fallback never runs; the `NoMethodError` propagates. The fallback
is therefore unreachable in exactly the case it was written for.

Note also that the two layouts hand `LiveAudioClip` *structurally different* nodes: for Live 8 the
nested `<ClipSlot>` element, for Live 12 the outer `<ClipSlot>` element. `LiveAudioClip` then
assumes a `<Value>` child directly beneath whatever it is given
(`lib/live_set/live_set_audio_clip.rb:31` — `clip_slot.Value.AudioClip`). Resolving the `Value`
container once, in a layout-independent way, is the deeper fix.

#### Why the fix should probe the document rather than branch on the Live version

The user is right that the schema changed between Live 8.6 and Live 12. Two strategies:

1. **Branch on a version marker** (e.g. read `MinorVersion` and compare to "11." / "12."). This
   couples the parsing code to a version table and breaks on any future layout change or on
   mid-version quirks.
2. **Probe the structure** — inspect the actual node the code is holding and descend accordingly.

Strategy 2 is the recommendation: the parent/child shape of the `ClipSlot` element tells you
unambiguously which layout you are in, without any version knowledge.

#### Recommended approach

**Step 1 — stop using Slop accessors for the slot list; use XPath, which always returns a
`NodeSet`.**

```ruby
@clip_slots = @audio_track.DeviceChain.MainSequencer.ClipSlotList
```

`xpath` returns a `Nokogiri::XML::NodeSet` regardless of match count, and `NodeSet#each` yields
child *elements* (not attribute pairs), so iteration is uniform. Concretely:

```ruby
def clip_slot_elements(clip_slots)
  return [] if clip_slots.nil?

  clip_slots.xpath('./ClipSlot')
end
```

This alone removes both failure modes in (a) — the `Array` return type and the `Node#each`
attribute-pair iteration.

**Step 2 — select the `<Value>` container by probing children, not by guessing.**

Instead of `clip_slot.ClipSlot || clip_slot`, descend based on what the slot actually contains:

```ruby
# Live 8 nests the payload in a second <ClipSlot>; Live 12 puts it directly in the slot.
def value_node(clip_slot)
  nested = clip_slot.at('./ClipSlot')       # Live 8
  return nested.at('./Value') if nested     # may be nil if Live 8 slot is empty

  clip_slot.at('./Value')                   # Live 12
end
```

`at` returns `nil` when there is no match, so this handles both layouts and the "empty slot" case
uniformly. Note that `at('./ClipSlot')` is a *direct-child* XPath, so it will not accidentally match
a deeper `ClipSlot` elsewhere in the tree.

**Step 3 — decide whether a slot holds a clip by looking for the `AudioClip` element.**

The current guard is:

```ruby
next unless inner.respond_to?(:Value) && inner.Value && !inner.Value.children.empty?
```

`respond_to?(:Value)` is a Slop-ism that is true for any Slop-decorated node regardless of whether
a `<Value>` child exists, and `!inner.Value.children.empty?` is true for a `<Value>` containing only
whitespace text. Both are weak proxies for "this slot has a clip". The real question is whether the
slot contains an `<AudioClip>`:

```ruby
value = value_node(clip_slot)
next if value.nil?

audio_clip = value.at('./AudioClip')
next if audio_clip.nil?
```

**Step 4 — pass the `AudioClip` node (or the `Value` container) to `LiveAudioClip` in a
layout-independent way.**

`lib/live_set/live_set_audio_clip.rb:31` currently does `@audio_clip = clip_slot.Value.AudioClip`,
i.e. it assumes the `Value` container is exactly one level below whatever it is handed. If Step 2
resolves the `Value` node in a layout-agnostic way, the cleanest contract is to hand
`LiveAudioClip` the `AudioClip` node itself, and let it find `SampleRef` beneath it. That removes
the `Value` assumption from the clip class entirely.

Alternatively, keep the current contract (hand it the `Value` container) and just make sure
`define_audio_clips` always passes the *same* node for both Live versions — i.e. resolve the
`Value` element in Step 2 and pass that, rather than passing the outer slot for Live 12 and the
inner slot for Live 8. The current code passes the inner `<ClipSlot>` for Live 8 and (were it
reachable) the outer slot for Live 12, so the two layouts hand the clip class *structurally
different* nodes. That inconsistency is the deeper problem; making `define_audio_clips` always
pass a `Value` container fixes it.

**Step 5 — note the other slot lists that exist in the format.**

Per `als_notes.md:50-51`, `<ClipSlotList>` also appears under `FreezeSequencer` and `Mixer`, and
`als_notes.md:38` notes that the `MainSequencer` one is the one intended. The current code only
reads `DeviceChain.MainSequencer.ClipSlotList`, which is the right choice, but a comment recording
that the other two are deliberately excluded would help.

#### Additional observations

- **`LiveAudioClip` has the same class of problem.** `lib/live_set/live_set_audio_clip.rb:31-33`
  chain `clip_slot.Value.AudioClip`, `.SampleRef.FileRef`, `.LastModDate['Value']` with no guards.
  If the `AudioClip` or `SampleRef` element is absent (MIDI clips, empty slots, Live 8 variants),
  these raise `NoMethodError` on `nil`. The defensive-nil approach described in Step 3 should be
  applied here too — the clip class should tolerate a missing `SampleRef` and report the clip as
  having no file, rather than aborting the whole report.
- **Related: `LiveAudioClip` does not find `AudioClip` elements that Live 12 moved out of
  `ClipSlot`.** Its own comment (`lib/live_set/live_set_audio_clip.rb:24-28`) states that Live 12
  moved `<AudioClip>` into `TakeLanes/TakeLane/ClipAutomation/Events/AudioClip` and
  `DeviceChain/MainSequencer/Sample/ArrangerAutomation/Events/AudioClip`. If clips really live
  there in Live 12, then the flat `<ClipSlot><Value><AudioClip>` form used by the current code is
  the Live 8 form, and the Live 12 location needs its own lookup. **This should be confirmed
  against a real Live 12 set before implementing** — it is the one question the notes raise that
  the current code does not answer.
- **A regression test would be worth adding here.** A small fixture `.als` (gzipped XML) covering
  the Live 8 nested form, the Live 12 flat form, an empty slot, and a track with 2+ slots would
  pin the behaviour down. **This has now been done** — see `spec/live_set/live_set_audio_track_clip_slots_spec.rb`,
  which encodes the whole matrix above. The examples that currently fail are marked `pending` with
  the reason, so the suite stays green while the defect is tracked; RSpec will flag any of them
  that starts passing unexpectedly.

  The spec also surfaced a **separate** defect that was not previously in this report: the
  "reads the sample path from each clip" example returns `["", ""]` instead of the expected
  relative paths. That is M9 (the `.text` vs `Value` attribute mismatch) and it is now marked
  pending with an M9 reference.

#### Specs that pin this down

| Spec | Covers |
| --- | --- |
| `spec/live_set/live_set_track_clip_slots_spec.rb` | The Live 8 nested layout, the Live 12 flat layout, and the zero-slot case, at one and at 2+ slots (S3, M9) |
| `spec/live_set/live_set_track_spec.rb` | `#frozen?` (S2) |
| `spec/live_set/live_set_track_show_track_spec.rb` | The frozen marker in `#show_track` (S2) |
| `spec/common/run_spec.rb` | Exit-status handling (S4) and line-structure preservation (S5) |
| `spec/spec_helper.rb` | The fixtures, plus `FakeClip` |

`spec/spec_helper.rb` provides the fixtures:

- `audio_track_element(clip_slots:, freeze:)` — builds a Slop-decorated document with one
  `AudioTrack`.
- `clip_slot_xml(nested:, id:, relative_path:)` — builds a `<ClipSlot>` in either the Live 8
  nested or the Live 12 flat layout.

The fixtures are built in memory rather than loaded from a gzipped `.als` file, so the specs stay
fast and do not need binary fixtures. If a real-world `.als` is added later, a spec that parses it
would be worth having, to confirm the fixtures match reality.

The S2, S4 and S5 specs were verified to **fail** when the corresponding fix is reverted, so they
genuinely detect the defects rather than merely passing.


---

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


### M8. `expand_env` does not expand the `$NAME` form it appears to support

`lib/common/util.rb:24`:

```ruby
gsub(/\$([a-zA-Z_][a-zA-Z0-9_]*)|\${\g<1>}|%\g<1>%/) do
  ENV.fetch(Regexp.last_match(1), nil)
end
```

The alternation binds `\g<1>` to the *first* capture group, which only exists in the first
alternative. In the `${NAME}` and `%NAME%` alternatives the group is unset, so `Regexp.last_match(1)`
is `nil` and `ENV.fetch(nil, nil)` returns `nil` — the variable is replaced with an empty string
rather than its value.

This means the documented `PATH_TO_ALS_FILE` expansion (README and every help message) only works
for the `${NAME}` and `%NAME%` forms and silently produces empty strings for the plain `$NAME` form.
An undefined variable is likewise silently replaced with an empty string rather than being reported.

### M9. `LiveAudioClip` reads paths with `.text` but the documented format uses `Value` attributes

`lib/live_set/live_set_audio_clip.rb:44-48` selects
`@file_ref.at('RelativePath/RelativePath/Path') || @file_ref.at('RelativePath')` and reads
`.text`.

The comment block at lines 8-15 states that Live 8 uses `Value` attributes
(`<RelativePath Value="Samples/Imported/song1.mp3" />`) and that `.text` is required because paths
are nested text nodes. But `als_notes.md:356` shows the Live 8 format as an *attribute*:

```xml
<RelativePath Value="Samples/Imported/song1.mp3" />
```

For that shape, `at('RelativePath')` returns the element and `.text` is `""` (attributes are not part
of `.text`), so `@relative_path` becomes empty and `collected?` returns false for every Live 8 clip.
The `RelativePath/RelativePath/Path` fallback covers the nested-text form but not the attribute form.

The two path-reading strategies in the file are not consistent with each other or with the notes.

### M10. `LiveAudioClip` stores `@absolute_path_xml` but the attribute is never exposed or used

`lib/live_set/live_set_audio_clip.rb:48` sets `@absolute_path_xml`, but the `attr_reader` list at
lines 3-5 does not include it, and no other code reads it. The value is passed straight into
`compute_absolute_path` on line 52, so the ivar is redundant.

### M11. `LiveScene` is constructed but its data is never used

`lib/live_set/live_set_class.rb:46` builds `@scenes = @live_set.Scenes.map { |scene| LiveScene.new scene }`.
`@scenes` is never read again, and `LiveScene` (`lib/live_set/live_set_scene.rb`) only assigns
`@id`, `@name` and `@tempo` in its constructor — it exposes no readers, so the values are
unreachable. The whole class is effectively dead.

### M12. `LiveAudioTrack#name` and `#show_track` read the track name differently

`lib/live_set/live_set_audio_track.rb:47-51` (`name`) uses a three-step fallback:
`Name/EffectiveName`'s `Value` attribute, then `Name`'s text, then `##{@id}`.

`#show_track` (line 71) instead uses `@audio_track.Name.EffectiveName['Value']` directly, with no
fallbacks. The two disagree for any track missing an `EffectiveName`, and `show_track` raises
`NoMethodError` on `nil` where `name` would have degraded gracefully.


## Minor

### N8. `LiveAudioTrack` exposes `clip_slots` but nothing consumes it

`lib/live_set/live_set_audio_track.rb:2` declares `attr_reader :clip_slots`, set on line 17. No other
code reads it.

### N10. `AllTracks#ready_for_p3s?` is dead code

`lib/live_set/live_set_all_tracks.rb:65-69`. The comment above it explicitly says it is "not used at
present, but it should be". `p3s_tx_msg` implements the same logic inline instead.

### N12. `AllTracks#p3s_tx_msg` has an unused variable

`lib/live_set/live_set_all_tracks.rb:31` — `has_errors` is set to `true` in the `blocking_devices`
loop, and the `next if ...` on line 45 can skip the `has_errors = true` on line 43, but the local
`iteration` variable in `check_ableton_project_info` is the clearer example:
`lib/live_set/live_set_class_private.rb:16` — `iteration` is incremented on line 17 and never read.

### N14. `LiveSet#modify_als` hard-codes the Live 11 version strings

`lib/live_set/live_set_class.rb:71-75` hard-codes `Creator`, `MajorVersion`, `MinorVersion`,
`Revision` and `SchemaChangeCount` for "Ableton Live 11.3.21". There is no configuration or
version-detection logic to choose these.


### N16. `LiveDevice::PLUGIN_MARKERS` is an unsorted list

`lib/live_set/live_device.rb:7-12` — the entries are grouped by plugin family rather than
alphabetised, and `ClapPlugin`/`PluginId` are on a shared line while the rest are not.

### N17. `LiveDevice#max_for_live?` regex mixes anchors and alternation

`lib/live_set/live_device.rb:46` — `/max\s*for\s*live|\bM4L\b|^Max\b/i`. The `^Max\b` alternative is
anchored to the start of the whole string, so a manufacturer/name like "X Max" will not match, while
`max for live` matches anywhere. Intent is unclear.

### N18. `generate_xsd` help text lists `-f` in the wrong format

`lib/generate_xsd/generate_xsd_options.rb:16` — "Options are: -f overwrite any existing xsd." The
other commands list options with a leading dash and consistent capitalisation.

### N21. `LiveDevice` targets elements that do not exist in real sets — **LOW PRIORITY**

`LiveDevice` never matches anything, so the Push 3 Standalone "blocking device" check never runs.

`lib/live_set/live_set_track.rb` finds devices with `@audio_track.search('.//Device')`. A survey of
40 sets in `$songs` found **zero** `<Device>` elements. The elements that exist are `<PluginDevice>`
(229 in 23 of the 40 files), which is a different element.

The rest of the class is written against a structure that these files do not use:

| What `LiveDevice` looks for | Occurrences in 40 sets |
| --- | --- |
| `<Device>` | 0 |
| `<PresetManifestV1>` | 0 |
| `<CurrentPreset>` | 0 |
| `<VstPlugin>`, `<VstPluginCategory>`, `<VstId>` | 0 |
| `<AudioUnitPlugin>`, `<AudioUnitPreset>`, `<AudioComponent>` | 0 |
| `<ClapPlugin>`, `<PluginId>` | 0 |
| `<VstPreset>` | 10, in one file |

The plugin name is not where the class looks for it. In a real set the name lives under
`PluginDesc`:

```xml
<PluginDevice Id="6">
  <Name Value=""/>
  <UserName Value=""/>
  <PluginDesc>
    <VstPluginInfo Id="0">
      <Path Value="C:/Program Files/VstPlugins/MeldaProduction/Pitch Shift/MAutoPitch.dll"/>
      <PlugName Value="MAutoPitch"/>
```

76 `VstPluginInfo` elements were found in the sample, with `PlugName` values such as
`"TDR VOS SlickEQ"` (38), `"MAutoPitch"` (24) and `"GTune"` (4). There is no `Manufacturer`
element at all — 76 of 76 are absent — so the current `@manufacturer` logic has no source.

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




### N22. `exe/` scripts use a `VO_DEBUGGING` environment variable

`exe/live_set`, `exe/als_delta`, `exe/generate_xsd` and `exe/validate_asd` all branch on
`ENV['VO_DEBUGGING']` to choose between `require_relative '../lib/live_set'` and `require 'live_set'`.
The name suggests a generic debugger switch but is specific to this project.

### N24. `after_real_pain.xsd` is untracked

The file exists in the working directory but `.gitignore` contains `*.xsd`, so it is not in version
control. It is a generated artifact from `generate_xsd`.

### N30. `LiveAudioTrack#initialize` assumes `DeviceChain/MainSequencer/ClipSlotList` exist

`lib/live_set/live_set_audio_track.rb:17` — `@clip_slots = @audio_track.DeviceChain.MainSequencer.ClipSlotList`
uses no safe navigation, unlike line 12 which does. A track without a `DeviceChain` raises
`NoMethodError` on `nil`. Write a unit test for a track without a `DeviceChain`
and verify expected results.

### N31. `LiveAudioClip#initialize` assumes `Value/AudioClip` exists

`lib/live_set/live_set_audio_clip.rb:31` — `@audio_clip = clip_slot.Value.AudioClip`, and line 32
dereferences `@audio_clip.SampleRef.FileRef` with no guard. The `define_audio_clips` filter checks
for `inner.Value` but not for `AudioClip` within it.

### N32. `LiveAudioClip#last_modified` assumes `LastModDate` exists

`lib/live_set/live_set_audio_clip.rb:33` — `@audio_clip.SampleRef.LastModDate['Value'].to_i`. If
`LastModDate` is absent this raises `NoMethodError` on `nil`.

### N33. `LiveAudioClip#show_clip` formats a time that may be epoch-zero

`lib/live_set/live_set_audio_clip.rb:88` — `@last_modified.strftime(...)`. If `LastModDate` is
missing, the rescue path is not taken and the method raises (see N32).


### N35. `generate_xsd` writes the XSD without checking the output directory exists

`lib/live_set.rb:52` — `File.write(@xsd_file, content)` raises `Errno::ENOENT` if the target
directory does not exist. The `generate_xsd` help text does not mention this.

### N36. `als_delta` compares against a backup, not the previous version

`lib/als_delta/als_delta_class.rb:43-58` — the loop backs up the current file and diffs the current
file against that backup, so the first iteration compares the file to itself. The help text says
"compare with previous version", which is accurate only from the second iteration onward.


## Severe

3. **S3** — `define_audio_clips` relies on Slop accessors whose return type varies by child count
   and whose Live 8 / Live 12 fallback is unreachable. **Open — recommendations only, see above.**
