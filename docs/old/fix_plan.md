# Fix Plan: The Live 12 → Live 11 Conversion, in XSLT

## Context

The gem converts a Live 12 set into a Live 11 set. The transformations that make the two formats differ
currently live as hand-written Ruby in `lib/live_set/live_set_converter.rb`.

We have decided the transformations belong in an XSLT stylesheet instead because a that
provides a way to associate functionality to nodes in a parsed schema. This can
be used to transform conformant XML documents. The transformations are
bidirectional, which means one XSLT stylesheet provides the ability to convert
Ableton Live 12 to Live 11 format, and back again.

`validate_asd` validates that a converted sets is well-formed XML, and that it
complies with what we have learned about that version of the Live schema.

We are unsure of the role that schemas might play in the near term. This is
undefined at present.

Already in place:

- `lib/live_set/tx/live_12_to_live_11.xsl` — a first pass at the a
  transformation. TODO this is a text file. it might be easier to maintain if it
  were expressed in Ruby code instead. important: discuss before going any further!!!
- `lib/live_set/live_set_transformer.rb` — applies a named stylesheet to a document.
- `schemas/live_{10.1.3,11.3,12.4}d1.xsd` — generated from every demo set of each version, so
  each one accepts all of its version's demo sets.

## How this plan is built

Four phases, in this order.

1. **Scaffolding** — a broad outline. It is allowed to be imperfect and incomplete.
2. **Major details** — the parts that carry the weight get filled in.
3. **Minor details** — known, written down, deliberately *not* acted on yet.
4. **Minor details added** — they get added later, one at a time.

Every phase ends at a working state. Nothing in Phase 3 blocks Phase 2.

## The "Master" → "Main" rename

The Live 12 developers renamed "Master" to "Main". This is the largest single group of
differences between the two formats, and it can be stated once instead of transformation by transformation.

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
master track. That is the exception that keeps the transformation an entry in a list rather than a substitution.

**This simplifies the transformations.** Instead of four unrelated rename transformations — `MainTrack` →
`MasterTrack`, `AutoColorPickerForReturnAndMainTracks` → `AutoColorPickerForReturnAndMasterTracks`,
`IsSongTempoLeader` → `IsSongTempoMaster`, and `AudioOut/Main` → `AudioOut/Master` — the
stylesheet has one transformation family: *Live 12 says "Main" where Live 11 says "Master"*, expressed as a
small list of the four names it applies to, plus the attribute value `AudioOut/Main`. The
`SongMasterValues` case is not a rename at all: Live 12 keeps the scroll position in
`LiveSet/SessionScrollPos`, and Live 11 keeps it in `LiveSet/SongMasterValues/SessionScrollerPos`,
so the conversion has to build the wrapper. (Live 11's `SongMasterValues` holds nothing else —
the schema says its only child is `SessionScrollerPos` — so the wrapper is small.)

The same idea applies elsewhere: the renames are a handful of one-word substitutions, and the
plan states them as such rather than as a list of unexplained differences.

## Phase 1 — Scaffolding (broad outline, imperfect on purpose)

1. `lib/live_set/tx/` holds one stylesheet per conversion direction. *(exists)*
2. `LiveSetTransformer` applies a stylesheet by name to a document. *(exists)*
3. `LiveSetConverter` keeps its current API — `new(set_name, xml_doc, overwrite:).convert` — but
   its body becomes: transform, then write. The transformations leave the Ruby file.
4. Every template in a stylesheet carries a comment saying why the transformation exists. The comments name
   the difference the transformation is about — "Live 12 says Main where Live 11 says Master" — rather than
   restating the template.
5. A spec converts a Live 12 demo set and validates the result against the Live 11 schema.
6. `docs/als_work.md` describes the stylesheet and the `tx` directory.

Not required to be true at the end of this phase: that every transformation is in the stylesheet, that the
spec passes, or that the docs describe every transformation.

## Phase 2 — Major details

**M1 — The transformation families the stylesheet has to cover.** The stylesheet must have a template for
each of these; the Ruby transformation for that family is deleted when the stylesheet has it.

