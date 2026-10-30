# Converting and Comparing Live Sets

This document says:

1. What the Live 11 conversion does today, and what is wrong with it.
2. What has to change.
3. What the pieces are, and how they fit together.

The companion documents are:

- [`glossary.md`](glossary.md) — the terms these documents use.
- [`als_notes.md`](als_notes.md) — the format itself: what the XML looks like.
- [`als_work.md`](als_work.md) — the how-to document for working with the format.
- [`live_control_plan.md`](live_control_plan.md) — the plan for proving a
  conversion by opening it in Live.

Open questions live in [`TODO.md`](../TODO.md). The ones this document touches are **T1** (XML-level
validation of the Live 11 conversion) and **N42** (unknown lane `Type` values may crash Live 11).


## The conversion today

`live_set -11` converts a Live 12 set to the Live 11 format. It used to be six
hand-written edits in `lib/live_set/live_set_class.rb`:

| Line    | What it does                                                                                              |
| ------- | --------------------------------------------------------------------------------------------------------- |
| 101–105 | Writes five Live 11 version strings onto the `<Ableton>` element, including a hard-coded `Revision` hash. |
| 113–117 | Deletes every `//InstrumentMeld`, `//Roar` and `//MxPatchRef`.                                            |
| 121     | Replaces the text `AudioOut/Main` with `AudioOut/Master` in the serialized XML.                           |
| 172–176 | Renames `MidiEditorLaneModel` to `ExpressionLane` inside `ContentLanes` and `ExpressionLanes`.            |
| 181–189 | Rewrites a `Saturator`'s `Oversampling` from `"true"`/`"false"` to `"1"`/`"0"`.                           |
| 47      | Parses the document with `Nokogiri::Slop`.                                                                |

The transform now exists, and it is Ruby rather than XSLT: the base class is
`lib/live_set/tx/live_version_converter.rb`, the transformations of the 11↔12 version_diff are
`lib/live_set/tx/live_11_and_12.rb`, and `docs/fix_plan2.md` says why the
stylesheet was replaced. The line numbers above are those of the code that is
gone; the table describes what the conversion did, not where it lives now.

A transform takes its direction from the document it is given. A rename matches either
spelling and emits the other, so one set of transformations carries both directions of a
version_diff. See `docs/cpfir.md`, "The Lifecycle of a Conversion".


## What is wrong with it

### The measurement

The Live 12 demo set was converted with the current code, and the result was
validated against a freshly generated Live 11 schema:

```shell
$ bundle exec exe/live_set -11 -f /tmp/live12_input.als
Writing /tmp/live12_input_11.als
Conversion complete

$ bundle exec exe/generate_xsd -f /tmp/live_11.3d1.xsd <live 11 demo set>
$ bundle exec ruby probe_validate.rb      # validates the converted set
total errors: 539
```

**539 errors.** Broken down:

| Kind | Count |
| --- | --- |
| The attribute is not allowed | 521 |
| `ArrangementClipsListWrapper` is not expected | 15 |
| `TimeAndValueTransforms` may not have content | 1 |
| `ReturnTrack` is not expected | 1 |
| `MainTrack` is not expected; `MasterTrack` was expected | 1 |

The 521 attribute errors are:

| Attribute                                                                  | Count    | Where                                                              |
| -------------------------------------------------------------------------- | -------- | ------------------------------------------------------------------ |
| `CurveControl1X`, `CurveControl1Y`, `CurveControl2X`, `CurveControl2Y`     | 119 each | on `<FloatEvent>`, at a position where Live 11 does not allow them |
| `SelectedToolPanel`, `SelectedGeneratorName`, `SelectedTransformationName` | 15 each  | on track elements                                                  |

Two caveats about these numbers:

- **539 is a floor, not a ceiling.** libxml2 reports only the first violation
  inside an element, so a track that fails on an unexpected element never gets
  its attributes checked.
- **One of the 539 is not a conversion defect.** The Live 11 demo set has no
  `ReturnTrack`, so the Live 11 schema does not declare one. That error is an
  artifact of generating the schema from a single set, not something the
  conversion did wrong.

