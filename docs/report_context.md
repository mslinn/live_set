# Expanding the Scope of `als_report`

`als_report` examines ALS XML if it is passed a path to an `.als` file. If it is
passed a path to an Ableton Live `Project` directory, it reports a summary of
the contents, which includes an `.als` file.

The generated report needs to state up front what it is reporting, (ALS file
only or entire Live project), the path it was given, the machine it worked on.
Some of this is already reported; we just need to provide additional context
when an entire project is being reported on.

Two reports of the same set — one made from the project the set was saved in, one made
from the ALS file alone — differ in half of their sections.

The report states the context it worked from, and the sections that depend on the context
are written only in the context that supports them.

For the most complete results, the report should be generated on the computer
that the set was created from.

## What is given to the command

The path given to the command decides the context. There is no switch that chooses it.

- `als_report path/to/blah.als` — the command is given a set. It reports that set, and
  the XML in it.
- `als_report path/to/project` — the command is given a directory, and not a set. It
  reports the project: every `.als` file it holds.
- `als_report path/to/project --als blah.als` — the command is given a project, and
  only the named set of it is reported.

The `--als` option names a set of the project. It may be given more than once, and each
name is either the name of a file in the project (`--als blah.als`) or a path relative to
the project (`--als Sets/blah.als`).

A project is reported as a report for each of the sets it holds. The part of a report that
belongs to a set is repeated for every set, and the reports are written one after another.

The facts that are the same for every set of the project are written once, above the
reports of the sets, so that a reader sees what is common before what is specific to a
set. Those facts are the context, the path that was given, the machine the report was made
on, the times of the project folder, the time the report was made, the time zone the times
are written in, and — with `--report_machine` — the state of the machine.

```markdown
# `Song Project`

| Context              | This report pertains to the Live sets contained in "Song Project" folder. |
| Directory            | `/mnt/f/work/music/Song Project`                                         |
| On computer          | `Bear`                                                                    |
| Project created      | 2026-11-05 11:58:42                                                      |
| Project last modified| 2026-11-05 11:58:42                                                      |
| Report generated     | 2026-11-11 21:50:16 by live_set v0.2.6                                  |
| Time zone            | America/Toronto (UTC-5)                                                  |

# `Song.als`

| Format              | Set                                    |
| Revision            | 29bb8f2920bd08036a270fd62ef54610b5b8d4fd |
| SchemaChangeCount   | 3                                      |
| Set created         | 2026-11-05 11:18:19                   |
| Set last modified   | 2026-11-05 11:18:19                   |
| Written by          | Ableton Live 11.3.13                   |

## Metadata
...
```

A set's own report is not otherwise changed: its title, its facts table, and its sections
are as they are.

## The two contexts

### A lone set

The report is given one file: `song.als`.

**What is known.** The XML in the file: the tracks and the things under them, the clips and
the samples they name, the files the set refers to, the size and the checksums of the file,
the version of Live that wrote it, and the verdict for a transfer to a P3S Standalone.

**What is not known.** The project the set was saved in, the samples that were collected
into it.

**What is known about the test computer** the packs that are installed, the content of the
Live user library, and the state of the machine. Note that if the
Live set came from another computer, these facts are not known.

**What the report says.** What the XML holds, and that nothing else was looked
at. It cannot say which samples are missing. It can report the packs installed
on the computer that ran `als_report`, but if that is not the same computer that
was used to create the Live set, then that information is not available.

### A project

The report is given the path to a project folder: the set, the folder it is
saved in, the samples collected into that folder, and the content of the
machine.

**What the report adds.** Which of the samples the set names are collected into
the project and which are not, the assets the project holds, the packs the set
refers to, and — when `--report_machine` is given — which of the packs are installed,
which of the external samples the machine has, and the state of the machine: the
'Ableton Project Info' folders around the set, and what the machine knows about
the files the set names.

## What the report says about the context

One line, in the header table of the report, beside the facts about the file:

| The context | The line |
| --- | --- |
| A lone set | `This report pertains to ALS XML, without a project folder.` |
| A project | `This report pertains to the Live set contained in "XYZ Project" folder.` |

Add a command line switch, --report_machine, to enable the information about the
machine als_report ran on.


## The samples of the set

A sample of a set is either **collected into the project** or **external** to it.

A collected sample is in the project folder, and it is always located: that is a fact of
the project, and the report says so in either context.

