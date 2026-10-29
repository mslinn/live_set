# Fix Plan: The Live 12 → Live 11 Conversion, in Ruby

## Context

The gem converts a Live 12 set into a Live 11 set.

`LiveSetConverter` reads a set, hands the parsed document to `LiveSetTransformer`, and
writes the result. The transformer looks at the version of the set, finds the bridge for that
version, and applies it. The bridge between Live 11 and Live 12 is
`lib/live_set/tx/live_11_and_12.rb`: it holds what the two versions do differently, as
lists and as hand-written code, and it inherits the machinery that applies them from
`lib/live_set/tx/live_version_converter.rb`. A bridge is not told which way to convert; it
reads the version of the set it is given and converts it to the other of the two.

The terms these documents use are defined in `docs/glossary.md`.

The plan for this conversion is this document. The outstanding work of the gem as a whole is in
`TODO.md`, and the identifiers there are the ones the code and the documents cite. Where an item
of this plan is outstanding work, it has an identifier in `TODO.md`, and this plan refers to it
by that identifier.

## The transformation is Ruby code

The transformations are Ruby code: `lib/live_set/tx/live_version_converter.rb` holds the
machinery that applies them, and the bridge for each pair of versions holds what the two
versions do differently.

The XSLT stylesheet the Ruby replaced, `lib/live_set/tx/live_12_to_live_11.xsl`, stays in the
repository. It is the only other implementation of these transformations that has ever existed,
and it was incomplete with errors.

## Architecture

The bidirectionality of the transformations is explained in `docs/cpfir.md`, and proved by the
specs that walk the same transformations in each direction:
`spec/live_set/tx/live_11_and_12_up_spec.rb` and
`spec/live_set/tx/live_11_and_12_down_spec.rb`. **Transformations are bidirectional.**

- A transformation that renames an element matches either spelling and emits the
  other. The direction is a property of the document, not of the transformation.
- The up direction (older version to newer) is lossless. It preserves everything
  the set contains and changes only how it is expressed. It must reproduce
  Live's own conversion: opening an older set in a newer Live and saving it
  produces a specific document, and the upgrade has to produce that same
  document, including the elements Live adds and the default values it gives
  them.
- The down direction is lossy. Constructs the older version cannot represent are
  dropped and cannot be recovered, so down-then-up does not return the original
  document, and the down direction is not a functional inverse of the up
  direction.
- Transformations that cannot be expressed symmetrically — deleting an element
  only the newer version has, adding one the older version lacks — are
  conditioned on the direction.
- There are no separate up and down functions, and no separate up and down
  transformations.  `docs/cpfir.md`, "The Lifecycle of a Conversion", says so: a
  transformation takes its direction from the document it is given; it matches
  the document it is given and emits something else, so one set of
  transformations carries both directions of a version_diff. One bridge stands
  between two versions, and it handles schema translations both ways.
- Because the asymmetry is real, comparing two sets means upgrading both to the same version
  first, and comparing the XML trees there, element by element, with `lib/live_set/xml_diff.rb`.
  Bytes play no part in it.

The registry is keyed by version, the key being the version the bridge leads to,
and a conversion is a composition of the bridges between the two versions,
composed with `>>`.  `docs/cpfir.md`, "Defining a Single Source of Truth: The
Target End-State" through "The Lifecycle of a Conversion", has the shape; only
the 11↔12 version_diff is in scope now.

## Classes

`lib/live_set/tx/live_version_converter.rb` holds the machinery, and knows
nothing about any particular `version_diff`:

- the lists it applies — `version`, `remove`, `remove_under`, `rename`,
  `rename_under`, `empty`, `remove_attribute`, `default_attribute`, `add`,
  `add_attribute`, `child_order` — each of which a bridge declares by calling
  the method of the base class that owns it, for the version of Live it
  converts;
- the operations that apply them: `version_strings`, `remove_elements`,
  `rename_elements`, `empty_elements`, `default_attributes`;
- `convert`, which runs them in order and then calls `special_transformations`.

