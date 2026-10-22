# TODO

Inconsistencies found while reviewing the structure and implementation of `live_set`.

Severity key: **Severe** = the code is broken or will produce wrong results; **Moderate** = works but
contradicts another part of the project or is likely to break; **Minor** = cosmetic or inconsistent
style. Minor issues are reported but were deliberately not acted on.

---

## Severe

### S1. `FileUtils` is used but never required — **FIXED**

`lib/live_set/live_set_class.rb:90` calls `FileUtils.rm_f new_set_path` on the `-11 -f` (convert and
overwrite) path, but `lib/live_set/live_set_class.rb` does not `require 'fileutils'`. No file in the
`live_set` code path requires it either — only `lib/als_delta/als_delta_class.rb:2` does, and that is
only loaded by the `als_delta` command.

The `FileUtils` constant is therefore undefined when `live_set -11 -f` runs, which raises
`NameError: uninitialized constant FileUtils`. The write path is also reached when `--force` is not
supplied, but only the `rm_f` call needs `FileUtils`.

Fix: add `require 'fileutils'` to `lib/live_set/live_set_class.rb`.

### S2. `show_track` queries the wrong object for the frozen state — **FIXED**

`lib/live_set/live_set_audio_track.rb:72`:

```ruby
frozen = @audio_track.frozen? ? ' frozen'.green : ' **not frozen**'.yellow unless all_frozen || @audio_clips.empty?
```

`@audio_track` is a `Nokogiri::XML::Node`, not a `LiveAudioTrack`. `frozen?` is defined on
`LiveAudioTrack` (line 53) to return the parsed `@frozen` value, but on a Nokogiri node `frozen?`
resolves to `Kernel#frozen?`, which reports whether the *Ruby object* is frozen — it is always
`false` for a Nokogiri node.

Consequence: the per-track "frozen" / "**not frozen**" marker is never shown as frozen. A frozen
track is reported as "**not frozen**", and the class already exposes the correct `frozen?` method
that is never used here.

Fix: change `@audio_track.frozen?` to `frozen?` (or `@frozen`).

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
| `spec/live_set/live_set_audio_track_clip_slots_spec.rb` | The Live 8 nested layout, the Live 12 flat layout, and the zero-slot case, at one and at 2+ slots (S3, M9) |
| `spec/live_set/live_set_audio_track_spec.rb` | `#frozen?` (S2) |
| `spec/live_set/live_set_audio_track_show_track_spec.rb` | The frozen marker in `#show_track` (S2) |
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

### M3. `generate_xsd` calls itself with an error message

`lib/generate_xsd/generate_xsd_options.rb:47`:

```ruby
generate_xsd msg if @loglevel && !@loglevels.include?(@loglevel.upcase.to_sym)
```

This calls the *command* `generate_xsd` (defined in `lib/live_set.rb:34`) rather than the
`help_generate_xsd` helper. The same pattern exists in `lib/live_set/live_set_options.rb:44`
(`live_set msg`) and `lib/als_delta/als_delta_options.rb:43` (`help_als_delta msg` — this one is
correct). The two incorrect ones re-enter the command, which re-parses options and re-prints the
help, instead of showing the error message.

Fix: call `help_generate_xsd msg` and `help_live_set msg`.

### M4. `unless remaining` treats an empty array as truthy

`lib/generate_xsd/generate_xsd_options.rb:34,37` guard with `unless remaining`. `remaining` is an
`Array`; an empty array is truthy in Ruby, so the guard never fires. The subsequent
`remaining.shift` returns `nil`, and the "No XSD file name provided" / "No ALS file names provided"
messages are never shown.

Fix: use `if remaining.empty?` (or `if remaining.nil? || remaining.empty?`).

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

### M6. `als_delta` help text calls the command `ls_delta`

`lib/als_delta/als_delta_options.rb:15,18,27` use `ls_delta`, while the executable and everything
else use `als_delta`. The same text is copied into `README.md:138,141,150`.

### M7. `als_delta` help says "Press enter" but the code waits for any key

`lib/als_delta/als_delta_options.rb:16` says "Press enter to compare with previous version", but
`lib/als_delta/als_delta_class.rb:47` uses `$stdin.getch` and prints "Press any key to display the
changes to the Live set XML file, or press Esc to exit."

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

### M13. `Log` formatter's `FATAL` branch is unreachable

`lib/common/log.rb:14`:

```ruby
when 'FATAL' || 'UNKNOWN'
```