### The kinds of difference

Every difference between two Live versions falls into one of eight kinds. Each
kind needs a different operation, so the list of differences has to be sorted by
kind before anything can be done with it.

<!-- markdownlint-disable MD013 -->
| Kind                          | Example, measured on the demo sets                                                                                                                 | Operation           |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| Element in the source only    | `InstrumentMeld` (2), `Roar` (10), `MxPatchRef` (5), `ArrangementClipsListWrapper` (45), `TakeLanesListWrapper` (19)                               | delete              |
| Attribute in the source only  | `SelectedToolPanel`, `SelectedGeneratorName`, `SelectedTransformationName` (19 tracks each); `InitUpdateAreSlicesFromOnsetsEditableAfterRead` (27) | delete attribute    |
| Element renamed               | `MidiEditorLaneModel` → `ExpressionLane` (8); `MainTrack` → `MasterTrack` (1); `ReWireDeviceMidiTargetId` → `ReWireSlaveMidiTargetId`              | rename              |
| Attribute value respelled     | `AudioOut/Main` → `AudioOut/Master` (17), on `Target/@Value`; `Saturator/Oversampling` `"true"`/`"false"` → `"1"`/`"0"`                            | rewrite the value   |
| Element in the target only    | `VelocityDetail` (16), `NeedArrangerRefreeze` (16)                                                                                                 | add with a default  |
| Value not legal in the target | lane `Type` 2 and 3 in `ContentLanes`, `Type` 5 in `ExpressionLanes`                                                                               | filter or translate |
| Element at a different depth  | *none found in the demo sets*                                                                                                                      | move                |
| Everything else               |                                                                                                                                                    | keep unchanged      |
<!-- markdownlint-enable MD013 -->

Three notes on this table:

- **The current conversion only covers the first four kinds, and only partly.**
  It deletes three elements, renames one, rewrites two values, and misses every
  attribute, every element that has to be added, and every value domain.
- **`ArrangementClipsListWrapper` and `TakeLanesListWrapper` are empty
  markers**, not containers.  Both are `<Wrapper LomId="0"/>` with no children.
  They are Live 12's way of saying "there is a list here"; Live 11 says it
  differently. So they are deletions, not moves.
- **The move kind was expected but is not confirmed.** The demo sets put the
  session clips and the take lanes in the same place in both versions
  (`ClipSlotList` appears 33 times in each). Nothing in the demo sets needs to
  move. The 460-set corpus would be the place to look for a move.

### The lane values

The lanes are the one known crash risk. A lane is identified by the container it
is in and its `Type` value, and the set of lanes is the same in every set of a
given Live version:

| Live version | `ContentLanes` types | `ExpressionLanes` types |
| ------------ | -------------------- | ----------------------- |
| 11           | 4, 5                 | 0, 1, 2, 3              |
| 12           | 2, 3, 4              | 0, 1, 2, 3, 5           |

Converting Live 12 to Live 11 therefore produces lanes of `Type` 2 and 3 in
`ContentLanes` and `Type` 5 in `ExpressionLanes`, none of which Live 11 has ever
had.

The two families use the same numbers for different things: `Type` 2 in
`ContentLanes` is not `Type` 2 in `ExpressionLanes`. There is no mapping between
the two versions' lane numbering, because the numbering is per family and per
version.

This is already tracked. **TODO N42** says:

> The Live 12 lane numbering is not portable to Live 11, and the round-tripped
> set keeps lane `Type` values that Live 11 does not understand. This is the
> main unresolved compatibility risk.

**TODO T1** asks for the conversion contract to be made explicit by asserting
the supported lane types. What to *do* with a lane the target does not have —
drop it, map it, keep it, or refuse to convert — is an open research question.
It is not top priority, and the research is tedious.


## What must change

Seven things.

### The conversion must become a transform

The conversion is a difference between two XML formats, and a transform is how
that difference is expressed: the difference list becomes a set of transformations
that are applied, rather than code that patches a document in place.