| Family | Example |
| --- | --- |
| version strings on `<Ableton>` | `MajorVersion`, `MinorVersion`, `Creator`, … |
| remove a Live-12-only element | `InstrumentMeld` |
| remove a Live-12-only element under a named parent | `CrossFadeState/MidiControllerRange` |
| remove a Live-12-only attribute | `SelectedToolPanel` |
| rename an element | `MainTrack` → `MasterTrack` |
| rename an element under a named parent | `ScaleInformation/Root` → `RootNote` |
| rewrite a value | `Saturator/Oversampling`, `AudioOut/Main` → `AudioOut/Master` |
| empty an element that Live 11 leaves empty | `TimeAndValueTransforms`, `Mixer/Sends` |
| insert an element Live 11 has and Live 12 does not | `VelocityDetail`, `NeedArrangerRefreeze`, `NeedRefreeze`, `ChooserBar` |
| move an element to where Live 11 keeps it | `LiveSet/SessionScrollPos` → `SongMasterValues/SessionScrollerPos`; clip scale information → end of the clip |
| add a default attribute | note-event `Probability`, `PerNoteEvent` curve controls |
| drop what Live 11 does not have | take lanes of a MIDI track; take-lane `Id` and `LomId` |

Where the stylesheet and the old Ruby disagree, the stylesheet wins.

**M2 — `LiveSetConverter` becomes thin.** It reads the set, hands the document to
`LiveSetTransformer`, and writes the result. The transformation constants (`LIVE_12_ONLY`,
`LIVE_12_ONLY_IN_CONTEXT`, the rename maps, `EMPTY_IN_LIVE_ELEVEN`, …) and the transformation methods go
away. The class keeps its constructor, its `convert` method, and its logging.

**M3 — The specs.**

- `spec/live_set/tx/live_12_to_live_11_spec.rb` — one example per transformation family, on small XML
  fragments. Fast, and needs no demo set. The rename examples cover the whole list of the
  Master/Main rename, including `MainSequencer`, which must not be touched.
- An end-to-end example: convert a Live 12 demo set, validate the result against
  `schemas/live_11.3d1.xsd`. Skipped when the schema has not been generated, the way
  `spec/validate_asd/demo_sets_spec.rb` already is.

**M4 — The documentation.** `docs/als_work.md`, section "XSLT Implementation" (currently "See
cpfir.md" plus a TODO): describe the `tx` directory, the transformer, what a stylesheet is for,
and how a new Live version gets its own stylesheet. Note that the stylesheet is the transformation set,
and that the schema is what the result is checked against.

## Phase 3 — Minor details (noted, not acted on)

- **Return tracks.** Live 10 and Live 12 both spell a return track `<ReturnTrack>`; no Live 11
  demo set has one, so the Live 11 schema cannot describe one. The old Ruby deletes every return
  track, which loses the user's tracks. The stylesheet keeps them and the schema gap is recorded
  rather than fixed. Settling Live 11's spelling needs a Live 11 set that has a return track.
- Byte-for-byte equality with the output of the old Ruby converter. The stylesheet is the
  reference; whitespace and attribute order are not worth chasing yet.
- Device-preset provenance that Live 11 writes and Live 12 does not: `FilePresetRef`,
  `BranchSourceContext`, `OriginalFileRef`.
- Devices only Live 12 has — Drift, Hybrid, MultiSampler, Erosion, BeatRepeat, Vocoder. The
  converted set keeps them.
- Lane `Type` value domains (`docs/conversion.md` §6).
- `docs/als_format.md` is cited by the converter and the specs but does not exist;
  `docs/als_notes.md` does.
- `docs/conversion.md` §1 has a stale line-number table.
- Live 9 and Live 8 schemas (TODO, low urgency).
- Two rubocop offenses left over from earlier edits.

## Phase 4 — Minor details added later

Each Phase 3 item becomes its own small change, in the order it bites: the return-track question
first, then the schema gap, then the documentation repairs. One at a time, with a spec wherever it
can be tested.

## Files

- `lib/live_set/tx/live_12_to_live_11.xsl` — the transformations (modify)
- `lib/live_set/live_set_transformer.rb` — applies a stylesheet (exists, minor changes)
- `lib/live_set/live_set_converter.rb` — becomes thin (modify)
- `spec/live_set/tx/live_12_to_live_11_spec.rb` — new
- `spec/validate_asd/demo_sets_spec.rb` — add the end-to-end conversion example (modify)
- `docs/als_work.md` — "XSLT Implementation" (modify)

## Verification

```
bundle exec rubocop
bundle exec rspec
bin/generate_xsds          # writes schemas/, which is gitignored
bundle exec rspec spec/validate_asd/demo_sets_spec.rb
```

Then by hand: convert a Live 12 demo set with `exe/live_set`, and validate the result with
`exe/validate_asd` against `schemas/live_11.3d1.xsd`.
