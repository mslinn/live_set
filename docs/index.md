# Documentation Index

What each document in this repository is for, and where the code lives.

Read this first. It is the map; the documents it points at are the detail.

## The documents in `docs/`

| Document | What it is for |
| --- | --- |
| [`glossary.md`](glossary.md) | **The TERMS.** The words the other documents use, and what each of them means here. |
| [`als_notes.md`](als_notes.md) | **The WHAT.** The ALS file format itself: what the XML looks like, and the shapes it takes. Its headings are what the code cites. |
| [`live_11_12_diff.md`](live_11_12_diff.md) | **The differences between two versions.** A summary of them; the transformations that follow from them are in `lib/live_set/tx/live_11_and_12.rb`, and the headings are what the code cites. |
| [`als_work.md`](als_work.md) | **The HOW-TO.** How the format is reverse engineered: the XML tools, the two corpora (the Ableton demo sets and the 460-set corpus), how the schemas are generated, and how the test suite is arranged. It was written before the code was rewritten, and it is being reconciled with the code — the open items are in `fix_plan2.md`, Phase 3. |
| [`fix_plan2.md`](fix_plan2.md) | The plan for the Live 12 → Live 11 conversion in Ruby: why the XSLT stylesheet was replaced by Ruby code, the architecture (a base class and one subclass per version_diff), and the open items in Phase 3. |
| [`cpfir.md`](cpfir.md) | The architectural guide to composing bidirectional transformations in Ruby: pure function composition, the version-keyed registry, the pipeline, and how two sets are compared. |
| [`conversion.md`](conversion.md) | What the conversion has to become: the kinds of difference between two Live versions, the pieces of the component, the traps of XSLT 1.0, and the problem of value domains. It is a design document, written before the transform was written in Ruby. |
| [`live_control_plan.md`](live_control_plan.md) | The plan for proving a conversion by round-tripping it through Ableton Live under program control, using the `gui_harness` gem. |
| [`release_notes/index.md`](release_notes/index.md) | The release notes of Live 8 through Live 12, downloaded from Ableton's web site and kept in `release_notes/`, one HTML file per version. They are the evidence for what each version changed, and where they came from and how they were obtained is written down there. |

**The release notes are not installed with Live.** No version of Live puts a
copy of its release notes on the computer; they are published on Ableton's web
site only.

**When two documents disagree:** `fix_plan2.md` settles what it has settled.
`als_notes.md` and the version_diff documents describe the format and the
differences between two versions, and the code follows them. `conversion.md` and
`als_work.md` are design documents, written before the transform was written in
Ruby, so where they disagree with the code they are describing what was
planned.

## The terms the documents use

The words used throughout the documents are defined in
[`glossary.md`](glossary.md). A reader who meets one of them and does not know
which sense it is used in should go there first.

## The headings the code cites

The code cites the headings of two documents. The headings used to carry section
numbers, which were the ones `docs/als_format.md` had; that document is not in
this repository, and it was split into `als_notes.md` and a version_diff
document. The numbers are gone, and the headings are cited instead.

| Heading | Lives in |
| --- | --- |
| Converting a set to Live 11 uses a fixed schema | `live_11_12_diff.md` |
| The elements the two versions name differently | `live_11_12_diff.md` |
| The values the two versions write differently | `live_11_12_diff.md` |
| The lane types | `live_11_12_diff.md` |
| The lane types Live 11 does not have | `live_11_12_diff.md` |
| Every value is stored in a `Value` attribute | `als_notes.md` |
| Where a track's audio is | `als_notes.md` |
| The sample references of a clip | `als_notes.md` |
| Whether a sample has been collected | `als_notes.md` |
| The devices of a chain, and the plug-ins among them | `als_notes.md` |
| The device chain, and the chains nested inside it | `als_notes.md` |
| The group tracks | `als_notes.md` |
| A group track holds no clips | `als_notes.md` |
| A member track names its group | `als_notes.md` |
| The device chain of a group | `als_notes.md` |
| Freezing a group track | `als_notes.md` |
| The `Options.txt` hidden option | `als_notes.md` |
| The two sequencers of a track, and the frozen track that keeps both | `als_notes.md` |

## How a transformation is found

The transformations of a version_diff are written by hand, and the process for finding them is written down:

| Question | Where it is answered |
| --- | --- |
| What kinds of difference there are, and what each one is | [`conversion.md`](conversion.md) §2.2 |
| Why a transform is not directional, and how it composes | [`cpfir.md`](cpfir.md) §4 |
| How a transformation is written, and why nothing writes it for you | [`conversion.md`](conversion.md) §3.3 |
| Which elements and attributes a version has | [`als_work.md`](als_work.md), "Mapping XSD to Ruby Classes" — the schema is the index of the format, and two schemas are diffed to find the differences |
| The differences between Live 11 and Live 12 in particular | [`live_11_12_diff.md`](live_11_12_diff.md) |
| The transformations themselves | `lib/live_set/tx/live_11_and_12.rb` — the tables, the special transformations, and the comment block that describes how the conversion works |

## Where the code is

| Thing | Where it lives |
| --- | --- |
| The transformations of the Live 11 ↔ Live 12 conversion | `lib/live_set/tx/live_11_and_12.rb` — the tables, the special transformations, and the comment block that describes how the conversion works |
| The machinery the transformations run on | `lib/live_set/tx/live_version_converter.rb` — knows nothing about any particular version_diff |
| The seam that finds the bridge for a set | `lib/live_set/live_set_transformer.rb` |
| Reading a set, converting it, writing it out | `lib/live_set/live_set_converter.rb` |
| One example per transformation, in each direction | `spec/live_set/tx/live_11_and_12_down_spec.rb`, `spec/live_set/tx/live_11_and_12_up_spec.rb` |
| The end-to-end check | `spec/live_set/tx/live_conversion_spec.rb` — converts the Live 12 demo set and validates the result against the Live 11 schema |
| The tools for looking inside sets | `exe/xml_nodes`, `exe/xml_diff`, `exe/generate_xsd`, `exe/xsd_order`, `exe/validate_asd` |
| The schemas | generated into `schemas/` by `bin/generate_xsds`; not in the repository, so each computer generates its own |

## The superseded documents in `docs/old/`

| Document | What it is for |
| --- | --- |
| [`old/fix_plan.md`](old/fix_plan.md) | The earlier plan, written when the transform was to be an XSLT stylesheet. Superseded by [`fix_plan2.md`](fix_plan2.md). |
| [`old/composing_pure_functions_in_ruby.md`](old/composing_pure_functions_in_ruby.md) | The long form of the architecture guide. Superseded by [`cpfir.md`](cpfir.md). |

## Documents outside `docs/`

| Document | What it is for |
| --- | --- |
| [`../README.md`](../README.md) | What the program does, how to install and use it, and the sample report. |
| [`../TODO.md`](../TODO.md) | The outstanding work, with the identifiers (`T1`, `N42`, `GH1`, …) that the code and the other documents cite. |
| [`../sets/README.md`](../sets/README.md) | The reference sets checked into this repository, and why each one is here. |