`lib/live_set/tx/live_11_and_12.rb` holds the differences between the Live 11
format and the Live 12 format: the lists, and the fifteen transformations that
are not lists — the Saturator's `Oversampling` value, the `AudioOut/Main`
target, the scroll position, the freeze elements, the clip slot's refreeze, the
device's `IdRefList`, the MIDI clip's scale information, the chooser bar, the
MIDI take lanes, the take lane's `LomId`, the device's view data, the source
context, the tuning, the track names, and the follow action link. A bridge
overrides `special_transformations` and calls `super`.

The base class is written once. Each further version_diff costs a bridge of
lists and specials, and nothing else.

**Where the lists live.** The base class owns the lists, and a bridge declares
what each of them holds. There is one set of lists per bridge, with no
direction structure in it. A bridge has to declare every list, even the ones it
has nothing to say about, and a list that is not declared is an error, and it
is named. A list declared under a name the base class does not have is an error
too, and it is raised when the bridge is loaded.

**A bridge stands on its own.** No bridge inherits from another bridge, and the
base class refuses to be the parent of a bridge of a bridge. A conversion
across several versions is the composition of the bridges between them.

## Schemas

The schemas are XML schemas, stored as XSD files, one per version of Live, under `schemas/`:
`schemas/live_10.1.3d1.xsd`, `schemas/live_11.3d1.xsd`, `schemas/live_12.4d1.xsd`, named for
the version that wrote them. `docs/als_notes.md`, "ALS Schemas", says more about them.

The schemas are helpful to test conversions: the end-to-end example of Phase 3
is the conversion validated against the Live 11 schema. Passing it is necessary
and not sufficient because these schemas are probably incomplete, and making
them complete would be a huge undertaking.

The schemas describe structure, not data: the elements a version writes, the
attributes they carry, and how they nest. They say nothing about the values
those attributes hold. The two things are documented apart. `docs/als_notes.md`
holds the structure of a set — its elements, their nesting, their attributes —
and the data a set holds: the values, the sample references, the devices.
`docs/live_11_12_diff.md` holds what differs between two versions, in both: the
elements the two versions name differently, the values they write differently,
the elements one adds, the elements one puts at another depth.

They are generated, not written by hand: `bin/generate_xsds` walks the demo sets of every
installed version and calls `exe/generate_xsd` on them. They are checked in, so that a new
contributor and a new machine can work with the latest information without having to install
Live first; regenerating them is a matter of running `bin/generate_xsds` again. Each one is
generated from every demo set of its version, so each accepts
all of its version's demo sets.

A schema inferred from too few sets is stricter than Live is: it says a construct is illegal
when Live merely does not happen to have written it yet. That is why the schema gap is a thing
to be recorded rather than a bug to be fixed, and why the Live 11 demo sets having no return
track says nothing about whether Live 11 has return tracks.

## How this plan is built

Four phases, in this order.

1. **Scaffolding** — a broad outline. It is allowed to be imperfect and incomplete.
2. **Major details** — the parts that carry the weight get filled in.
3. **The details** — the work list of the down direction, and the repairs the documents need.
   These are not minor: the end-to-end example does not pass until the work list is done.
4. **Minor details added** — they get added later, one at a time.

Every phase ends at a working state. Nothing in a later phase should block an earlier one.

## Phase 1 — Scaffolding (broad outline, imperfect on purpose) **Done**

1. `lib/live_set/tx/` holds the base class and one bridge per version_diff.
2. `LiveSetTransformer` applies a transformation to a document. It becomes the seam that finds
   the bridge for the version the document holds. The direction is not passed in: the bridge
   reads the version from `<Ableton MinorVersion>` in the document it is handed, and converts to
   the other version of its version_diff.
3. `LiveSetConverter` keeps its current API — `new(set_name, xml_doc, overwrite:).convert` — but
   its body becomes: transform, then write. The transformations leave it.
4. Every transformation carries a comment saying why it exists. The comments name the difference the transformation
   is about — "Live 12 says Main where Live 11 says Master" — rather than restating the code.
5. A spec converts a Live 12 demo set and validates the result against the Live 11 schema.
6. `docs/als_work.md` describes the transformation and the `tx` directory.

Not required to be true at the end of this phase: that every transformation is in place, that the up
direction works, or that the docs describe every transformation.

## Phase 2 — Major details

**M5 — The specs.** **Partly done.**

