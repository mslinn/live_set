# Fix Plan: the model, the serializers, and the documents that describe them

## Context

The report of a set is written from a model of the set: the model holds the facts, and a
serializer writes them as markdown. The rules of that arrangement are written down in
[`als_architecture.md`](dev/als_architecture.md), "Target Architecture", and in
[`report_design.md`](dev/report_design.md), "Implementation".

This document holds the work that is left. An item that is done is not here.

The outstanding work of the gem as a whole is in [`TODO.md`](TODO.md), and the identifiers
there are the ones the code and the documents cite. Where an item of this plan is
outstanding work already logged there, this plan refers to it by its identifier.

## The principles

- **A model class represents one XML entity, and holds what the XML holds and nothing else.**
- **Every collection is a class of its own**, named for the things it holds.
- **A model does not write markdown.**
- **The numbering is added by the serializers.**
- **A serializer is initialized from a model instance**, and the hierarchy of the serializers
  mirrors the hierarchy of the models.
- **Where several serializers have common behaviour, that behaviour is extracted into a
  helper.**
- **The indent of a thing comes from its number**, and the outline is one list.
- **The terms are the ones in [`glossary.md`](glossary.md).**

## The TODOs in the code

Fifteen comments ask for something, in five files, and eight of them are in one file.

| Where                                                    | What it asks for                                                                                                        |
| -------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `lib/live_set/serializer/live_markup.rb:35`              | The icon of a track belongs in a base class for tracks, which should already exist.                                       |
| `lib/live_set/serializer/live_markup.rb:49`              | The indentation of a number belongs in a `HierarchicalNumber` class (**D2**).                                            |
| `lib/live_set/serializer/live_markup.rb:63`              | The number of levels of a number belongs in the same class (**D2**).                                                    |
| `lib/live_set/serializer/live_markup.rb:165`             | The method adds no value: delete it, and call `localize.to_s` at the call sites.                                        |
| `lib/live_set/serializer/live_markup.rb:204`             | The method does the job of `swatch` as well, and neither name says that it fills a table cell with a colour.             |
| `lib/live_set/serializer/live_markup.rb:217`             | The line of a track belongs in `LiveTracksSerializer`.                                                                   |
| `lib/live_set/serializer/live_markup.rb:235`             | The coloured name of a track belongs in `LiveTracksSerializer`.                                                          |
| `lib/live_set/serializer/live_markup.rb:250`             | The dark background is to be a configurable parameter, driven from a default style sheet.                                |
| `lib/live_set/serializer/live_markup.rb:268`             | The state of a track belongs in `LiveTracksSerializer`, and is to be renamed `full_status`.                              |
| `lib/live_set/serializer/live_markup.rb:288`             | The solo marker needs a style sheet, in markdown if that is possible, and in Ruby if it is not.                           |
| `lib/live_set/tx/live_12_to_live_11.xsl:5`              | The transformation should be dead code: verify that it is, and delete it if it is.                                       |
| `lib/live_set/model/live_device_cross_reference.rb:9`    | Search the code and the documents for the claim that the devices of a group track are replicated on its child tracks. It is false (**N41**). |
| `lib/als_nodes/als_nodes.rb:7`                          | A question, not work: the boilerplate of `--children \| jq -r '.[]' \| sort -u` is to be abbreviated.                    |

Two more comments cite an item of `TODO.md` and ask for nothing:
`lib/live_set/model/live_track_facts.rb:153` (**N56**) and `:186` (**N41**).

## The work

### 1. The packs of the set are a section of the report

`report_design.md` lists `## Referenced Packs` among the sections of the report, and the
report writes it as `### Referenced Packs`, under `## Test Environment`. The design is the
authority on the report: the packs a set refers to are a fact about the set, and the
section is a section of its own.

The work: the section moves out of `## Test Environment` and becomes a section of its own;
the three specs that expect it where it is are corrected — `spec/als_report/als_report_spec.rb`,
`spec/live_set/serializer/als_model_serializer_spec.rb` and
`spec/live_set/serializer/live_packs_serializer_spec.rb` — and the reports of the reference
sets are regenerated.

### 2. The reports of the reference sets are regenerated

The reports of the reference sets are written by `dev/als_generate_reference_reports` and
are checked in to the repository of the reference sets. Every change to the report is in
them, so they are regenerated and diffed, and the diff is what says what the change was.

### 3. The work that is in the plan of the serializers

[`serializer_plan.md`](dev/serializer_plan.md) holds the work that is left for the
serializers: the identity of a MIDI clip, and the spec of the missing samples.

## The questions that are still open

These are questions, not work, and they are in `TODO.md`:

- **N58** — should each asset of a set carry a hash of its own?
- **N59** — should the report carry a checksum of the tool that made it?
- **N60** — the report should fold when a reader clicks a node.

## The evidence

- The specs of the models and the serializers pass, and the spec of the report as a whole
  passes: `bundle exec rspec spec/live_set spec/als_report`.
- `bundle exec rubocop` is clean.
- The reports of the reference sets are regenerated and diffed:
  `ruby dev/als_generate_reference_reports`. The report must not change, except for what
  the work asks for.
- Every TODO and FIXME that is done is deleted, and every item of `TODO.md` that is done is
  deleted from it, in the manner `TODO.md` describes.
