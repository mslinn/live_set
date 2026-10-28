# Fix Plan: The Live 12 → Live 11 Conversion, in Ruby

## Context

The gem converts a Live 12 set into a Live 11 set. The rules that make the two formats differ
currently live as hand-written Ruby in `lib/live_set/live_set_converter.rb`.

We have decided the rules belong in a transformation of their own, one that provides a way to
associate functionality with nodes in a parsed schema, and that can transform conformant XML
documents. The transformation is bidirectional: one transformation converts Ableton Live 12 to
the Live 11 format, and back again.

`validate_asd` validates that a converted set is well-formed XML, and that it complies with what
we have learned about that version of the Live schema.

We are unsure of the role that schemas might play in the near term. This is undefined at present.

Already in place:

- `lib/live_set/live_set_transformer.rb` — applies a transformation to a document.
- `schemas/live_{10.1.3,11.3,12.4}d1.xsd` — generated from every demo set of each version, so
  each one accepts all of its version's demo sets.

## The transformation is Ruby code, not an XSLT stylesheet

`lib/live_set/tx/live_12_to_live_11.xsl` was written first, as an XSLT stylesheet. It is 397
lines and it will certainly grow: every rule is a template with its own identity handling, and
the up direction would double it. It is replaced by Ruby code.

The Ruby was written and run against the stylesheet on the Live 12 demo set. The two produce
the same document, node for node:

```
xslt elements: 236427   ruby elements: 236427
IDENTICAL
```

The sizes, and what they mean:

| | lines | of which rules |
| --- | --- | --- |
| the XSLT stylesheet | 397 | 332 without comments |
| the Ruby, one file | 213 | 156 without comments |
| the Ruby, base class + subclass | 257 | 100 base, 157 rules |

The Ruby is shorter and it grows more slowly. A rule is a table entry instead of a template:
the forty-element removal list is twelve lines of `%w[]` and one loop, against forty lines of
template. A rename is a hash entry. The special rules are three to eight plain lines each. And
none of the XSLT 1.0 constraints apply — no template priorities, no `xsl:copy` that silently
drops attributes, no user-defined functions, no `xsl:message` that raises.

The decisive argument is the up direction. The up direction (Live 11 → Live 12) has to be
lossless and faithful to Live's own conversion, and its rules come from the same experiment that
produced the down direction: open a Live 11 demo set in Live 12, save it, and compare the two
files. In XSLT that means a second template for every rule, and the stylesheet roughly doubles
to eight hundred lines. In Ruby the same tables are read the other way.

`docs/cpfir.md` says that ALS conversions are handled by XSLT transformations. That sentence
changes.

## The architecture

The bidirectionality is settled in `docs/cpfir.md`, and proved by the `/tmp/bidir.rb`
experiment: **a transformation is not directional.**

- A rule that renames an element matches either spelling and emits the other. The direction is a
  property of the document, not of the rule.
- The up direction (older version to newer) is lossless. It preserves everything the set
  contains and changes only how it is expressed. It must reproduce Live's own conversion:
  opening an older set in a newer Live and saving it produces a specific document, and the
  upgrade has to produce that same document, including the elements Live adds and the default
  values it gives them.
- The down direction is lossy. Constructs the older version cannot represent are dropped and
  cannot be recovered, so down-then-up does not return the original document, and the down
  direction is not a functional inverse of the up direction.
- Rules that cannot be expressed symmetrically — deleting an element only the newer version has,
  adding one the older version lacks — are conditioned on the direction.
- There are no separate up and down functions, and no separate up and down rules.
  `docs/composing_pure_functions_in_ruby.md` says so: "These pure functions are bidi xslt
  transformations. Thus we do not define separate up and down functions." One bridge stands
  between two versions, and it handles moving both ways.
- Because the asymmetry is real, comparing two sets means upgrading both to the same version
  first, and comparing the XML trees there (canonicalized, per XML C14N, with the whitespace
  removed). Bytes play no part in it.

The registry is keyed by version, each entry holding the step up to the next version and the step
down to the previous one, and a conversion is a pipeline of those steps composed with `>>`.
`docs/cpfir.md` §2–§4 has the shape; only the 11↔12 pair is in scope now.

## The base class and its subclasses

`lib/live_set/tx/live_version_converter.rb` holds the machinery, and knows nothing about any
particular version pair:

- the tables it applies — `VERSION`, `REMOVE`, `REMOVE_UNDER`, `RENAME`, `RENAME_UNDER`,
  `EMPTY`, `REMOVE_ATTRIBUTE`, `DEFAULT_ATTRIBUTE` — read through `self.class::`, so a
  subclass supplies them by defining its own;
- the operations that apply them: `version_strings`, `remove_elements`, `rename_elements`,
  `empty_elements`, `default_attributes`;
- `convert`, which runs them in order and then calls `special_rules`.

