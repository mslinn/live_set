# Reporting ALS Files

Ableton Live stores sets in `.als` files, which contain XML that describes the
set.  The `als_report` command builds a model from the XML and converts the
model to markdown.

This document is the shape of the report: its sections, what each of them says, and
the rules that govern them. What the command is given, and what it does with it, is in
[`report_context.md`](../report_context.md).


## The report of a project

A project holds one or more sets. The report of a project is a common table, and then
a report for each of its sets.

The common table holds the facts that are the same for every set of the project: the
context, the path that was given, the machine the report was made on, the times of the
project folder, the time the report was made, and the time zone the times are written
in. The part of a report that is dedicated to a set is repeated for every set, and the
reports follow the common table, one after another.

A set's own report is not otherwise changed: its title, its facts table, and its
sections are as they are.

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

The context is stated in one line, in the table of the facts it belongs to: in the
common table of a project, and in the table of the set itself when the report is of a
lone set.


## The sections of the report

The report is a markdown document, and its sections are:

- **The header block** — the general facts about the set.
- **`## Metadata`** — the sizes and the checksums of the file.
- **`## P3S Standalone`** — the P3S compatibility status.
- **`## Groups/Tracks/Clips/Devices`** — the tracks, the track groups, the take
  lanes, the clips, and the devices.
- **`## Located Samples`** — the samples collected into the project, and the ones
  that come from a pack or from the Live core library.
- **`## Missing Samples`** — the samples that are not collected into the project, and
  that do not come from a pack or from the Live core library.
- **`## Device/Track Cross-Reference`** — every device the set uses, and the
  tracks that use them.
- **`## Track / Clip Cross Reference`** — every clip in the set, and the tracks
  that refer to them.
- **`## Set Assets`** — the files the set refers to, as a numbered list.
- **`## Referenced Packs`** — the packs the set refers to.
- **`## Test Environment`** — the machine: the 'Ableton Project Info' folders, the
  packs that are installed, and the packs that are not.

Some of what the report says is about the set, and some of it is about the machine the
report was made on. The machine's facts are written only when `--report_machine` is
given, because they are true of the machine and not of the set:

- the packs that are installed, and the packs that are not;
- the 'Ableton Project Info' folders around the set;
- whether a sample of the user library, or of a random place, is on this machine;
- the size on disk, and the date, of each file the set refers to.

Everything else the report says is a fact of the set, and is written in either context.


## The samples of the set

A sample of a set is either **collected into the project** or **external** to it.

A collected sample is in the project folder, and it is always located: that is a
fact of the project, and the report says so in either context.

An external sample is in a pack, in the Live core library, in the user library,
or in a random place: a path that Live wrote for a file that was on another
machine, or one that leaves the project folder. The random ones are the
hard-to-find ones, and they are the reason the report names the path of every
file the set refers to.

**A sample of a pack and a sample of the Live core library are never missing.**
The pack holds the one, and the installation of Live holds the other. What may
be missing is the pack, or the installation of Live, and that is a fact of the
machine: the report writes the packs that are installed, and says whether the
installation is here.

The samples of the user library, and the ones in a random place, may be
missing: the file has to be found again. Whether they are on the machine that
ran the report is a fact of the machine, and not of the set: a set that was
made on another computer names files that are not here. The report says how
many of them are here when `--report_machine` is given.


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

`Referenced Packs` is a section of the report. `Installed Packs` and `Missing
Packs` are sections of the test environment.


## Implementation

- **A model class represents one XML entity.** It holds what the XML element
  holds and nothing else. Most XML elements have corresponding model classes.
- **Every collection is a class of its own**, named for the model class
  instances it holds.
- **A model does not write markdown.** A serializer class is initialized with a
  model instance, and it writes the markdown representation. The hierarchy of
  serializer classes mirror the model class hierarchy, which mirror the XML
  structure. This means each model class has a small serializer class of its
  own. Model classes should not have methods called `to_markdown` or `to_number`
  because that functionality belongs to the corresponding serializer class.
- **Numbering is added by model serializers.** The ALS XML has no notion of a
  track number or a clip number, so no model has one. Model serializers that
  process collections generate numbered lists and pass them to the child
  serializers.
- **The indent of a thing comes from its number.** The number of a thing in the report says
  how deep it is: `1` is a track at the top of the set, `1.1` is a child of it, and `1a` — a
  device of the track `1` — is a child of it too. The indent is derived from the number, so
  that the number of a thing and the place of it in the outline can never disagree.
- **The outline is one list.** Every line of the outline is a list item of the same kind, so
  that a renderer takes the children of a thing for its content and not for a list of their
  own.

## The `Groups/Tracks/Clips/Devices` Section

The `Groups/Tracks/Clips/Devices` section numbers each reported item hierarchically.

The hierarchical relationships between the ALS XML, the ALS model classes, and the corresponding serializer classes is
reflected in the markdown generated for the ALS report. Conceptually nested XML items stored in the ALS file are
reported using a hierarchical numbering system.

"Conceptually nested" means that the XML hierarchy evolved over time as Ableton Live added features. Some features made
the XML structure nesting less obvious, so this project assembles a set of nested model classes that mirror the
perceived nesting, which may not literally reflect the nested elements structure of the ALS XML.

### Hierarchical Numnbering System

In a hierarchical numbering system, `1.1.2a` represents a specific sub-item nested deep within a structured list or
document outline.

Here is how this specific number breaks down from the top level down to the most specific point:

• 1. — The first main section or chapter.
• 1.1. — The first subsection under main section 1.
• 1.1.2. — The second sub-subsection under subsection 1.1.
• 1.1.2a — The first individual clause, paragraph, or item (denoted by 'a')
within sub-subsection 1.1.2.


#### Visual Example

To see how this looks in a legal document, technical manual, or project outline:
• 1. Main Heading
 • 1.1 Subheading
  • 1.1.1 Sub-subheading
  • 1.1.2 Sub-subheading
   • 1.1.2a This is the exact item you are looking for.
   • 1.1.2b The next item at this same level.

#### Usage in This Project

TODO: the following was taken from the `Fascination.md` reference report
(`$live_reference_sets/sets/live_11/experiments/reports/Fascination.md`). Notice
how it shows references for `<AudioTrack/>` elements, which do not exist for
MIDI. Audio files live in separate files, so `<AudioTrack/>` elements point to
the audio files. In that sense audio samples are always referenced.

```text
ALS_Model
  Group track 1 👥 Group # Drums
  Group Track Device 1a Filter Max for Live ⚠ not usable on Push 3
  Group Track Device 1b DrumBuss Live
  Track 1.1 🎹 MIDI Kontakt 7
    Track Device 1.1a Kontakt 7 VST3 ⚠ not usable on Push 3
    Clip 1.1.1 (×5) Kontakt 7 1 ⚠ not in project
      Copies (×5): launch: trigger, warp: none
    Take lane 1.1.1 3-Kontakt 7 1
      Clip 1.1.1.1 (×3) Kontakt 7 1 ⚠ not in project
        Copies (×3): launch: trigger, warp: none
```

Notice how Track 1.1 appears beneath Group track 1; That means the track is a member of the group. The hierarchical
numbering (1.1) is consistent with the indentation.