- `spec/live_set/tx/live_version_converter_spec.rb` — the base class: that it applies the
  lists, and that a bridge's lists are read in its place. Small XML fragments, no demo set.
  **Done.**
- `spec/live_set/tx/live_11_and_12_spec.rb` — one example per transformation, on small XML fragments.
  Each example gives a document in one version and asserts the document in the other, so the
  symmetry is what is under test. The rename examples cover the whole list of the Master/Main
  rename, including `MainSequencer`, which must not be touched. **Done**, in two files:
  `live_11_and_12_down_spec.rb` and `live_11_and_12_up_spec.rb`.
- A comparison example: two sets of different versions that hold the same set compare equal once
  both are upgraded, per `docs/cpfir.md`, "Comparing Two Live Sets". **Done.**
  `spec/live_set/tx/live_up_comparison_spec.rb` is that example, and it passes.

**M6 — The documentation.** `docs/als_work.md`, section "Transform Implementation": describe the
`tx` directory, the base class and its bridges, the direction, and how a new Live version gets
its own bridge. **Done.** `docs/cpfir.md`, "The Lifecycle of a Conversion" through "The Conversion
Edits the Document It Is Given": the sentence that says the conversions are
XSLT changes, and the `BidirectionalXslt` example becomes the base class and its bridges.
**Done.** The document now describes the Ruby architecture: the three classes of a conversion
and the nine steps of the bridge, the registry, the composition of the bridges between two
versions, and the comparison of two sets by `lib/live_set/xml_diff.rb`. The mutation proxy of
the old section 6 is gone: the conversion edits the document it is given, and the section says so.

**M7 — A file of bidirectional pure functions for every Live version.** One file holds, for every
version of Live, the pure functions that translate a set to and from the previous version of
Live: the bridge between Live 11 and Live 10, the bridge between Live 10 and Live 9, and so on.
That is the version-keyed registry of `docs/cpfir.md`, "Defining a Single Source of Truth: The
Target End-State", with the bridges of the
registry as pure functions rather than as objects that are handed a document. A function is
pure, so a conversion is a composition of functions, and the direction is not passed to them:
the direction is a property of the document, which the function reads. **Done.** The registry
is `lib/live_set/tx/live_versions.rb`, keyed by the version the bridge leads to, and
`LiveSetTransformer::BRIDGES` is gone: the transformer asks the registry for the bridge of the
version the document carries.

The file is `lib/live_set/tx/live_versions.rb`. It holds the bridge for every version of Live,
and each entry is the pure function that takes a document and returns a document. The registry
is keyed by version, and the key is the version the bridge leads *to*, so that a conversion
from one version to another is the composition of the steps between them. The direction is not
a parameter of any of them: each reads the version out of the document it is handed and emits
the other of the two versions. The entry for Live 12 is the bridge that stands between Live 12
and Live 11, and it is the one that exists today, as a class.

How it is done: a bridge is a class, and it is a function of a document — `Live11And12.call(document)`
takes a document and returns the converted document, which is `LiveVersionConverter.call` in the
base class. The registry holds the bridges as those functions, so they compose with `>>`:
`LiveVersions.bridges_between(from:, to:)` gives the bridges between two versions in the order
they are applied, and `LiveVersions.convert(document, from:, to:)` is their composition.
`spec/live_set/tx/live_versions_spec.rb` is the example.

Why this belongs in Phase 2 and not Phase 3: it is the architecture the rest of the work
assumes, and it is what the registry of `docs/cpfir.md`, "Defining a Single Source of Truth: The
Target End-State", describes. The bridges
themselves — the Live 10↔9 and the Live 9↔8 — are Phase 3 work, because their transformations do not
exist yet (D8).

## Phase 3 — The details

The end-to-end example lives here, and it is the acceptance criterion of this phase: the Live 12
demo set converts to a set that validates against the Live 11 schema. It does not pass until
the down-direction work list is done, which is why it is not in Phase 2.

### End-to-end Example **Not done**

This is Phase 3's acceptance criterion; it does not pass until the
down-direction work list is done.

Convert a Live 12 demo set, validate the result against `schemas/live_11.3d1.xsd`. Skipped
when the schema is not there, the way `spec/validate_asd/demo_sets_spec.rb` already
is. `spec/live_set/tx/live_conversion_spec.rb` is that example. **Not done.** It fails: the
converted set does not validate against the Live 11 schema, and its failure message is the work
list below. The contract this example holds the conversion to is:


### The down-direction work list

Each name below is a construct the converted set carries that the Live 11 schema does not
accept. What each one becomes is decided by the kind of difference it is, and the kinds are in
`docs/conversion.md`, "The kinds of difference". A construct Live 11 does not have is a transformation
that removes it; a
construct Live 11 does have, but the Live 11 schema does not declare, is a gap in the schema —
the schema is an inference from the XML stored in the sets of that version, and a schema
inferred from too few sets is stricter than Live is. Which of the two a name is cannot be read
off the failure message alone: it takes the two schemas, and for the devices, Ableton's
published device lists.

The transformations are written by hand, in `lib/live_set/tx/live_11_and_12.rb`, each with a comment
naming the difference it is about. Nothing produces them automatically
(`docs/conversion.md`, "The differences must be sorted by kind, and the non-obvious ones
hand-written"). The vocabulary a transformation needs comes from the schemas: the schema of
a version lists every element and every attribute of that version, and the differences between
two versions are found by diffing one schema against the other (`docs/als_work.md`, "Mapping
XSD to Ruby Classes"; `docs/conversion.md`, "Attributes have to be part of the difference list"
and "Why the baselines are what to compare").

The items are grouped by the construct they belong to, so that names are worked on together.
The grouping is provisional: it says which names are settled in one sitting, and each name is
settled on its own.

1. **The MIDI mapping elements** — `MidiControllerRange` (235), `KeyMidi` (19). **Not done.**
2. **The MultiSampler and its slices** — `MultiSamplePart` (13),
   `InitialSlicePointsFromOnsets` (12), `RoundRobin` (12),
   `InitUpdateAreSlicesFromOnsetsEditableAfterRead` (12), `MultiSampler` (2). **Not done.**
3. **The Drift device** — `Drift` (3). **Not done.**
4. **The device preset provenance** — `OriginalFileRef` (12), `BranchSourceContext` (11),
   `AbletonDefaultPresetRef` (9), `SourceContext` (5). **Not done.**
5. **The `Value` attributes Live 12 writes** — `Value` (8). **Not done.**
6. **The Live 12 devices** — `MultibandDynamics` (3), `AdaptiveQAffectsShelves` (3),
   `Vocoder` (2), `GrainDelay` (2), `AudioEffectBranch` (2), `Vinyl` (1), `StereoGain` (1),
   `Reverb` (1), `PreDrive` (1), `GlueCompressor` (1), `Delay` (1), `AutoFilter` (1).
   **Not done.**
7. **The audio clip's warp markers** — `WarpMarkers` (1). **Not done.**
8. **The MIDI clip's per-note elements** — `PerNotePitchBendOn` (1), `MidiNoteLength` (1),
   `MidiArpeggiator` (1). **Not done.**
9. **The device's view data and macro snapshots** — `ViewStates` (1), `MacroSnapshots` (1).
   **Not done.**
10. **The names not yet classified** — `Manual` (3), `Sends` (2), `AutomationLane` (1).
    **Not done.** These are classified before they are worked on: each is either a construct
    Live 11 does not have, or a gap in the Live 11 schema.
11. **The return tracks.** Live 10 and Live 12 both spell a return track `<ReturnTrack>`; no
    Live 11 demo set has one, so the Live 11 schema cannot describe one. The old Ruby deletes
    every return track, which loses the user's tracks. The transformation keeps them and the
    schema gap is recorded rather than fixed. Settling Live 11's spelling needs a Live 11 set
    that has a return track. **Open.**

### The documents

The end-to-end example fails because the transformations are incomplete, and the transformations cannot be written
until the documents say what the differences between two versions are, and where each one
belongs. So the documents are made consistent first, and the end-to-end example is fixed last.

**D1 — The release notes are the evidence, and they are kept.** The release notes of Live 8
through Live 12 are downloaded from Ableton's web site into `docs/release_notes/`, one file per
version, and `docs/release_notes/index.md` records where they come from, how they were fetched,
and what they are used for. **Done.**

**D2 — A file of bidirectional pure functions for every Live version.** Phase 2, M7.

**D3 — A difference belongs to the version that introduced it, and a similarity is not a
difference.** A fact that both versions share is not in a version_diff document at all; the
format facts of it belong in `docs/als_notes.md`. Where a difference is recorded depends on
which version introduced it, and the release notes say which that is. **Done.**

**D4 — Section numbers are dropped, and the headings are what the code cites.** The numbers
came from `docs/als_format.md`, which no longer exists, and they were load-bearing in 32
citations. **Done**, D4a to D4g.

- **D4a — The numbers are gone from `docs/als_notes.md`. Done.**
- **D4b — The numbers are gone from `docs/als_work.md`. Done.**
- **D4c — The numbers are gone from `docs/live_11_12_diff.md`. Done.**
- **D4d — The code in `lib/` cites the headings. Done.**
- **D4e — The specs cite the headings. Done.**
- **D4f — `README.md` links to the headings. Done.**
- **D4g — `docs/conversion.md` and `docs/cpfir.md` keep their numbers, and the code still cites
  them by number. Done.** Their numbers are their own, not the ones `als_format.md` had, so
  they were not part of the first pass. Until they are reconciled with the headings, the code
  cites headings in one document and numbers in another.

  The numbers are gone from both documents now, and everything that cited them cites the
  headings instead:

  | Where | The citation | The heading it became |
  | --- | --- | --- |
  | `docs/cpfir.md` | its numbered sections 1–6 | "Core Principles of Pure Function Composition", "Defining a Single Source of Truth: The Target End-State", "Dynamically Slicing the Pipeline Intervals", "The Lifecycle of a Conversion", "Comparing Two Live Sets", "The Conversion Edits the Document It Is Given" |
  | `lib/live_set/live_set_transformer.rb` | `docs/cpfir.md`, section 4 | "The Lifecycle of a Conversion" |
  | `lib/live_set/live_set_transformer.rb` | `docs/conversion.md`, sections 2.2 and 3.3 | "The kinds of difference" and "The differences must be sorted by kind, and the non-obvious ones hand-written" |
  | `lib/live_set/tx/live_version_converter.rb` | `docs/cpfir.md`, section 4 | "The Lifecycle of a Conversion" |
  | `lib/live_set/tx/live_version_converter.rb` | `docs/conversion.md`, section 3.3 | "The differences must be sorted by kind, and the non-obvious ones hand-written" |
  | `lib/live_set/tx/live_version_converter.rb` | `docs/conversion.md`, sections 3.4 and 5.3 | "Attributes have to be part of the difference list" and "Why the baselines are what to compare" |
  | `lib/live_set/tx/live_11_and_12.rb` | `docs/conversion.md`, section 2.2 | "The kinds of difference" |
  | `lib/live_set/tx/live_11_and_12.rb` | `docs/cpfir.md`, section 4 | "The Lifecycle of a Conversion" |
  | `lib/live_set/live_set_converter.rb` | `docs/cpfir.md` | "The Lifecycle of a Conversion" |
  | `docs/als_work.md`, `docs/live_11_12_diff.md`, `docs/conversion.md`, `docs/index.md` | the same numbers | the same headings |
  | `docs/fix_plan2.md` — "Architecture", "M5", "M6", "M7", "D4g", "D8" | `docs/cpfir.md` §2, §4, §5, and `docs/conversion.md` §2.2, §3.3 | the same headings |

  The numbering of `docs/conversion.md` is dropped as well, so that its citations read as
  headings like the others: "The conversion today", "What is wrong with it", "The measurement",
  "The kinds of difference", "The lane values", "What must change", "The conversion must become a
  transform", "The differences must be written down as transformations, not discovered each time", "The
  differences must be sorted by kind, and the non-obvious ones hand-written", "Attributes have
  to be part of the difference list", "Elements have to be able to be added", "Value domains
  have to be known", "The output has to be checked before it is reported as converted", "The
  pieces", "The reader", "The transforms", "The baselines", "The comparator", "The component",
  "Putting it together", "Traps in XSLT 1.0", "Open questions", "Baselines", "What a baseline
  is", "How it was discovered", "Why the baselines are what to compare", "What the baseline is
  for", "A baseline and a schema are opposite operations on the same corpus", "One open
  question", "Value domains", "The question", "What the other parsers do", "What that means
  here", "How a domain can be written down", "What to do with an illegal value".

  The references inside `docs/conversion.md` to its own sections became references to its own
  headings: "section 6" is "Value domains", "section 5" is "Baselines", and "section 2.3" is
  "The lane values".

**D5 — `docs/als_notes.md` routes the reader.** A reader who does not yet know which document to
open should find the way from the format to the version_diff documents. The outline of
`docs/als_notes.md` becomes: an early section that introduces the version_diff documents and
their headings, and short stub sections that point at a specific heading of a version_diff
document, wherever one exists. Where none exists, one is written.

**Done.** The routing section is in place, and it is followed by stubs for "The lane types" and
"The schema a converted set is written to"; each stub names a heading of
`docs/live_11_12_diff.md`, and each of those headings exists. The other three version_diff
documents are not written yet (D8), so there is nothing to stub for them. Where a stub needs a
heading that does not exist, that heading is written, in the difference document it belongs to.

**D6 — The index is the map, and it is cleaned up first.** **Done**
`docs/index.md` says what each document
is for, and where the code lives. , and it is being kept current as the documents change.

**D7 — The TODO and FIXME comments in the documents are answered.** **Not done.**
They are the work list for the documentation. `docs/index.md` is cleaned
up first, because the index is the map the other repairs are made against. Then
each comment is answered, moved to `TODO.md` with an identifier, or deleted as
superseded.

| Where | The comment |
| --- | --- |
| `README.md:301`, `README.md:306` | a frozen group track: what the XML says, and the `Options.txt` option (`docs/als_notes.md`, "The `Options.txt` hidden option") |
| `docs/als_notes.md:24` | show the schemas of each version |
| `docs/als_notes.md:36` | which version the outline was taken from |
| `docs/als_work.md:90` | `als_delta` compares XML strings; it has to compare trees |
| `docs/als_work.md:253` | the note that this document predates the code |
| `docs/als_work.md:393`, `docs/als_work.md:405` | the Live 9 and the Live 8 schemas |
| `docs/als_work.md:670` | the lanes: the explanation is not authoritative |
| `docs/als_work.md:736` | the round trip: verbose, to be summarized or deleted |
| `docs/als_work.md:848` | the "Live 8 layout" label on the nested clip slot, which is wrong |
| `docs/als_work.md:898`, `docs/als_work.md:901` | how often a session slot holds an audio clip |
| `docs/als_work.md:922` | the two id spaces, of the session view and of the arrangement |
| `docs/als_work.md:1012` | the `PluginDevice` FIXME: the name is not where the code looks for it |
| `docs/als_work.md:1057` | the paragraph about telling a third-party plug-in from a native device |
| `docs/als_work.md:1072` | the elements the code looks for that no real set has |
| `docs/als_work.md:1086` | cites **TODO N21**, which is not an identifier in `TODO.md`. **Done.** The citation is gone: the passage now says the code has been rewritten, and points at `lib/live_set/live_device.rb`. The two other dangling identifiers were `TODO.md N39` (`spec/live_set/live_set_modify_als_spec.rb`, twice — now T1, which is the question it was) and `TODO.md S3` (`spec/live_set/live_set_track_show_track_spec.rb` — now the code that does the clip parsing). |
| `docs/als_work.md:1337` | the discussion of blocking transfers and blocking group devices |
| `docs/live_control_plan.md:18`, `:63`, `:95`, `:116`, `:148`, `:173`, `:175`, `:319` | the plan for proving a conversion by running Live |

**D8 — A version_diff document for every two adjacent versions.** `docs/live_8_9_diff.md`,
`docs/live_9_10_diff.md`, `docs/live_10_11_diff.md` and `docs/live_11_12_diff.md`. Each holds the
newer version's release notes summarized, and then the format differences that follow from them,
organized by the kinds of difference in `docs/conversion.md`, "The kinds of difference". The release
notes of the newer
version supply the items, because every difference is something the newer version changed.
**Not done.** `docs/live_11_12_diff.md` is written; the other three are not.

The evidence for Live 10↔11 is gathered but not written down. What is known:
Live 10 has `<SceneNames><Scene Id="38" Value="Scene 1">`, with a `ColorIndex` child; Live 11
has `<Scenes><Scene Id="0">`, with `<Name Value="Intro"/>`, `<FollowAction>`, `<Color>`,
`<Tempo>`, `<TimeSignatureId>`, `<IsTempoEnabled>` and `<TimeSignatureEnabled>` children. So
`SceneNames` becomes `Scenes`, the scene's name moves from an attribute to a `Name` child, and
the follow action moves from the clip to the scene. Candidates from the schema vocabularies,
not yet verified: `ExpressionLane`/`ContentLanes`, `GroovePool`, `MpeSettings`, `Drift`,
`Hybrid`, `TakeLane`, `PerNoteEvent`, `FileSize`/`OriginalFileSize`.

## Phase 4 — Minor details added later

These are the items that do not block anything: they are added one at a time, in the order they
bite, with a spec wherever they can be tested.

- **Lane `Type` value domains** (`docs/conversion.md`, "Value domains"; TODO N42). The Live 12
  lane numbering is not portable to Live 11, and the converted set keeps lane `Type` values that
  Live 11 does not understand.
- **Live 9 and Live 8 schemas**, and the bridges for the version_diffs below 11 (TODO, low
  urgency). The bridges are the code side of D8, and the registry of `docs/cpfir.md`,
  "Defining a Single Source of Truth: The Target End-State", composes a conversion from Live 8
  only when the bridges for 9, 10 and 11 are there.
- **Six rubocop offenses** in `lib/live_set/tx/live_11_and_12.rb`, in the `TRACK_ATTRIBUTES` and
  `ADD_ATTRIBUTE` hashes: alignment of the keys, and a trailing comma. All are autocorrectable.
- **The Ruby against the stylesheet it replaces.** The two have already been compared node for
  node on the Live 12 demo set, and the result was identical; what is left is to make that
  comparison a spec. What it is worth is not settled: the stylesheet has the same gaps in its
  transformations that the Ruby has, so the comparison is not a test of correctness, and it is not
  the test the conversion is measured against either — that is the Live 11 schema. What it does
  show is that the rewrite did not lose what the stylesheet had, and the stylesheet is the only
  other implementation of these transformations that has ever existed.

## Files

- `lib/live_set/tx/live_version_converter.rb` — the base class (new)
- `lib/live_set/tx/live_11_and_12.rb` — the transformations for the 11↔12 version_diff (new)
- `lib/live_set/tx/live_versions.rb` — the version-keyed registry of the pure functions (new)
- `lib/live_set/tx/live_12_to_live_11.xsl` — kept: the XSLT the Ruby replaces, kept for
  comparison
- `lib/live_set/live_set_transformer.rb` — finds the bridge for the version the document carries,
  and applies it
- `lib/live_set/live_set_converter.rb` — becomes thin (modify)
- `spec/live_set/tx/live_version_converter_spec.rb` — new
- `spec/live_set/tx/live_11_and_12_down_spec.rb`, `spec/live_set/tx/live_11_and_12_up_spec.rb` —
  one example per transformation, in each direction (new)
- `spec/live_set/tx/live_conversion_spec.rb` — the end-to-end conversion example (new)
- `spec/live_set/tx/live_versions_spec.rb` — the registry of the bridges (new)
- `docs/live_8_9_diff.md`, `docs/live_9_10_diff.md`, `docs/live_10_11_diff.md` — the version_diff
  documents for the older versions (new)
- `docs/als_work.md` — "Transform Implementation" (modify)
- `docs/cpfir.md` — the XSLT sentences, replaced with the Ruby architecture (modify)
- `docs/conversion.md` — the numbers dropped, the headings cited (modify)
- `docs/glossary.md`, `docs/index.md` — the terms and the map (modify)

## Verification

```shell
bundle exec rubocop
bundle exec rspec
bin/generate_xsds          # rewrites schemas/, which is checked in
bundle exec rspec spec/validate_asd/demo_sets_spec.rb
```

The conversion is checked against the Live 11 schema, by the end-to-end example in Phase 3.

Then by hand: convert a Live 12 demo set with `exe/live_set`, and validate the result with
`exe/validate_asd` against `schemas/live_11.3d1.xsd`.