`lib/live_set/tx/live_11_and_12.rb` holds the differences between the Live 11 format and the
Live 12 format: the tables, and the eight rules that are not tables — the Saturator's
`Oversampling` value, the `AudioOut/Main` target, the scroll position, the freeze elements, the
clip slot's refreeze, the device's `IdRefList`, the MIDI clip's scale information, and the
chooser bar. A subclass overrides `special_rules` and calls `super`.

The base class is written once. Each further version pair costs a subclass of tables and
specials, and nothing else.

## The "Master" → "Main" rename

The Live 12 developers renamed "Master" to "Main". This is the largest single group of
differences between the two formats, and it can be stated once instead of rule by rule.

The schemas make the shape of it plain:

| Live 11 | Live 12 |
| --- | --- |
| `MasterTrack` | `MainTrack` |
| `AutoColorPickerForReturnAndMasterTracks` | `AutoColorPickerForReturnAndMainTracks` |
| `IsSongTempoMaster` | `IsSongTempoLeader` |
| `SongMasterValues/SessionScrollerPos` | `LiveSet/SessionScrollPos` |

No element or attribute name in the Live 12 format contains "Master" at all — zero occurrences
across every Live 12 demo set. Live 11 has exactly four. So the conversion has to put "Master"
back in four places, and nowhere else.

The rename was not a blind search-and-replace, and the plan must not be one either:
`MainSequencer` is spelled the same in Live 11 and Live 12, and it has nothing to do with the
master track. That is the exception that keeps the rule a table rather than a substitution.

**This simplifies the rules, and the bidirectionality simplifies them further.** A rename is
symmetric — it matches either spelling and emits the other — so the four renames above are one
table, not four rules. Where a rule cannot be symmetric, it is conditioned on the direction:

- `MainTrack` ↔ `MasterTrack` — symmetric, one table entry.
- `AutoColorPickerForReturnAndMainTracks` ↔ `AutoColorPickerForReturnAndMasterTracks` — symmetric.
- `IsSongTempoLeader` ↔ `IsSongTempoMaster` — symmetric; Live 12 says "Leader", not "Main".
- `AudioOut/Main` ↔ `AudioOut/Master` — symmetric, an attribute value.
- `LiveSet/SessionScrollPos` → `SongMasterValues/SessionScrollerPos` — not a rename. Live 12
  keeps the scroll position where Live 11 keeps it in a wrapper, and Live 11's `SongMasterValues`
  holds nothing else (the schema says its only child is `SessionScrollerPos`). So the wrapper is
  built on the way down and unwrapped on the way up.

## How this plan is built

Four phases, in this order.

1. **Scaffolding** — a broad outline. It is allowed to be imperfect and incomplete.
2. **Major details** — the parts that carry the weight get filled in.
3. **Minor details** — known, written down, deliberately *not* acted on yet.
4. **Minor details added** — they get added later, one at a time.

Every phase ends at a working state. Nothing in Phase 3 blocks Phase 2.

## Phase 1 — Scaffolding (broad outline, imperfect on purpose)

1. `lib/live_set/tx/` holds the base class and one subclass per version pair.
2. `LiveSetTransformer` applies a transformation to a document. It becomes the seam that finds
   the bridge for the version the document holds. The direction is not passed in: the bridge
   reads the version from `<Ableton MinorVersion>` in the document it is handed, and converts to
   the other version of its pair.
3. `LiveSetConverter` keeps its current API — `new(set_name, xml_doc, overwrite:).convert` — but
   its body becomes: transform, then write. The rules leave it.
4. Every rule carries a comment saying why it exists. The comments name the difference the rule
   is about — "Live 12 says Main where Live 11 says Master" — rather than restating the code.
5. A spec converts a Live 12 demo set and validates the result against the Live 11 schema.
6. `docs/als_work.md` describes the transformation and the `tx` directory.

Not required to be true at the end of this phase: that every rule is in place, that the up
direction works, or that the docs describe every rule.

## Phase 2 — Major details

**M1 — Every rule of the current converter is in the subclass.** The rules are the tables and
the eight specials listed above. The Ruby rules in `live_set_converter.rb` — `LIVE_12_ONLY`,
`LIVE_12_ONLY_IN_CONTEXT`, the rename maps, `EMPTY_IN_LIVE_ELEVEN`, and the rule methods — go
away once the subclass has them. The conversion is checked against the stylesheet it replaces,
node for node, on a demo set.

**M2 — The bridge knows which way it is going, and the rules follow.** The bridge reads the
version of the document it is given and converts to the other version of its pair. A rename rule
emits whichever spelling the document does not have. A removal rule removes the elements only
the newer version has — a no-op going the other way, because a Live 11 file does not have them.
An insertion rule inserts the elements only the older version has, and it applies only when going
down. The rules that cannot be expressed symmetrically — the freeze elements, the clip slot's
refreeze, the chooser bar, the scale information — get their other half, so that the up
direction reproduces what Live itself does.