The transform is Ruby, not XSLT. The stylesheet was written first and then
replaced, because a transformation is an entry in a list in Ruby and a template in
XSLT: in XSLT the up direction needs a second template for every transformation,
while in Ruby
the same list is read the other way. `docs/fix_plan2.md` says why, and
`lib/live_set/tx/` holds the result.


### The differences must be written down as transformations, not discovered each time

Today the list is six hand-written edits inside the conversion code. A new Live
release means a new audit of the format, by eye, from scratch.

The baselines are what makes the audit tractable. Section 5 describes what a
baseline is: the minimum ALS for a version. Comparing the baselines of two
versions shows what differs between those two formats, with no song content in
the way.

What the comparison shows and what it means are different things. It shows that
`MainTrack` sits at a path where Live 11 has `MasterTrack`; it cannot show that
they are the same element. That is a judgement, made when the transformation is written.

### The differences must be sorted by kind, and the non-obvious ones hand-written

Section 2.2 lists eight kinds. Each is a different operation:

| Kind                          | How it is expressed                                                                   |
| ----------------------------- | ------------------------------------------------------------------------------------- |
| delete an element             | a transformation that matches it and emits nothing                                    |
| delete an attribute           | a transformation that matches the attribute and emits nothing                         |
| rename an element             | a transformation that matches the old name and emits the new one                      |
| rewrite an attribute value    | a transformation that matches the attribute and writes a new value                    |
| add an element with a default | a transformation that copies the parent and appends the new child                     |
| filter by value               | a transformation that matches the element and emits it only when its value is allowed |
| move an element               | copy it to the new parent, and suppress the original                                  |
| keep everything else          | the identity transformation                                                           |

All seven operations were exercised against a miniature ALS document and all seven work in
XSLT 1.0, which is what Nokogiri implements.

**Which of the eight a baseline comparison can decide, and which it cannot:**

| Difference                                 | Decided by the baseline comparison?                                     |
| ------------------------------------------ | ----------------------------------------------------------------------- |
| Element in one version and not the other   | yes, by path                                                            |
| Attribute in one version and not the other | yes, by path                                                            |
| Attribute value respelled                  | no — the comparison shows *that* the value differs, not what it becomes |
| Element renamed                            | no — by inspection                                                      |
| Element moved                              | no — by inspection                                                      |
| Value not legal in the target              | no — needs the value domain, "Value domains"                            |
| Element to be added, and its default       | no — by inspection                                                      |

**The transformations are written by hand.** Nothing produces them automatically. The
comparison of the two versions' baselines is information for the person writing
them.

### Attributes have to be part of the difference list

521 of the 539 errors are attributes the target version does not have. The
schemas know which attributes exist in which version, so the transformations can delete
them by name.

The blind text substitution at line 121 has to go with them. It works by luck:
the string `AudioOut/Main` happens to appear only as the value of
`Target/@Value` in these sets. A substitution over serialized XML cannot know
that, and will happily rewrite text content or an element name if the string
ever appears there. It has to be a transformation about one specific attribute on one
specific element.

### Elements have to be able to be added

Live 11 puts `VelocityDetail` and `NeedArrangerRefreeze` on every MIDI track.
Live 12 has neither.  A converted set has to grow them, with the values Live 11
writes (`Value="0"` and `Value="true"`).

This is not a small correction. It means the Live 11 → Live 12 direction is
*bigger* than the Live 12 → Live 11 direction, because it has to invent
everything Live 12 added:

| Live 11 → Live 12 has to |                                                                                                                                 |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| add elements             | `IsTuned`, `ControllerLayoutRemoteable`, `ControllerLayoutCustomization`, `TakeLanesListWrapper`, `ArrangementClipsListWrapper` |
| add attributes           | `SelectedToolPanel`, `SelectedGeneratorName`, `SelectedTransformationName`, `InitUpdateAreSlicesFromOnsetsEditableAfterRead`    |
| delete elements          | `VelocityDetail`, `NeedArrangerRefreeze`                                                                                        |
| rename elements          | `MasterTrack` → `MainTrack`, `ReWireSlaveMidiTargetId` → `ReWireDeviceMidiTargetId`                                             |
| rename values            | `AudioOut/Master` → `AudioOut/Main`, `Oversampling` `"1"`/`"0"` → `"true"`/`"false"`                                            |