`'FATAL' || 'UNKNOWN'` evaluates to `'FATAL'` (a non-empty string is truthy), so `'UNKNOWN'` is
never matched. Since `when` uses `===` against the severity string, `'UNKNOWN'` falls through to the
`else` branch and is coloured green rather than red.

Fix: `when 'FATAL', 'UNKNOWN'`.

### M14. `human_file_size` depends on `ByteSize` without requiring it — **FIXED**

`lib/common/util.rb:29` calls `ByteSize.new(number)`, but `lib/common/util.rb` did not
`require 'bytesize'`. It happened to work because `lib/live_set/live_set_class.rb:1` requires it, but
`lib/common/util.rb` was not self-contained.

Fix: add `require 'bytesize'` to `lib/common/util.rb`.

### M15. `gemspec` looks for `LICENSE.*` but the file is `LICENCE.txt` — **FIXED**

`live_set.gemspec:23` includes `Dir[..., 'LICENSE.*', ...]`. The repository contained `LICENCE.txt`
(British spelling), so the licence file was not included in the built gem. The `Dir[]` glob simply
matched nothing.

Fix: rename `LICENCE.txt` to `LICENSE.md` and convert it to proper markdown. The gemspec glob
already matches it, and `README.md` now links to `LICENSE.md`.

---

## Minor

Reported for completeness; no action taken.

### N2. `help_validate_asd` promises environment variable expansion that is not implemented

`lib/validate_asd/validate_asd_options.rb:13` says "Environment variables used in PATH_TO_ALS_FILE
are expanded", but `lib/live_set.rb:59-74` (`validate_asd`) does not call `expand_env` — it uses the
raw `ARGV` values. The other three commands do call `expand_env`.

The new `validate_asd` command was written during this session and is included for completeness.

### N3. `LiveSet#show` prints version information twice

`lib/live_set/live_set_class.rb:28-32` prints `Ableton version`, `Creator` and `SchemaChangeCount`
from the constructor, and `#show` (lines 51-58) prints `Created by`, `Major version`,
`Minor version`, `SchemaChangeCount` and `Revision`. `Creator` and `SchemaChangeCount` are
duplicated. The constructor's output is not suppressed when `modify_als` runs, so the conversion
path prints both blocks too.

### N4. `LiveSet#initialize` prints unconditionally

The `puts` at `lib/live_set/live_set_class.rb:28` is in the constructor rather than in `show`, so
output is emitted as a side effect of construction, before the caller decides what to do.

### N5. `LiveSet#modify_als` calls `exit` with no status

`lib/live_set/live_set_class.rb:68` — `exit` is equivalent to `exit 0` (success). It is arguably
correct here ("nothing to do" is not an error), but it is inconsistent with the explicit
`exit 1` used in `lib/live_set.rb:73`.

### N6. `LiveSet#initialize` uses `readlines` then joins with `"\n"`

`lib/live_set/live_set_class.rb:21` — `Zlib::GzipReader.open(set_name, &:readlines)` followed by
`@contents.join("\n")` at line 23. Because `readlines` already keeps the trailing newlines, the
join inserts an extra newline between every line, so the parsed document has blank lines between
all elements. `Zlib::GzipReader.open(set_name, &:read)` avoids this. The same pattern is in
`lib/generate_xsd/generate_xsd.rb:25-26`.

### N7. `LiveAudioTrack` has both `frozen` and `frozen?`

`lib/live_set/live_set_audio_track.rb:2` declares `attr_reader :frozen` and line 53 defines
`frozen?` returning the same value. Two names for one attribute; `AllTracks#all_frozen?` calls
`&:frozen` while `LiveAudioTrack#frozen?` exists — inconsistent usage of the two spellings.

### N8. `LiveAudioTrack` exposes `clip_slots` but nothing consumes it

`lib/live_set/live_set_audio_track.rb:2` declares `attr_reader :clip_slots`, set on line 17. No other
code reads it.

### N9. `LiveAudioClip` declares readers that are never used

`lib/live_set/live_set_audio_clip.rb:3-5` declares `file_ref`, `file_type`, `live_pack_name`,
`relative_path_type`, `id` and `need_refreeze`. Of these, only `relative_path`, `absolute_path` and
`file_size` are used elsewhere.

### N10. `AllTracks#ready_for_p3s?` is dead code

`lib/live_set/live_set_all_tracks.rb:65-69`. The comment above it explicitly says it is "not used at
present, but it should be". `p3s_tx_msg` implements the same logic inline instead.

### N11. `AllTracks#summary` contains a duplicated word

`lib/live_set/live_set_all_tracks.rb:79`:
`"Warning: This set is too large to be frozen and too large too large to transfer to Push 3
Standalone."` — "too large" appears twice.

