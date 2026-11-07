# Reporting ALS Files

Ableton Live stores sets in `.als` files, which contain XML that describes the
set.  The `als_report` command builds a model from the XML and converts the
model to markdown.


## Report Sections

The report is a markdown document, and its sections are:

| Section                           | Description                                                                                    |
| --------------------------------- | ---------------------------------------------------------------------------------------------- |
| Header block                      | General facts about the set                                                                    |
| `## Metadata`                     | Sizes and checksums                                                                            |
| `## Push 3 Standalone`            | Push 3 Standalone compatibility status                                                         |
| `## Groups/Tracks/Clips/Devices`  | Tracks, track groups, take lanes, clips, and devices                                           |
| `## Missing Samples`              | Samples that are not in the project, packs, or the Core Library                                |
| `## Located Samples`              | Samples collected into the Live project directory, and samples from a pack or the Core Library |
| `## Device/Track Cross-Reference` | All devices used in the set, and the tracks that use them                                      |
| `## Track / Clip Cross Reference` | All clips in the set, and the tracks that reference them                                       |
| `## Set Assets`                   | Samples the set contains, as a numbered list                                                   |
| `## Referenced Packs`             | Lists the packs the set refers to.                                                             |
| `## Test Environment`             | The state of the machine the report was made on                                                |


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
• 1.1.2a — The first individual clause, paragraph, or item (denoted by 'a') within sub-subsection 1.1.2.

#### Visual Example

To see how this looks in a legal document, technical manual, or project outline:
• 1. Main Heading
 • 1.1 Subheading
  • 1.1.1 Sub-subheading
  • 1.1.2 Sub-subheading
   • 1.1.2a This is the exact item you are looking at.
   • 1.1.2b The next item at this same level.

#### Usage in This Project

TODO: the following was taken from the `Fascination.md` reference report
(`$live_reference_sets/sets/live_11/reports/Fascination.md`). Notice how it shows references, which we do not exist for
MIDI. Audio files live in separate files, so ALS XML elements can only point to the audio files. In that sense audio
samples are always referenced.

```text
ALS_Model
  Group track 1 👥 Group # Drums
  Group Track Device 1a Filter Max for Live ⚠ not usable on Push 3
  Group Track Device 1b DrumBuss Live
  Track 1.1 🎹 MIDI Kontakt 7
    Track Device 1.1a Kontakt 7 VST3 ⚠ not usable on Push 3
    Clip 1.1.1 (×5) Kontakt 7 1 ⚠ not in project
      References (×5): launch: trigger, warp: none
    Take lane 1.1.1 3-Kontakt 7 1
      Clip 1.1.1.1 (×3) Kontakt 7 1 ⚠ not in project
        References (×3): launch: trigger, warp: none
```

Notice how Track 1.1 appears beneath Group track 1; That means the track is a member of the group. The hierarchical
numbering (1.1) is consistent with the indentation.
