# Documentation Index

What each document in this repository is for, and where the code lives.

Read this first. It is the map; the documents it points at are the detail.

## `docs/`

- [`TODO.md`](TODO.md): The work backlog, with stable identifiers (`T1`,
  `N42`, `GH1`, `L1`, …) that the code and the other documents cite.
- [`glossary.md`](glossary.md): Defines the terms used in this project.
- [`dev/als_notes.md`](dev/als_notes.md): Notes on the ALS file format: what the XML
  looks like, and the shapes it takes.
- [`dev/als_architecture.md`](dev/als_architecture.md): Describes how this project
  models the XML, transforms it, and serializes it to markdown.
- [`dev/als_work.md`](dev/als_work.md): How the format is reverse engineered: the XML
  tools, the corpora (the Ableton demo sets and the other sets in the reference
  corpus), and how the test suite is arranged.
- [`dev/cpfir.md`](dev/cpfir.md): The architectural guide to composing bidirectional
  transformations in Ruby: pure function composition, the version-keyed
  registry, the composition of the bridges between two versions, the classes of
  a conversion, and how two sets are compared.
- [`dev/conversion.md`](dev/conversion.md): What the conversion has to become: the kinds
  of difference between two Live versions, the pieces of the component, the
  traps of XSLT 1.0, and the problem of value domains. It is a design document,
  written before the transform was written in Ruby.
- [`dev/live_11_12_diff.md`](dev/live_11_12_diff.md): **The differences between two
  versions.** A summary of them; the transformations that follow from them are
  in `lib/live_set/tx/live_11_and_12.rb`, and the headings are what the code
  cites.
- [`dev/live_schemas.md`](dev/live_schemas.md): **Discussion on the schemas Live
  ships.** Every Live installation carries a description of the format, one file per
  format version; these are Live's schema, and more complete than the XSDs this
  repository infers. The open questions are tracked as **TODO L1**.
- [`dev/ab_test_plan.md`](dev/ab_test_plan.md): Early thoughts on the reverse
  engineering procedure using nearly-empty Live 11 sets, one thing in each,
  written by Live 11 and by Live 12 and compared: how a case is made, where the
  sets live, what the factory-default set holds, and the questions that are
  still open.
- [`dev/report_design.md`](dev/report_design.md): How a set report is written.
- [`report_context.md`](report_context.md): What `als_report` is given, and what it does
  with it: the path to a set or to a project, the two contexts, and the decisions about the
  command.
- [`release_notes/index.md`](release_notes/index.md): The release notes of Live
  8 through Live 12, downloaded from Ableton's web site and kept in
  `release_notes/`, one HTML file per version. They are the primary evidence for
  what each version changed, and where they came from and how they were obtained
  is written down there.

## Transformations

The transformations of a version_diff are written by hand, and the process for
finding them is written down:

| Kinds of differences | [`conversion.md`](dev/conversion.md), "The kinds of difference" |
| How a transforms compose | [`cpfir.md`](dev/cpfir.md), "Composable Transforms" |
| How a bridge stands on its own, and how a conversion composes the bridges between them | [`cpfir.md`](dev/cpfir.md), "Dynamically Slicing the Pipeline Intervals" |
| How a transformation is written | [`conversion.md`](dev/conversion.md), "The differences must be sorted by kind, and the non-obvious ones hand-written" |
| Elements and attributes for a Live version | [`als_work.md`](dev/als_work.md), "Mapping XSD to Ruby Classes" — the schema is the index of the format, and two schemas are diffed to find the differences. Live ships schemas of its own, which are more complete; they are described in [`live_schemas.md`](dev/live_schemas.md) |
| The differences between Live 11 and Live 12 XML | [`live_11_12_diff.md`](dev/live_11_12_diff.md) |
| Transformation between 11 and 12 | `lib/live_set/tx/live_11_and_12.rb` — the lists, the special transformations, and the comment block that describes how the conversion works |

## Code Map

- [Reading a set, converting it, writing it out](../lib/als_to_version/live_set_converter.rb)
- [What a report is about, and what it may say](../lib/live_set/report_context.rb)
- [The report of a project](../lib/live_set/serializer/live_project_serializer.rb)
- [Tools for looking inside sets](../exe/als_nodes), [als_diff](../exe/als_diff), [als_to_xsd](../exe/als_to_xsd), [als_validate](../exe/als_validate)
- [Live colour palette](../lib/live_set/model/live_palette.rb)
- [Generated markup](../lib/live_set/serializer/live_markup.rb)
- [Transformation machinery](../lib/live_set/tx/live_version_converter.rb)
- [Bridge registry](../lib/live_set/tx/live_versions.rb)
- [Live 11 ↔ Live 12 conversion transformations](../lib/live_set/tx/live_11_and_12.rb)
- [Up transformation example](../spec/live_set/tx/live_11_and_12_up_spec.rb)
- [Down transformation example](../spec/live_set/tx/live_11_and_12_down_spec.rb)
- [End-to-end round-trip (validation by converting up and back down)](../spec/live_set/tx/live_conversion_spec.rb)
- [Live release notes](../exe/als_release_notes)


## Reference Sets and Generated Reports

Reference sets and their reports are stored in the [reference set repository](https://github.com/mslinn/live_reference_sets/), present on developer
computers at the location that the environment variable `live_reference_sets` points to.