### N12. `AllTracks#p3s_tx_msg` has an unused variable

`lib/live_set/live_set_all_tracks.rb:31` — `has_errors` is set to `true` in the `blocking_devices`
loop, and the `next if ...` on line 45 can skip the `has_errors = true` on line 43, but the local
`iteration` variable in `check_ableton_project_info` is the clearer example:
`lib/live_set/live_set_class_private.rb:16` — `iteration` is incremented on line 17 and never read.

### N13. `check_ableton_project_info` looks for `Ableton Project Info` in the set directory twice

`lib/live_set/live_set_class_private.rb:11-13` checks the set's own directory, and the loop starting
at line 18 starts from the *parent* of that directory. The two checks are therefore for different
directories, so this is not a bug, but the `cur_dir`/`prev_dir` loop guard on lines 16 and 31 is
redundant — `cur_dir.root?` on line 29 already terminates it.

### N14. `LiveSet#modify_als` hard-codes the Live 11 version strings

`lib/live_set/live_set_class.rb:71-75` hard-codes `Creator`, `MajorVersion`, `MinorVersion`,
`Revision` and `SchemaChangeCount` for "Ableton Live 11.3.21". There is no configuration or
version-detection logic to choose these.

### N15. `LiveDevice#value_of` mixes three access strategies

`lib/live_set/live_device.rb:64-70` tries the `Value` attribute, then `EffectiveName`'s `Value`
attribute, then raw text. The `.then { |s| s.empty? ? nil : s }` on line 69 would be clearer as
`&.strip`, and the chain returns the *first* match rather than preferring an explicit `Value`
attribute over a nested `EffectiveName`.

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

### N19. `als_delta` requires `highline` but never uses it

`lib/als_delta/als_delta_class.rb:4` — `require 'highline'`. `HighLine` is only used in
`lib/live_set/live_set_class_private.rb`.

### N20. `lib/live_set/live_set_options.rb` requires `optparse` but `common/util` does not

`lib/live_set/live_set_options.rb:3` and the two other `*_options.rb` files each require `optparse`
individually. `lib/common/util.rb` is the only shared file loaded unconditionally, and it does not
require it.

### N21. `Log` is referenced from `live_set_class.rb` but required elsewhere

`lib/live_set/live_set_class.rb:14` uses `Log.level`, and
`lib/live_set/live_set_audio_track.rb:9` uses `Log.debug`. Neither file requires
`../common/log`; the constant comes from `lib/live_set.rb:4` (`require_directory "#{__dir__}/common"`).
The classes are not independently loadable.

### N22. `exe/` scripts use a `VO_DEBUGGING` environment variable

`exe/live_set`, `exe/als_delta`, `exe/generate_xsd` and `exe/validate_asd` all branch on
`ENV['VO_DEBUGGING']` to choose between `require_relative '../lib/live_set'` and `require 'live_set'`.
The name suggests a generic debugger switch but is specific to this project.

### N23. `src/live_set.rs` is an incomplete Rust port

`src/live_set.rs` is 98 lines and declares `mod live_set; mod als_delta; mod common;`, but no
corresponding `live_set.rs`, `als_delta.rs` or `common.rs` files exist under `src/`. It also lists
only `common`, `als_delta` and `live_set` as commands — `generate_xsd` and `validate_asd` are absent.
The `common` command in the Rust code dispatches to `common::parse_options()` and
`common::help_live_set(...)`, mirroring the Ruby `common` method that is itself dead code (M1).

### N24. `after_real_pain.xsd` is untracked

The file exists in the working directory but `.gitignore` contains `*.xsd`, so it is not in version
control. It is a generated artifact from `generate_xsd`.

### N25. `README.md` says "Two commands are provided" while three are shipped

`README.md:109` — updated to "Three" as part of the `validate_asd` work in this session, with
`validate_asd` added to the list.

### N26. `CHANGELOG.md` lists `bin/validate_asd` and `validate_asd` as separate additions

`CHANGELOG.md:6-8` — both the bash prototype and the Ruby command are listed for 0.2.5. This
accurately reflects the history, but a reader may expect the bash script to have been replaced.

### N27. `.rubocop.yml` uses `plugins:` rather than `require:`

`.rubocop.yml:1` — this was changed from `require:` to `plugins:` in the working tree (uncommitted).
`plugins:` is the newer RuboCop spelling, but the `rubocop-md` plugin should be confirmed to
support it. RuboCop runs clean with this configuration, so it appears to work.

### N28. `rubocop-md` flags `CHANGELOG.md` and `README.md` file names