### Value domains have to be known

The schemas say `xs:string` for every attribute, so they say nothing about which values are legal.
See "Value domains".

### The output has to be checked before it is reported as converted

The conversion prints `Conversion complete` and exits 0, whatever it produced. The 539 errors above
were found by validating the output separately, after the fact. Nothing in the conversion notices
that it produced a set Live 11 cannot open.

A vocabulary check is enough — every element name and every attribute name in the output has to be
one the target version has. The schema of the target version is where that list comes from: it
lists every element and every attribute of that version, so the names one version has and the
other does not are found by diffing one schema against the other. Full XSD validation is not: a
schema generated from one set makes 35,708 "required attribute" claims, most of which are
artifacts of that one set.


## The pieces

### The reader

An `.als` file is an XML document. Most are gzip-compressed, but uncompressed ones are used for
testing. `docs/als_work.md` has the method:

```ruby
require 'zlib'

def read_als(filepath)
  File.open(filepath, 'rb') do |file|
    Zlib::GzipReader.new(file).read # Attempt to read as Gzip
  rescue Zlib::GzipFile::Error
    file.rewind # If it's not a valid gzip file, rewind and read as plain text
    file.read
  end
end
```

Compression is not a property of a Live version, and it is not the comparator's business. Two sets
that differ only in compression are the same set, and everything downstream sees a
`Nokogiri::XML::Document` either way.

### The transforms

One transform per adjacent version_diff, in each direction:

```text
live_10 ──▶ live_11 ──▶ live_12
live_10 ◀── live_11 ◀── live_12
```

Each is a pure function from one document to another:

```text
live_12_to_live_11(source, baseline) -> document
```

Pure means the result depends only on the arguments and nothing outside is touched, so the same
source and the same baseline always give the same document. The baseline is an argument, not hidden
state.

Because they are pure, they compose. A conversion from Live 10 to Live 12 is the composition of the
two upward transforms, applied in memory, with no intermediate file ever written:

```ruby
document = live_10_to_live_11(document)
document = live_11_to_live_12(document)
```

One transform stands between two adjacent versions, and it stands on its own: no transform inherits
from another transform. The conversion from Live 12 to Live 9 is the composition of the transforms
between Live 12 and Live 11, Live 11 and Live 10, and Live 10 and Live 9 — there is no transform
between Live 12 and Live 9, and none of them inherits the ones it is built from.

The transforms are written by hand. Nothing produces them automatically.

### The baselines

One hand-maintained XML file per Live version, at the root of the repository:

```text
baselines/live_10.xml
baselines/live_11.xml
baselines/live_12.xml
```

They are read at run time, not computed. The target version's baseline is the starting point of a
transform, so the output of a conversion has the target version's structure by construction. See
"Baselines".

The directory is not packaged in the gem. `live_set.gemspec` has a comment saying so, and saying
that it is not yet decided whether an installed user needs the baselines or only a developer does.

### The comparator

The comparator works on XML nodes. It corresponds nodes between two documents and reports each
difference as an action.

**Correspondence is by `Id`.** In the ALS format, a node that is an identifiable thing — a track,
a clip, a device, a scene — carries an `Id` attribute. That is the key. In XSLT it is a `key()`
declaration; in Ruby it is a hash index.

**The vocabulary of node types is the vocabulary of shapes.** An ALS document is uniform, so three
shapes cover it:

| Shape | What it is | What can be done with it |
| --- | --- | --- |
| `*[@Id]` | an identifiable thing | correspond it, copy it, move it |
| `*[@Value]` | a value | read it, rewrite it |
| `*` | a container | match it by path, recurse into it |

The semantic kind of a node — a track, an envelope point, a device parameter — is not one of
these shapes. It would take a hand-built vocabulary that the format does not publish, so the
comparator works on the shapes.

**The actions it reports:**

| Action | What it means |
| --- | --- |
| **upgrade** | the node is at a lower version than its counterpart |
| **downgrade** | the node is at a higher version |
| **lowest_common_denominator** | reduce both nodes to a form they can both take |
| **delete** | the node has no counterpart |
| **move** | the node is in both, at a different position |
| **create** | the node is needed but absent |

