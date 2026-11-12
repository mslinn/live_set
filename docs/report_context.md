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

The shape of the report — its sections, what each of them needs, and the rules that
govern them — is in [`dev/report_design.md`](dev/report_design.md). This document is
about what the command is given, and what it does with it.

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
the project (`--als Sets/blah.als`). A name that is not in the project is an error, and
so is a directory that holds no set. Any directory is a project, whether or not it was
made by Live.

## The two contexts

### A lone set

The report is given one file: `song.als`. It says what the XML holds, and that nothing
else was looked at. It does not say which samples are present, and it does not say which
are missing: there is no project to say it of.

### A project

The report is given the path to a project folder: the set, the folder it is saved in, the
samples collected into that folder, and the content of the machine. It says what the set
holds, and what is where.

The facts of the machine are true of the machine and not of the set, so they are written
only when `--computer` is given.

## The work

1. **The samples of the user library, and the ones in a random place.** They may be
   missing, and the report does not say whether they are on this machine. The paths of
   those samples are the paths of the machine that made the set, and they are not resolved
   against this one, so the question is not settled.
2. **The installation of Live.** The report does not say whether the installation that
   holds the core library is on this machine, for the same reason.

The work that concerns the shape of the report is in
[`dev/report_design.md`](dev/report_design.md).
