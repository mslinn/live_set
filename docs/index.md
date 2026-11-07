# Documentation Index

What each document in this repository is for, and where the code lives.

Read this first. It is the map; the documents it points at are the detail.

## The documents in `docs/`

| Document | What it is for |
| --- | --- |
| [`TODO.md`](TODO.md) | The outstanding work, with stable identifiers (`T1`, `N42`, `GH1`, `L1`, …) that the code and the other documents cite. |
| [`glossary.md`](glossary.md) | Defines the terms used in this project. |
| [`als_notes.md`](als_notes.md) | Notes on the ALS file format: what the XML looks like, and the shapes it takes. |
| [`als_architecture.md`](als_architecture.md) | Describes how this project models the XML, transforms it, and serializes it to markdown. |
| [`als_work.md`](als_work.md) | How the format is reverse engineered: the XML tools, the corpora (the Ableton demo sets and the other sets in the reference corpus), and how the test suite is arranged. |
| [`serializer_plan.md`](serializer_plan.md) | Remaining work on the serializers in `lib/live_set/serializer/`. |
| [`cpfir.md`](cpfir.md) | The architectural guide to composing bidirectional transformations in Ruby: pure function composition, the version-keyed registry, the composition of the bridges between two versions, the classes of a conversion, and how two sets are compared. |
| [`conversion.md`](conversion.md) | What the conversion has to become: the kinds of difference between two Live versions, the pieces of the component, the traps of XSLT 1.0, and the problem of value domains. It is a design document, written before the transform was written in Ruby. |
| [`live_11_12_diff.md`](live_11_12_diff.md) | **The differences between two versions.** A summary of them; the transformations that follow from them are in `lib/live_set/tx/live_11_and_12.rb`, and the headings are what the code cites. |
| [`live_schemas.md`](live_schemas.md) | TODO: this is not true: **The schemas Live ships.** Every installation carries a description of the format, one file per format version; these are Live's own, and more complete than the XSDs this repository infers. The open questions are tracked as **TODO L1**. |
| [`ab_test_plan.md`](ab_test_plan.md) | **The PROGRAM.** Nearly-empty Live 11 sets, one thing in each, written by Live 11 and by Live 12 and compared: how a case is made, where the sets live, what the factory-default set holds, and the questions that are still open. |
| [`report_design.md`](report_design.md) | How a set report is written from. |
| [`release_notes/index.md`](release_notes/index.md) | The release notes of Live 8 through Live 12, downloaded from Ableton's web site and kept in `release_notes/`, one HTML file per version. They are the evidence for what each version changed, and where they came from and how they were obtained is written down there. |

## Transformations

The transformations of a version_diff are written by hand, and the process for
finding them is written down:

| Question | Where it is answered |
| --- | --- |
| Kinds of differences | [`conversion.md`](conversion.md), "The kinds of difference" |
| How a transforms compose | [`cpfir.md`](cpfir.md), "The Lifecycle of a Conversion" |
| How a bridge stands on its own, and how a conversion composes the bridges between them | [`cpfir.md`](cpfir.md), "Dynamically Slicing the Pipeline Intervals" |
| How a transformation is written | [`conversion.md`](conversion.md), "The differences must be sorted by kind, and the non-obvious ones hand-written" |
| Elements and attributes for a Live version | [`als_work.md`](als_work.md), "Mapping XSD to Ruby Classes" — the schema is the index of the format, and two schemas are diffed to find the differences. Live ships schemas of its own, which are more complete; they are in [`live_schemas.md`](live_schemas.md) |
| The differences between Live 11 and Live 12 XML | [`live_11_12_diff.md`](live_11_12_diff.md) |
| Transformation between 11 and 12 | `lib/live_set/tx/live_11_and_12.rb` — the lists, the special transformations, and the comment block that describes how the conversion works |

## Code Map

| Function | Source Code File |
| --- | --- |
| Reading a set, converting it, writing it out | `lib/als_to_version/live_set_converter.rb` |
| The tools for looking inside sets | `exe/als_nodes`, `exe/als_diff`, `exe/als_to_xsd`, `exe/als_xsd_order`, `exe/als_validate` |
| The colours of Live, and the markup the report is written with | `lib/live_set/model/live_palette.rb` and `lib/live_set/serializer/live_markup.rb` |
| The machinery the transformations run on | `lib/live_set/tx/live_version_converter.rb` — knows nothing about any particular version_diff |
| The registry of the bridges, keyed by the version each one leads to | `lib/live_set/tx/live_versions.rb` — the conversion from one version to another is the composition of the bridges between them |
| The transformations of the Live 11 ↔ Live 12 conversion | `lib/live_set/tx/live_11_and_12.rb` — the lists, the special transformations, and the comment block that describes how the conversion works |
| One example per transformation, in each direction | `spec/live_set/tx/live_11_and_12_down_spec.rb`, `spec/live_set/tx/live_11_and_12_up_spec.rb` |
| The end-to-end check | `spec/live_set/tx/live_conversion_spec.rb` — converts the Live 12 demo set and validates the result against the Live 11 schema |
| Live release notes | `exe/als_release_notes` — Live release notes of for each supported version. |
| ALS XML schemas | generated into the `xsd/` directory of the repository of the reference sets by `dev/generate_xsds`; checked in, so a new contributor and a new machine can use them without installing Live |


## Reference Sets and Reports

Reference sets and their reports are stored in the [reference set repository](https://github.com/mslinn/live_reference_sets/), present on developer
computers at the location that the environment variable `live_reference_sets` points to.