### The component

#### Inputs

| # | Input | Notes |
| --- | --- | --- |
| 1 | The source document | A `Nokogiri::XML::Document`, from `read_als`. |
| 2 | The source version | The format identifier, from the `<Ableton>` element's `MinorVersion`. |
| 3 | The target version | The same. |
| 4 | The target baseline | The baseline for the target version. |

#### Outputs

| # | Output | Notes |
| --- | --- | --- |
| 1 | The converted document | A `Nokogiri::XML::Document` in the target version's format. |
| 2 | A report | The differences, as actions. |

#### Capabilities

1. **Apply a chain of transforms in order, in memory.** No intermediate files.
2. **Find the chain for a version_diff.** Given a source version and a target version, work out
   the ordered list of transforms that connects them, in either direction.
3. **Pass a set through unchanged** when its header already says it is in the target version.
4. **Compare two sets** and report the differences as actions.
5. **Refuse to report success when something went wrong.** A failed stage, or an output with names
   the target version does not have, is an error, not a conversion.

#### What it must not do

- **Decide what the differences are.** That is the transformations' job. The component applies
  transformations; it does not write them.
- **Generate transformations at run time.** The transformations are written by hand and checked in.
- **Open Live.** Proving a converted set works is `docs/live_control_plan.md`'s job.
- **Lose material it does not understand.** The identity transformation copies everything the
  transformations do not mention, with its attributes. That is what makes it safe to run a transform written for one
  version against a set that contains something new.

### Putting it together

To compare two sets:

1. Read both with `read_als`.
2. Determine each one's version from its header.
3. **If a set's header already says it is in the desired version, pass the set as is.** Otherwise,
   transform it up to that version — upgrading the older one, never downgrading, because
   downgrading discards material and upgrading only adds defaults.
4. Compare the two, and report the differences as actions.

Upgrading rather than reducing to the lowest common denominator is a choice. Reducing to the
lowest common denominator is one of the actions the comparator can report, but it throws away
everything the newer version added, so it is not the strategy.

### Traps in XSLT 1.0

These are the things that will bite. The first one was found by testing, not by reading.

1. **A rename shadows every later transformation that matches the new name.** A transformation
   matching `MidiEditorLaneModel` that renames it to `ExpressionLane` wins over a later
   transformation matching `ContentLanes/ExpressionLane`, so the later one never runs.
   Transformations that depend on the *result* of
   a rename have to match the source name, or carry an explicit `priority`.
2. **Moving a node needs two halves.** Copy it to the new parent, and suppress the original. Leave
   out either half and the node is duplicated or lost.
3. **`xsl:attribute` replaces, it does not add.** A transformation that writes an attribute the element
   already has changes its value.
4. **`xsl:output indent="yes"` reformats the document.** That is helpful when two sets are going to
   be diffed, because it removes incidental whitespace differences. It also changes the file, so it
   has to be a deliberate choice, not an accident.
5. **Whitespace between elements is preserved** unless `xsl:strip-space` says otherwise.

### Open questions

1. **Which version do two sets get compared at?** Upgrading the older one is the strategy, but the
   target version still has to be chosen. The newest version both can reach is the obvious answer
   and has not been confirmed.
2. **Does the upgrade direction invent what it cannot know?** Going up, Live 11 → Live 12 has to
   add elements and attributes that Live 12 writes and Live 11 does not have. Some of those have
   sensible defaults. Others do not, and inventing a value is different from dropping one.
3. **Is the comparison byte-exact, or does it ignore `Id` counters?** Live renumbers `Id` attributes
   on save, so a byte-exact comparison across a round trip through Live will not hold.


## Baselines

### What a baseline is

The baseline for a Live version is the **minimum ALS for that version**:

- every element that is always present,
- carrying only the attributes that are always present,
- with the values Live writes for them.

It is the lowest frame into which material can be placed. It is not a file to be found; it is
discovered and then maintained by hand.

### How it was discovered

Take any set of that version and remove two things:

<!-- markdownlint-disable MD060 MD013 -->
| What to remove           | How to know what to remove |
| ------------------------ | -------------------------- |
| The optional attributes  | An attribute is required iff every instance carried it. The XSD generator already computes this: 35,708 of 35,716 attribute declarations in the Live 11 schema are `use="required"`.  |
| The members of the lists | An element is optional iff some instance of that parent lacked it. The XSD generator already computes this too: 99 of 44,695 element declarations in the Live 11 schema are optional. |
<!-- markdownlint-enable MD060 MD013 -->

Both are decided **per path**, not per element name, because the XSD generator produces one content
model per path. Live 11 has 31,190 content models against 1,808 distinct element names. That is
what makes the removal possible: the same element name can be required in one place and optional
in another.

What is left is the baseline.

The two halves of the derivation come from different places:

- **Which nodes to cut** comes from the schema, which is a specification.
- **The values that remain** come from an instance, which is any set of that version.

The schema knows that `EffectiveName` is a required attribute of `Name`. It does not know that the
value is `"Untitled"`.

### Why the baselines are what to compare

A demo set's difference from another demo set contains song content, which is noise. Two baselines
differ only in format.

Comparing baseline_11 against baseline_12, matching on path, shows:

| At the same path | 12 → 11 | 11 → 12 |
| --- | --- | --- |
| name in 11, not in 12 | delete | add |
| name in 12, not in 11 | add | delete |
| same name, attribute in one only | delete attribute | add attribute |
| same name, different value | rewrite the value | rewrite the value |
| same path, different element name | rename | rename |

The comparison is symmetric, so one comparison informs both directions.

**Not everything in that table can be decided by the comparison.** A rename is not obvious from it:
`MainTrack` and `MasterTrack` are the same element under two names, and so are
`MidiEditorLaneModel` and `ExpressionLane`, but a comparison cannot tell that from an unrelated
pair of elements that happen to sit at the same path. That is settled by inspection, and then
written into the transformations by hand. The same goes for value respellings, moves, and elements that have
to be added with a default.

### What the baseline is for

Two jobs:

- **It is the starting point of a transform.** The output of a conversion is built from the target
  version's baseline, so the output has the target version's structure by construction. A source
  element the target version does not have is never carried over, because the copy is explicit.
- **It is the comparator's frame.** It says which nodes are structure and which carry material.

### A baseline and a schema are opposite operations on the same corpus

The schema is the union of what can exist; the baseline is the intersection of what always exists.
The XSD generator's rule — "element optional iff some instance lacked it" — is the union. The
baseline is the intersection. They must not be confused: feeding a baseline to the XSD
generator would make every element in it required, which is wrong.

Ableton ships files that resemble the baselines, and they are worth knowing about:

| Kind | Where |
| --- | --- |
| The empty set | `Resources/Builtin/Templates/DefaultLiveSet.als` (Live 11, 12), `Resources/Versions/DefaultLiveSet.als` (Live 9, 10) |
| The empty set, per edition | `Resources/Core Library/Lessons/Sets/Live 11 Standard Empty.als` and siblings |
| The default track | `Resources/Core Library/Defaults/Creating Tracks/Audio Track/Default Audio Track.als`, `…/MIDI Track/Default MIDI Track.als` |
| An artist's template | `Resources/Core Library/Templates/` — `Quick Start Song.als`, `Vocal Recording.als`, `Podcast & Radio.als`, `8-Track Template.als`, `Demo & Sketch.als` |

They are useful as a check on a hand-maintained baseline, and the artist's templates are the same
idea at a different level: a template is a baseline that redefines what "empty" means to one
artist.

### One open question

**Are lanes part of a baseline, or are they list members that get stripped?** If lanes are
stripped, the lane `Type` question in 2.3 leaves the baseline comparison and has to be handled
separately. If lanes stay, a baseline carries each version's lane set, and the difference between
them — including the types the target version has never had — shows up in the comparison where it
belongs.


## Value domains

### The question

Every value in an `.als` file is stored in a `Value` attribute. The generated schemas type all of
them as `xs:string`, so a schema says nothing about which values are legal in a given version.