**M3 — The up direction, Live 11 → Live 12.** Lossless, and faithful to Live's own conversion.
The rules come from the same experiment that produced the down direction: open a Live 11 demo
set in Live 12, save it, and compare the two files. The acceptance test is `docs/cpfir.md` §4:
the upgraded set has to match the set Live itself produced, including the elements Live adds and
the default values it gives them.

**M4 — `LiveSetConverter` becomes thin.** It reads the set, hands the document to
`LiveSetTransformer`, and writes the result. It keeps its constructor,
its `convert` method, and its logging, and loses its rules.

**M5 — The specs.**

- `spec/live_set/tx/live_version_converter_spec.rb` — the base class: that it applies the
  tables, and that a subclass's tables are read in its place. Small XML fragments, no demo set.
- `spec/live_set/tx/live_11_and_12_spec.rb` — one example per rule, on small XML fragments.
  Each example gives a document in one version and asserts the document in the other, so the
  symmetry is what is under test. The rename examples cover the whole table of the Master/Main
  rename, including `MainSequencer`, which must not be touched.
- An end-to-end example: convert a Live 12 demo set, validate the result against
  `schemas/live_11.3d1.xsd`. Skipped when the schema has not been generated, the way
  `spec/validate_asd/demo_sets_spec.rb` already is.
- A comparison example: two sets of different versions that hold the same set compare equal once
  both are upgraded, per `docs/cpfir.md` §5.

**M6 — The documentation.** `docs/als_work.md`, section "XSLT Implementation" (currently "See
cpfir.md" plus a TODO): describe the `tx` directory, the base class and its subclasses, the
direction, and how a new Live version gets its own subclass. `docs/cpfir.md` §4–§6: the
sentence that says the conversions are XSLT changes, and the `BidirectionalXslt` example becomes
the base class and its subclasses.

## Phase 3 — Minor details (noted, not acted on)

- **Return tracks.** Live 10 and Live 12 both spell a return track `<ReturnTrack>`; no Live 11
  demo set has one, so the Live 11 schema cannot describe one. The old Ruby deletes every return
  track, which loses the user's tracks. The transformation keeps them and the schema gap is
  recorded rather than fixed. Settling Live 11's spelling needs a Live 11 set that has a return
  track.
- **Where the tables live.** Settled: Ruby constants in the subclass. There is one set per
  bridge, with no direction structure in it, so the argument for a data file — that the data
  would express the direction — does not apply. What is left against it is that YAML resolves
  `"1"` as `1` and `"true"` as `true`, and a misspelled key returns `nil` rather than raising,
  and both of those fail silently in values that go straight into XML attributes.
- Byte-for-byte equality with the output of the old Ruby converter. The transformation is the
  reference; whitespace and attribute order are not worth chasing yet.
- Device-preset provenance that Live 11 writes and Live 12 does not: `FilePresetRef`,
  `BranchSourceContext`, `OriginalFileRef`.
- Devices only Live 12 has — Drift, Hybrid, MultiSampler, Erosion, BeatRepeat, Vocoder. The
  converted set keeps them.
- Lane `Type` value domains (`docs/conversion.md` §6).
- `docs/als_format.md` is cited by the converter and the specs but does not exist;
  `docs/als_notes.md` does.
- `docs/conversion.md` §1 has a stale line-number table.
- Live 9 and Live 8 schemas, and the subclasses for the pairs below 11 (TODO, low urgency).
- Two rubocop offenses left over from earlier edits.

## Phase 4 — Minor details added later

Each Phase 3 item becomes its own small change, in the order it bites: the return-track question
first, then the schema gap, then the documentation repairs. One at a time, with a spec wherever it
can be tested.

## Files

- `lib/live_set/tx/live_version_converter.rb` — the base class (new)
- `lib/live_set/tx/live_11_and_12.rb` — the rules for the 11↔12 pair (new)
- `lib/live_set/tx/live_12_to_live_11.xsl` — deleted
- `lib/live_set/live_set_transformer.rb` — maps a target version to a conversion
- `lib/live_set/live_set_converter.rb` — becomes thin (modify)
- `spec/live_set/tx/live_version_converter_spec.rb` — new
- `spec/live_set/tx/live_11_and_12_spec.rb` — new
- `spec/validate_asd/demo_sets_spec.rb` — add the end-to-end conversion example (modify)
- `docs/als_work.md` — "XSLT Implementation" (modify)
- `docs/cpfir.md` — the XSLT sentences (modify)

## Verification

```
bundle exec rubocop
bundle exec rspec
bin/generate_xsds          # writes schemas/, which is gitignored
bundle exec rspec spec/validate_asd/demo_sets_spec.rb
```

The conversion is also checked against the stylesheet it replaces, node for node, on the Live 12
demo set — the check that has already been run and reported.

Then by hand: convert a Live 12 demo set with `exe/live_set`, and validate the result with
`exe/validate_asd` against `schemas/live_11.3d1.xsd`.