`bundle exec rubocop` reports `Naming/FileName` offenses for both markdown files. `Naming/FileName`
is already excluded for `Rakefile` (`.rubocop.yml:44-46`); the markdown files need the same
exclusion. Pre-existing, not introduced by recent work.

### N29. `lib/live_set/live_set_audio_track.rb` uses `!!` on a Nokogiri node

`lib/live_set/live_set_audio_track.rb:9-12` — `!!@audio_track.DeviceChain` and
`!!@audio_track.DeviceChain.MainSequencer.ClipSlotList` are used to test for presence. RuboCop's
`Style/DoubleNegation` flags this (it appears in the current RuboCop output). `!nil` or a `nil?`
check would be clearer.

### N30. `LiveAudioTrack#initialize` assumes `DeviceChain/MainSequencer/ClipSlotList` exist

`lib/live_set/live_set_audio_track.rb:17` — `@clip_slots = @audio_track.DeviceChain.MainSequencer.ClipSlotList`
uses no safe navigation, unlike line 12 which does. A track without a `DeviceChain` raises
`NoMethodError` on `nil`.

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

### N34. `all_tracks.rb` and `live_set_audio_track.rb` naming is inconsistent with the rest

The other classes are `LiveSet`, `LiveScene`, `LiveAudioClip`, `LiveDevice`; these are `AllTracks`
and `LiveAudioTrack` (the latter mixes both conventions).

### N35. `generate_xsd` writes the XSD without checking the output directory exists

`lib/live_set.rb:52` — `File.write(@xsd_file, content)` raises `Errno::ENOENT` if the target
directory does not exist. The `generate_xsd` help text does not mention this.

### N36. `als_delta` compares against a backup, not the previous version

`lib/als_delta/als_delta_class.rb:43-58` — the loop backs up the current file and diffs the current
file against that backup, so the first iteration compares the file to itself. The help text says
"compare with previous version", which is accurate only from the second iteration onward.

---

## Summary

| Severity | Count | Status |
| --- | --- | --- |
| Severe | 5 | 4 fixed, 1 open (S3 — recommendations only) |
| Moderate | 14 | 2 fixed (M14, M15), 12 open |
| Minor | 35 | open, reported only |

### Severe

1. **S1** — `FileUtils` is never required, so `live_set -11 -f` raises `NameError`. **Fixed.**
2. **S2** — `show_track` asks the Nokogiri node for `frozen?` instead of the track, so frozen
   tracks are always reported as not frozen. **Fixed.**
3. **S3** — `define_audio_clips` relies on Slop accessors whose return type varies by child count
   and whose Live 8 / Live 12 fallback is unreachable. **Open — recommendations only, see above.**
4. **S4** — `run_capture_stdout` treats `zdiff`'s "files differ" exit status 1 as a fatal error, so
   `als_delta` exits instead of showing the diff. **Fixed.**
5. **S5** — `run_capture_stdout` splits on all whitespace, flattening diff output. **Fixed.**

### Changes made

| File | Change |
| --- | --- |
| `lib/live_set/live_set_audio_track.rb:72` | `@audio_track.frozen?` → `frozen?` (S2) |
| `lib/common/run.rb:6-16` | `run_capture_stdout` takes `success_statuses:`; compares `status.exitstatus`; returns `stdout_str.split("\n")` (S4, S5) |
| `lib/als_delta/als_delta_class.rb:49-50` | `zdiff` call passes `success_statuses: [0, 1]` (S4) |
| `lib/common/util.rb:1` | Added `require 'bytesize'` (M14) |
| `LICENCE.txt` → `LICENSE.md` | Renamed and converted to proper markdown (M15) |
| `README.md:293` | Licence link now points at `LICENSE.md` (M15) |

### Specs added

| File | Covers |
| --- | --- |
| `spec/spec_helper.rb` | Fixtures: `audio_track_element`, `clip_slot_xml` (Live 8 nested / Live 12 flat) |
| `spec/live_set/live_set_audio_track_spec.rb` | S2 — `frozen?` |
| `spec/live_set/live_set_audio_track_show_track_spec.rb` | S2 — the frozen marker in `show_track` |
| `spec/common/run_spec.rb` | S4 — exit-status handling; S5 — line structure preserved |
| `spec/live_set/live_set_audio_track_clip_slots_spec.rb` | S3 and M9 — characterises the current broken behaviour; failing examples are `pending` |

The S2, S4 and S5 specs were verified to **fail** when the corresponding fix is reverted, so they
genuinely detect the defects rather than merely passing.