The lane `Type` is the case that matters, and it is the known crash risk. See "The lane values".

### What the other parsers do

Every other ALS parser and converter was looked at. **None of them records value domains.** They
all treat a value as an opaque string.

| Project | What it does | Value domains |
| --- | --- | --- |
| [`pyableton`](https://github.com/maranedah/pyableton) | Python library. `src/pyableton/constants.py` is four lines long and holds time-signature ids only. | none |
| [`als-parser`](https://github.com/live-daw-tools/als-parser) | Node library. Reads `Value` as a string. | none |
| [`als-parser`](https://github.com/jbremz/als-parser) | Python CLI. Extracts sample references and plug-in presets. | none |
| [`ableton-parser`](https://github.com/jake-g/ableton-parser) | Python CLI. Extracts tracks, devices, clips. | none |
| [`AbletonParsing`](https://github.com/R9295/ableton-parser) | Python parser. | none |
| [`abletron`](https://github.com/drj-io/abletron) | Node CLI. **The only other converter.** | none |
| [`Live Set Export`](https://ableton.github.io/export/) | Ableton's own SDK. Writes sets; does not read them. | types the properties it exposes |

Two of these are worth looking at closely.

**`abletron` is the only other converter, and it is much weaker than this one.** It rewrites the
root `<Ableton>` node and nothing else. Its README says:

> This script only updates the root `<Ableton>` XML node. Nodes may still exist in the XML file
> that are not compatible with the version you are targeting with this tool. In most of these cases,
> this will cause an error when loading the project.

**`als-parser` has the same problem this project has, in the same shape, and its author left a
TODO.** `lib/LiveSet.js` handles one version difference by checking for both spellings:

```javascript
// Live 12.something changed from MasterTrack to MainTrack
// TODO: some sort of abstraction for different versions?
// need to investigate how often this happens

if (_.has(this.#_parsed, 'LiveSet.MasterTrack.DeviceChain.Mixer.Tempo.Manual')) {
  ...
} else if (_.has(this.#_parsed, 'LiveSet.MainTrack.DeviceChain.Mixer.Tempo.Manual')) {
  ...
}
```

**Ableton's own Live Set Export SDK** is the only project here with any value typing at all. It
types the properties it exposes — tempo is 20 to 999 BPM, label colours are an enumeration of ten —
but it publishes no value domain for the format, and it does not read sets at all.

There is no published schema for the ALS format with typed values, and the format has no public
specification.

### What that means here

The value domains have to be produced by this project. There are three possible sources:

<!-- markdownlint-disable MD060 MD013 -->
| Source                 | What it gives                 | What it costs |
| ---------------------- | ----------------------------- | ------------- |
| The corpus             | The values that were seen, per element path, per Live version. The XSD generator can record these mechanically, the same way it records structure. | It records what was seen, not what is legal. A value never seen is indistinguishable from an illegal value. |
| Live itself            | The authority.                | It can only be consulted by opening sets in Live and seeing what it accepts. That is what `docs/live_control_plan.md` does. |
| Hand-written knowledge | The values that matter.       | Tedious, and it goes stale. |
<!-- markdownlint-enable MD060 MD013 -->

**The lane case is the good case.** The lanes are application state, not material, and the set of
lanes is the same in every set of a given Live version. So for the lanes the corpus gives the
complete answer rather than a sample of one.

### How a domain can be written down

XSD can express a value domain with a simple type restricted by enumeration. Because the XSD
generator produces one content model per path, a domain is representable per path:

```xml
<xs:simpleType name="Live11ContentLanesType">
  <xs:restriction base="xs:string">
    <xs:enumeration value="4"/>
    <xs:enumeration value="5"/>
  </xs:restriction>
</xs:simpleType>
```

The limitation is the same as the schema's other limitations: it says "these were seen", not "these
are legal". It is still worth writing down, because it turns a silent wrong value into a
validation error, and a transformation can filter against it.

### What to do with an illegal value

Open. Tracked as **TODO N42** and **TODO T1**. The options are to drop the lane, to map it to
another one, to leave it alone, or to refuse the conversion. The research needed to choose is
tedious and is not top priority.