An external sample is in the user library, in a pack, in the Live core library, or in a
random place: a path that Live wrote for a file that was on another machine, or one that
leaves the project folder. The random ones are the hard-to-find ones, and they are the
reason the report names the path of every file the set refers to.

Whether an external sample is on the machine that ran the report is a fact of the
machine, and not of the set: a set that was made on another computer names files that are
not here. The report says where an external sample comes from in either context, and
whether it is on this machine only when `--report_machine` is given.

## What each section means in each context

- `## Metadata` — the size and the checksums of the file, in either context.
- `## P3S Standalone` — the verdict, from what the XML says, in either context.
- `## Groups/Tracks/Clips/Devices` — the outline of the set, in either context.
- `## Set Assets` — the samples the set has of its own, as the XML names them, in either
  context; in the context of a project, where they are as well.
- `## Located Samples` — the samples that are collected into the project, and the external
  ones that the machine has. The collected samples are always here; an external one is
  here only when the machine has it, which is written only with `--report_machine`.
- `## Missing Samples` — the samples that are not collected into the project. Whether one
  of them is on the machine is a fact of the machine, and is written only with
  `--report_machine`.
- `## Referenced Packs` — the packs the set refers to, in either context.
- `## Test Environment` — the machine: the installed packs, the missing packs, the
  'Ableton Project Info' folders. Only when `--report_machine` is given.

A section that a context does not support is not written. The report says nothing about
what it did not look at.

## The packs

A pack is a folder of content that Ableton makes available for download. A set
can contain references to samples in various packs. For the samples to be
available, the pack must be installed.

**A pack reference is not an asset.** An asset is a thing that is physically
available: a sample collected into the project, or an image. A pack is always
external to a project; it is available on the machine, or it is not, and the set
does not hold it. So the packs of a set are not assets, and they are not part of
the assets of the project.

However, `collect and save` copies all pack references into the project
directory. what happens to the external reference? is the source of the assets
remembered, but the reference now points to the collected copy? we should read
the ableton documentation, and only look at the XML if necessary, because until
we write some more code spelunking through a tangle of references will be
problematic.

**The packs the set refers to** are a fact of the set: the XML names them. **The
packs that are installed** are a fact of the machine. The report writes them
apart:

```markdown
## Referenced Packs

- **Some Pack**: `Packs/Some Pack`

## Test Environment

### Installed Packs

- **Some Pack**: `/mnt/c/Users/Mike/.../Packs/Some Pack`

### Missing Packs

- **Other Pack**
```

`Referenced Packs` is a section of the report. `Installed Packs` and `Missing Packs` are
sections of the test environment.

## The decisions

1. **The statement is written once, with the facts it belongs to.** In the context of a
   project it is a row of the common table, labelled `Context`, with the sentence as its
   value; in the context of a lone set it is a row of the table of the set. In the context
   of a project with more than one set, the sentence is the plural one.
2. **The report of a lone set says what the XML holds, and that nothing else was looked
   at.** It does not say which samples are present, and it does not say which are missing.
3. **The rows about the project are written only in the context of a project.** `Project
   created` and `Project last modified` are facts about the project folder; in the context
   of a lone set there is no project, and they are not written. `Directory` names the
   project folder in the context of a project, and the folder the file is in in the context
   of a lone set.
4. **A project is reported as a common table and a report for each set.** The facts that
   are common to the sets of the project are written once, above the reports of the sets.
   The part of a report that is dedicated to a set is repeated for every set, and the
   reports follow the common table, one after another. A set's own report is not otherwise
   changed: its title, its facts table, and its sections are as they are.
5. **A name that `--als` gives that is not in the project is an error.** The command says
   so and stops, the way it does for a file that is not there.
6. **A report says nothing about the sets of a project it did not report.** The option is a
   filter, and the report is of what was asked for.
7. **The names of the sample sections keep their names for now.** `Located Samples` and
   `Missing Samples` are claims about the machine, and the report will say which of the two
   senses it is using. The wording is settled by reading generated reports.

## The work

1. The command takes a path to a set or to a project, and the `--als` option names the
   sets of a project to report.
2. The report states the context, in one line.
3. The sections a context does not support are not written.
4. The packs are written apart: the packs the set refers to, and the packs of the machine.
5. `docs/dev/report_design.md` is brought up to date with the sections of the report, and
   with the context each of them needs.
6. The reference reports are regenerated, and the specs of the report are corrected.
