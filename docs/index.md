# Documentation Index

## End User Docs

- [Glossary](glossary.md)
- [Command-line programs](commands/)
- [Live release notes](release_notes/index.md)
- [Push 3 Standalone (P3S) notes](p3s.md)
- [Two report modes](report_context.md)
- [TODO](TODO.md): The work backlog, with stable identifiers (`T1`,
  `N42`, `GH1`, `L1`, …) that the code and the other documents cite.

## Developer Docs

- [ALS XML](dev/als_notes.md)
- [Architecture](dev/als_architecture.md)
- [OSC](dev/osc.md)

### Reports

- [Collapsable lists](dev/collapsible_lists.md)
- [Collapsable mockup](dev/collapsible_mockup.md)
- [Report design](dev/report_design.md): How a set report is written.

### Reverse Engineering

- [Reverse engineering ALS XML](dev/als_work.md)
- [Early thoughts on reverse engineering procedure](dev/ab_test_plan.md)

### XML Conversions

- [Composing bidirectional transformations in Ruby](dev/cpfir.md)
- [ALS XML conversion](dev/conversion.md) This design document was written
  before the transform was written in Ruby.
- [Differences between Live 11 and 12 XML](dev/live_11_12_diff.md)
- [Live XML Schemas](dev/live_schemas.md)


## Reference Sets and Generated Reports

Reference sets and their reports are stored in the [reference set
repository](https://github.com/mslinn/live_reference_sets/), present on
developer computers at the location that the environment variable
`live_reference_sets` points to.
