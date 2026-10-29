# The Schemas Live Ships

Every version of Ableton Live ships a description of the format, in a directory
of its own:

```text
<Ableton home>/Live 11 Suite/Resources/Schema/
```

These are Live's own description of the format. They are not the schemas this
repository generates: see "The two kinds of schema", below.

What is known so far is written down here. What is not yet known is tracked as
**TODO L1** in [../TODO.md](../TODO.md).

## What the directory holds

One file per format version, named after the version:

```text
11.0_11300.txt
12.0_12402.txt
9.5_327.txt
```

The name is the format version, and the format version is the `MinorVersion`
attribute of a set. The Live 11 demo set says `MinorVersion="11.0_11300"`, and
`11.0_11300.txt` is a file in the directory. The Live 12 demo set says
`12.0_12402`, and that file exists too. **The schema of a set is therefore a
lookup, not a guess.**

Each file is XML, headed by the format version and two counters:

```xml
<AbletonSchema Version="5" TranslatorNumber="12402" ChangeCount="5">
```

Below that, the elements of the format are nested as they nest in a set, and
each carries a `Class` and a `Type`:

```xml
<AdsrScale>
  <EnvTime Class="TimeableFloat" Type="0" />
  <EnvTimeKeyScale Class="TimeableFloat" Type="0" />
  <EnvTimeIncludeAttack Class="TimeableBool" Type="0" />
</AdsrScale>
```

The `Class` names are the classes of the object model (`Bool`, `ClassId`,
`RemoteableInt`, `TimeableFloat`, …), and they are not the same thing as the
element names.

## Which versions an installation carries

An installation ships the schemas of the versions it can read, and of the
versions that came before it. What is on the machine here:

| Installation | Files | Format versions |
| --- | --- | --- |
| Live 8 | 6 | 8.1 |
| Live 9 Standard | 61 | 8.1, 8.2, 8.3, 9.0, 9.5 |
| Live 10 Standard | 86 | as Live 9, plus 10.0 |
| Live 11 Suite | 123 | as Live 10, plus 11.0 |
| Live 12 Suite | 203 | as Live 11, plus 12.0 |

So the union across the installations is Live 8.1 through Live 12.0, and the
newest installation is a superset of the others. The file count per format
version grows as the version accumulates schema changes:

| Format version | Files | Numbers |
| --- | --- | --- |
| 9.5 | 14 | 305 … 327 |
| 10.0 | 25 | 326 … 377 |
| 11.0 | 37 | 402 … 436, then 11201, 11202, 11300 |
| 12.0 | 80 | 12000 … 12402 |

The number in the file name is the second half of the format version. Within
a version the numbers are not consecutive, because a schema change is written
whenever the format changes, and the last number of a version is that
version's final format:

| Version | Final format |
| --- | --- |
| Live 9 | 9.5_327 |
| Live 10 | 10.0_377 |
| Live 11 | 11.0_11300 |
| Live 12 | 12.0_12402 |

## The two kinds of schema

This repository generates its own XSDs, and Live ships its own. They are
different artifacts and they are not interchangeable.

| | The XSDs in `schemas/` | The schemas Live ships |
| --- | --- | --- |
| Where they come from | inferred from the demo sets of that version | written by Ableton |
| What they are | XML Schema, for validation | a description of the object model |
| How complete | as complete as the demo sets | complete for the version |
| Where they live | `schemas/`, checked in | the installation, `Resources/Schema/` |

The difference in completeness is not subtle, and it is measurable.
`schemas/vocab_11.3d1.txt` holds the 1875 element names of the inferred Live
11 schema. `schemas/vocab_live11.txt` holds 1989 — 114 more. Every one of
those 114 names (`BandFreq1`, `BasePitch`, `Amplitude`, `Crc`, …) is present in
Live's own schema for 11.0, and none of them is missing from it.

So those 114 names are not stale or mistaken. They are real Live 11 elements
that no Live 11 demo set happens to contain, and the inferred schema cannot
know about them. `BandFreq1` is in none of the Live 11 demo sets, nor in
`sets/live_11/Fascination.als`.

**The inference is the weaker source, and the difference is largest exactly
where it matters** — in the elements that the sample sets do not exercise.

## What this is good for

The version_diff documents enumerate the differences between two versions, and
those differences are currently found by diffing two inferred schemas. Live's
own schemas are the authoritative statement of what each version contains, so
diffing two of them gives the element-level differences directly, without the
inference in the way.

The same applies to the versions with no version_diff document yet: Live 8,
Live 9 and Live 10 all have schemas in the directories of the installations
here, so the differences between those versions can be established from the
same source rather than inferred from sample sets.

## What is not yet known

- Whether the files describe the nesting of the elements as completely as a set
  nests them, which decides whether they can also give the order of the
  children of an element. The samples show the nesting; whether it is
  exhaustive has not been checked.
- Whether the format version of a set always has a schema file, for every
  version and every point release. The demo sets match, but a set written by a
  later point release of a version may name a number that is not the last one.
- Whether the `Class` and `Type` attributes say anything useful about the
  values an element holds, which would bear on the value domains that
  [conversion.md](conversion.md) raises.

**TODO L1** in [../TODO.md](../TODO.md) tracks this.
