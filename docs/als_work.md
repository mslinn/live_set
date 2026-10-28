# Working With The Ableton Live ALS File Format

Last Revision: 2026-10-27<br>
Author: Mike Slinn<br>
Status: For Discussion

This document is a reference for the how the work of reverse engineering the
Ableton Live set (ALS) format is being done. This is a HOW-TO document. The WHAT
document (discussing findings) is [als_notes.md](als_notes.md).

<blockquote style="border: 1px solid currentColor; padding: 12px; border-radius: 4px;">
IMPORTANT: We are not allowing any additional switches or configuration ability
for controlling the behavior of live_set at this time. One should not add
unnecessary complexity to a new project that is already undergoing a huge
transformation.
</blockquote>

The ALS format changes with every Ableton Live release. The `live_set` project
is designed to handle structural differences in ALS files, such as an element
name that was renamed, or elements that exist in one version but not in another.


## XML Tools

The following subsections are presented here because this information will be
required in the next section (Current Work).


### XML Transformation with XSLT (Nokogiri)


#### XSLT Templates

XSLT templates are used for transforming XML files from one format to another.
They perform structural transformations (for example, converting between Ableton
Live v11 and v12 formats).

We need to generate XSLT stylesheets that map one version’s structure to the other.
The XSLT stylesheets perform the bidirectional reorganization work.

To transform an XML document using an XSLT template, Nokogiri is the standard
and most performant choice.

```ruby
require 'live_set'

# The identity template: copies everything, so the transformation changes nothing
# until a rule is added. See "XSLT Identity Template".
IDENTITY_STYLESHEET = <<~XSLT.freeze
  <?xml version="1.0" encoding="UTF-8"?>
  <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
    <xsl:template match="node() | @*">
      <xsl:copy>
        <xsl:apply-templates select="node() | @*"/>
      </xsl:copy>
    </xsl:template>
  </xsl:stylesheet>
XSLT

# Read the live set, which is an XML document
document = AlsFile.read('input.als')
template = Nokogiri::XSLT(IDENTITY_STYLESHEET)

# Perform the transformation
transformed_document = template.transform(document)

# Write the transformed live set, carrying the source file's timestamp into the
# gzip header
AlsFile.write('output.als', transformed_document, File.mtime('input.als'))
```

Reading and writing live sets is done by `AlsFile`
(`lib/live_set/als_file.rb`). Reading gives the XML document; writing takes
the XML document, writes it in Live's own format, and compresses it. The XML is
written by `LiveXmlWriter` (`lib/live_set/live_xml_writer.rb`), because libxml2
does not write XML the way Live does. The writer, not the stylesheet, decides
the format, so the stylesheet's `xsl:output` settings do not apply to it.

The gzip header's mtime is stored inside the set. Live writes 0 there; this code
writes the timestamp of the file the set was read from, so that a converted set
keeps the timestamp of the one it came from. The output file's filesystem
`mtime` is the time the file was created.

A round trip through this code produces byte-identical XML. The compressed
file is not byte-identical: Live writes a gzip header with an mtime of 0 and
with the byte identifying the platform that wrote the file, and the deflate
stream itself differs.

TODO `als_delta` must compare XML trees, not XML strings. It reads the sets
with `AlsFile`, and the trees have to be brought to a common version before
they are compared. See docs/cpfir.md, section 5.


#### XSLT Identity Template

The standard way to copy an XML file with minor changes in XSLT is to use the
identity template, which copies everything as-is, and override it with specific
templates for the elements or attributes you want to change.

See
[StackOverflow](https://stackoverflow.com/questions/3436212/xslt-copy-with-modifications)
and [identity](https://dh.obdurodon.org/identity.xhtml).

Here is an example of an identity transform:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:template match="node() | @*">
    <xsl:copy>
      <xsl:apply-templates select="node() | @*"/>
    </xsl:copy>
  </xsl:template>

  <!-- Minor Change 1: Rename a specific element (e.g., change <oldTag> to <newTag>) -->
  <xsl:template match="oldTag">
    <newTag>
      <xsl:apply-templates select="node() | @*"/>
    </newTag>
  </xsl:template>

  <!-- Minor Change 2: Modify the text content of a specific element -->
  <xsl:template match="status">
    <status>
      <xsl:text>APPROVED</xsl:text>
    </status>
  </xsl:template>

  <!-- Minor Change 3: Modify a specific attribute -->
  <xsl:template match="@version">
    <xsl:attribute name="version">2.0</xsl:attribute>
  </xsl:template>

  <!-- Minor Change 4: Remove a specific element or attribute by matching it and doing nothing -->
  <xsl:template match="tempData"/>
</xsl:stylesheet>
```

How it works:

1. The Identity Template (`node() | @*`): Matches all nodes and attributes and
    outputs an exact copy via `<xsl:copy>` and `<xsl:apply-templates>`.
2. Overrides: Any more specific `xsl:template` match you add (like matching a
    specific tag, text node, or attribute) takes precedence over the identity
    template, allowing you to alter, replace, or drop it selectively.


#### XSLT Implementation

See [cpfir.md](cpfir.md).

TODO Discuss needs. We might need a new Ruby subdirectory (`lib/live_set/tx/`)
dedicated to the transformation in general, and perhaps subclasses of a new
generic class for each major ableton version (e.g. 8..12). We probably need a
new class for transforming als files using xslt, plus spec unit tests and also
tests on the ableton live demo als files. We definitely need unit tests that use
the ableton demo sets in all Live major versions as input data.


### XSD  (XML Schema)

TODO This section is not used at present. We might delete it soon.


#### Generating XSD

Every Ableton Live file contains XML. From the XML structure present in a given
Live file (or from a collection of them), you can generate an XML Schema (XSD)
that describes the allowed structure, elements, attributes, and types for that
version of the format. XSD files are used for XML validation.

By combining XSDs together we can assemble a more complete XSD.
Once a "good enough" stylesheet exists for two Ableton Live versions (e.g. v11
and v12), we can use the stylesheets to do much of the reorganizational work of
transforming bidirectionally between v11 and v12 formats.

#### Mapping XSD to Ruby Classes (RXSD)

RXSD (<https://github.com/movitto/RXSD>) was considered for mapping the generated
XSD to Ruby classes, and rejected. RXSD compiles a schema into Ruby classes on the
fly, at run time. The classes in this project are written by hand and live in
`lib/live_set/`, so a run-time generator is the wrong shape for the job. The gem
is also unmaintained: the last release, 0.5.3, was in May 2016, it depends on
`libxml-ruby ~> 2.8.0`, a second libxml2 binding alongside the Nokogiri this
project already uses, and RFC 8134 section 7.1 reports that it could not parse a
complex schema at all.

Rejecting it costs nothing. The schema `exe/generate_xsd` produces is already an
index of the format: it lists every element and every attribute of that Live
version. The format's vocabulary can be read from the schema, and the differences
between two versions can be found by diffing one schema against another. Neither
the inventory nor the diff needs the ALS files scanned by hand.


## Current Work

This document is part of an effort to create the next version of `live_set`. The
work being added right now is:

1. Perform a proper translation of XML elements between different Live versions.
   Use XSLT for the work; for example, renaming XML elements, moving XML
   elements, deleting XML elements, etc..

   TODO the current code base is not organized this way yet.

2. Develop high-level methods that detect and describe the differences between
   two Live sets. Do not assume that the XML schemas are identical for both Live
   set. Translate the older format into the newer format.


## Gui_harness

To make the required reverse-engineering possible, the
[gui_harness](https://github.com/mslinn/gui_harness) gem was created.
Gui_harness is meant to be used as a Ruby rspec helper for running GUI programs
that launch from the command line, like Ableton Live.

Gui_harness can answer GUI dialogs, provide values in forms, press buttons, and
read text from the dialog. It can also shut down the GUI program, and it takes
note of the return code and STDOUT and STDERR in case any warnings or errors
were emitted.

Gui_harness is a new program, and this is the first projec to use it. The tests
should verify that a recent version of gui_harness is used. Also bugs may be
found in gui_harness, so don't assume it works perfectly. If a bug is found in
gui_harness, fix it instead of moving on to something else.


## Comparing XML Contents

We can now iterate, using knowledge gained from reverse engineering the file
format changes between Ableton Live versions.

This document was written before the `live_set` code was updated; however, the
code is often incorrect, and this document also has many fundamental errors. TODO
and FIXME comments have been added to this document and in the code to assist
reconciliation.

<blockquote style="border: 1px solid currentColor; padding: 12px; border-radius: 4px;">
Important: when this document was last edited, both the code and the documentation
were in heavy flux and neither was authorative. Ask the user for clarification
whenever conflicting information is discovered.
</blockquote>


## Two Corpuses

The reverse-engineering data is based on two corpuses.

* The official Ableton Live demo sets. These are the primary sources.

* A corpus of 460 sets in the `$songs` directory of Mike Slinn&apos;s Bear computer.


| Corpus | Description | Use |
| --- | --- | --- |
| Mike Slinn&apos;s `$songs` directory on his Bear computer | 460 sets, featuring sets created with Live 8.2 to 12. | Real-world sets, containing groups, nesting and third-party plug-ins. |
| Ableton demo sets | Installed with Ableton Live | Most Live features are demonstrated, so these are good for testing. |


### Corpus of Mike Slinn&apos;s Sets

This corpus spans these versions:

|    Live version   | Sets |
| ----------------- | ---- |
| 8.2.1 – 8.3.4     |   21 |
| 11.3.21 – 11.3.22 |   32 |
| 12.0.1 – 12.4.6   |  407 |

**Caution:** 29 of the 32 Live 11 sets in `$songs` were written by `live_set -11` itself, which hard-codes certain
attributes:

* Filename ends with `_11.als`
* `MinorVersion` is `11.0_11300`
* `Revision` is a hard-coded value written by `live_set`.

This corpus's Live 11 sets mostly reflect what `live_set` produces, not what Live 11 produces.

Only 3 Live 11 sets in this corpus were actually created by Ableton 11.


### Corpus of Demo Sets

From Live 10 onwards, the demo sets have been provided in five versions: Intro, Lite, Push, Standard, and Suite.

Different demo sets are provided for each Ableton Live version. For example, Live 11&apos;s demo song is "Ninajirachi -
In The Rain", and Live 12&apos;s demo song is "Chuck Sutton - Patience", so a diff between them confounds version
differences with content differences.

The demo sets are installed with Ableton Live, and the
[locations](https://help.ableton.com/hc/en-us/articles/209774005-Location-of-the-default-Demo-Set)
for Ableton Live 9+ are:

```text
Windows:  %ProgramData%\Ableton\[Live Version]\Resources\Core Library\Lessons\Demo Songs
macOS:    /Applications/Live [Version].app/Contents/App Resources/Core Library/Lessons/Demo Songs
```

The versions installed on Mike Slinn&apos;s Bear computer, where this was
developed on were:

| Version | Path                                                                                        | `Creator`                                          |
| ------- | ------------------------------------------------------------------------------------------  | -------------------------------------------------- |
| Live 12 | `C:\ProgramData\Ableton\Live 12 Suite\Resources\Core Library\Lessons\Demo Songs\`           | Ableton Live 12.4d1                                |
| Live 11 | `C:\ProgramData\Ableton\Live 11 Suite\Resources\Core Library\Lessons\Demo Songs\`           | Ableton Live 113d1                                 |
| Live 10 | `C:\ProgramData\Ableton\Live 10 Standard\Resources\Core Library\Lessons\Demo Songs\`        | Ableton Live 10.1.3d1                              |
| Live 9  | `C:ProgramData\Ableton\Live 9 Standard\Resources\Core Library\Lessons\Samples\Live 9 Demo\` |                                                    |
| Live 8  | `C:ProgramData\Ableton\Live 8 Standard\`                                                    | Not installed by default, but available from Live. |


### Bash Environment Variables for Live Demo Sets

The largest demo files for each Ableton Live version were selected for testing:

```bash
export ableton_home='/mnt/c/ProgramData/Ableton'

export ableton_8_home="${ableton_home}/Live 8"
export ableton_8_program="${ableton_8_home}/Program/Ableton Live 8.exe"
# export ableton_8_demo_home="${ableton_8_home}"
# export ableton_8_demo_set="${ableton_8_demo_home}"

export ableton_9_home="${ableton_home}/Live 9 Standard"
export ableton_9_program="${ableton_9_home}/Program/Ableton Live 9 Standard.exe"
export ableton_9_demo_home="${ableton_9_home}/Resources/Core Library/Lessons/Sets"
export ableton_9_demo_set="${ableton_9_demo_home}/Amp-Drum Examples.als"

export ableton_10_home="${ableton_home}/Live 10 Standard"
export ableton_10_program="${ableton_10_home}/Program/Ableton Live 10 Standard.exe"
export ableton_10_demo_home="${ableton_10_home}/Resources/Core Library/Lessons/Demo Songs"
export ableton_10_demo_set="${ableton_10_demo_home}/Live 10 Intro Demo Song.als"

export ableton_11_home="${ableton_home}/Live 11 Suite"
export ableton_11_program="${ableton_11_home}/Program/Ableton Live 11 Suite.exe"
export ableton_11_demo_home="${ableton_11_home}/Resources/Core Library/Lessons/Demo Songs"
export ableton_11_demo_set="${ableton_11_demo_home}/Ninajirachi - In The Rain (Live 11 Intro Demo).als"

export ableton_12_home="${ableton_home}/Live 12 Suite"
export ableton_12_program="${ableton_12_home}/Program/Ableton Live 12 Suite.exe"
export ableton_12_demo_home="${ableton_12_home}/Resources/Core Library/Lessons/Demo Songs"
export ableton_12_demo_set="${ableton_12_demo_home}/Chuck Sutton - Patience (Live 12 Intro Demo).als"
```

### Ruby RSpec Variables for Live Demo Sets

The [spec/support/live_harness/live_launcher_spec.rb](Ruby test code) has a
similar structure.

## Surveying Corpuses

The [`als_files`](../bin/als_files) script re-runs the survey. To survey the
Live sets in the `$songs` directory, type:

```shell
$ bin/als_files "$songs"
```

`als_files` surveys 25 files by default, because surveying all of Mike&apos;s
sets takes about four minutes. To read them all instead of just the first 25, type:

```shell
$ bin/als_files "$songs" 0
```

### XSD Schemas

The schemas generated by `exe/generate_xsd` for various versions of Live and
stored in the `schemas/` subdirectory of this project are:

```text
live_12.4d1.xsd
live_11.3d1.xsd
live_10.1.3d1.xsd
# TODO (low urgency) live 9 & 8
```

The schemas are not stored in the repository — `.gitignore` excludes `*.xsd` — so
every developer generates them locally. The `schemas/` directory does not exist in
a fresh clone, and `generate_xsd` will not create it, so make it first:

```shell
mkdir -p schemas
exe/generate_xsd -f schemas/live_12.4d1.xsd   "$ableton_12_demo_home"/*.als
exe/generate_xsd -f schemas/live_11.3d1.xsd   "$ableton_11_demo_home"/*.als
exe/generate_xsd -f schemas/live_10.1.3d1.xsd "$ableton_10_demo_home"/*.als
# TODO (low urgency) live 9 & 8
```

`bin/generate_xsds` does all of that in one step, for every version of Live installed
on the computer.


### What the Generated Schemas Contain

Each schema is an inference from the sample files, and two things about it are worth
knowing.

**The attributes are declared.** Every value in an `.als` file is stored in a `Value`
attribute, so a schema that declared no attributes would reject every attribute in
every file it was generated from. The generated schemas declare the attributes they
found, and mark an attribute required when every instance of its element carries it.

**The children of an element are declared in the order they were first seen.** Live
does not always write siblings in groups. In the Live 11 demo set, the `<Tracks>`
element holds a MIDI track first, then the audio tracks, and then another MIDI track.
Inside a device's `<ParameterList>`, the parameters interleave: an enum parameter,
then a float parameter, then another enum parameter.

An `xs:sequence` can only say "all the MIDI tracks, then all the audio tracks". The
second MIDI track has no place in that model, so the schema rejects the very file it
was generated from. Where the sample shows a child element coming back after a
different child element has already appeared, the children are declared in an
`xs:choice` instead, which accepts them in any order.


### Generate Each Schema From Every Demo Set of That Version

A schema inferred from one set constrains Live more than Live constrains itself, and
so rejects the other sets of the same version. The Live 11 schema generated from the
Intro demo rejected four of the five Live 11 demo sets, over the order of the
children of `<Devices>` and over elements that one set happens not to contain.

Generating a schema from every demo set of a version fixes that. An element is
required only if every set contains it, and the children of an element are declared
in an `xs:choice` if the sets disagree about their order. All of the Live 10, Live 11
and Live 12 demo sets validate against the schema generated from their own version.


## Test Suite

The `live_set` test in `spec/demo_sets.rb` works with the test corpuses, instead
of XML fragments.

When testing the `-11` option, the sets are converted only once, and
`spec/conversions.rb` provides the result for multiple assertions.

The examples in `spec/live_set/live_set_modify_als_spec.rb` call the method
directly, and the examples in `spec/integration/live_set_modify_als_spec.rb` run
the command as a subprocess, three times per set, so that the second and third
runs can examine what happens when the set the command writes already exists.


## ALS Files Are XML, Probably GZipped

An `.als` file is an XML document. Most are gzip-compressed, but uncompressed
`.als` files are sometimes used for testing purposes. Read gzip-compressed
versions with:

```ruby
Zlib::GzipReader.open(path, &:read)
```

Here is a method that reads both compressed and uncompressed als files:

```ruby
require 'zlib'

def read_als(filepath)
  File.open(filepath, 'rb') do |file|
    Zlib::GzipReader.new(file).read # Attempt to read as Gzip
  rescue Zlib::GzipFile::Error
    file.rewind # If it's not a valid gzip file, rewind and read as plain text
    file.read
  end
end
```

Usage:

```ruby
content = read_als('test.als')
```


## XML Elements

### XML Root Element

The root element is `<Ableton>`, and the document is a single `<LiveSet>` under it.


#### The `Creator` Attribute

The `<Ableton>` element has `MajorVersion` and `MinorVersion` attributes, but those are Ableton's internal set-format
numbers, not the Live version a user sees. A set written by Live 12.2.1 reports `MajorVersion="5"
MinorVersion="12.0_12203"`.

The real Live version is stored in the `Creator` attribute:

```xml
<Ableton MajorVersion="5"
         MinorVersion="12.0_12203"
         SchemaChangeCount="3"
         Creator="Ableton Live 12.2.1"
         Revision="c0d59beb...">
```


### Converting a Live 12 Set to Live 11

The rules for converting Live 12 back to Live 11 were figured out by opening a
Live 11 demo set in Live 12, saving it, and comparing the two versions of the
Live set.

See [`conversion.md`](conversion.md) for what the conversion has to become, what
the component that does it looks like, and how the differences between two
versions are worked out.


#### Unique v11 Schema

`live_set -11` writes a set in the Live 11 format, and the version strings it
writes are fixed so the Live set can be recognized as being the result of a
conversion by `live_set` instead of being saved by Ableton Live:

```ruby
@ableton['Creator'] = 'Ableton Live 11.3.21'
@ableton['MajorVersion'] = '5'
@ableton['MinorVersion'] = '11.0_11300'
@ableton['Revision'] = '5ac24cad7c51ea0671d49e6b4885371f15b57c1e'
@ableton['SchemaChangeCount'] = '3'
```

`MajorVersion` with value `5` indicates that this ALS file contains a Live 11 set.

Note that `MinorVersion` here is `11.0_11300` while `Creator` says `11.3.21`.
The two are different numbering schemes: `Creator` is the version of Live that
wrote the set, and `MinorVersion` identifies the set format that the specified
version of Live 11 reads.


#### What the Conversion Removes, and What it Keeps

The following command converts a Live 12 set (`$path/to/my_v12_set.als`) to Live
11 format and saves the result as `$path/to/my_v12_set_11.als`. The
output file is overwritten if it already exists:

```shell
$ live_set -11 -f $path/to/my_v12_set.als
```

The conversion from Live 12 to 11 renames some well-known elements and removes
all elements that Live 11 does not have:

| Element          | In Live 11? | In Live 12?                      |
| ---------------- | ----------- | -------------------------------- |
| `InstrumentMeld` | no          | yes — 2 in the Live 12 demo set  |
| `MxPatchRef`     | no          | yes — 5 in the Live 12 demo set  |
| `Roar`           | no          | yes — 10 in the Live 12 demo set |

The first version of `live_set` copied all other elements unchanged. The
conversion was a selective removal, not a rewrite. It edited the version strings
on the `Ableton` element, removes those three elements, translated the two that
Live 11 spells differently, and wrote the rest of the document back out.

* Group tracks are kept, because both Live 11 and 12 support group tracks. See
  section 9.2.

* Elements the conversion is unaware of are kept. A `FakeGroup` element, a
  `TrackWrapperType` element, or anything else that a future version of Live
  writes is copied to the output verbatim, with its attributes intact. The
  conversion does not need to know what an element means in order to preserve
  it.

This is worth knowing if a set contains something the format reference does not
document. Nothing is silently dropped.

The conversion writes `<name>_11.als` next to the set it was given. If that file
is already there, the command stops and says so, unless the force option is
given:

```shell
$ live_set -11 my_set.als
Writing ./my_set_11.als
Conversion complete

$ live_set -11 my_set.als
Error: ./my_set_11.als already exists. Use -f to overwrite it.

$ live_set -11 -f my_set.als
Overwriting existing ./my_set_11.als
Conversion complete
```

#### Translating Renamed Elements

Some elements were renamed between Live 11 and 12.

The lane element was renamed. A lane is an `ExpressionLane` in Live 11 and a
`MidiEditorLaneModel` in Live 12. Apart from the name they are the same: the
same `Id` attribute, and they have the same `Type`, `Size` and `IsMinimized`
children.

```xml
<!-- Live 11 -->
<ContentLanes>
  <ExpressionLane Id="0">
    <Type Value="4"/>
    <Size Value="25"/>
    <IsMinimized Value="false"/>
  </ExpressionLane>
</ContentLanes>
```

```xml
<!-- Live 12 -->
<ContentLanes>
  <MidiEditorLaneModel Id="0">
    <Type Value="4"/>
    <Size Value="25"/>
    <IsMinimized Value="false"/>
  </MidiEditorLaneModel>
</ContentLanes>
```

The conversion renames `MidiEditorLaneModel` elements to `ExpressionLane` elements.

The `Oversampling` attribute values for `Saturator` and `Pedal` elments are
translated between boolean values and 0 & 1 (truthy integer) values.

| Parent      | Live 11.3d1           | Live 12.4d1           |
| ----------- | --------------------- | --------------------- |
| `Saturator` | `"1"` or `"0"`        | `"true"` or `"false"` |
| `Pedal`     | `"true"` or `"false"` | `"true"` or `"false"` |

The conversion reads a `Saturator`'s boolean value and rewrites the value as
`"1"` or `"0"`. `Pedal` values are not modified.

In the demo set, track 132 "Plastic Toy" has a `Saturator` with
`Oversampling="0"` in Live 11 and `Oversampling="false"` in Live 12; the other
five `Saturator`s have values `"1"` in Live 11 and `"true"` in Live 12.


### 2.4 The lanes are a fixed set, and it changed

TODO WTF is this all about? This is a terrible explanation, and reasoning is
suspect, and the conclusions are probably wrong. We need to follow normal
reverse-engineering principles, for example, create a simple file, translate
from R11 to R12, look at the result, then figure out what the types mean.
Because this section is complete bullshit, the resulting translated ALS file
crashes Ableton Live.

The two containers hold a fixed set of lanes, and **the set is the same in every set of a given
Live version**. Every demo set of every edition has the same lanes:

| Live version | `ContentLanes` types | `ExpressionLanes` types |
| ------------ | -------------------- | ----------------------- |
| 11           | 4, 5                 | 0, 1, 2, 3              |
| 12           | 2, 3, 4              | 0, 1, 2, 3, 5           |

All five Live 11 demo sets have `ContentLanes` types 4 and 5 and `ExpressionLanes` types 0 to 3.
All five Live 12 demo sets have `ContentLanes` types 2, 3 and 4 and `ExpressionLanes` types 0 to
3 and 5. The lanes are not a property of the music; they are part of the application state.

A lane is identified by the container it is in and its `Type`. The `Size` value says which family
a lane belongs to: 25 for a lane in `ContentLanes`, 41 for a lane in `ExpressionLanes`, in both
Live versions. The `Type` is a number within that family, and the two families use the same
numbers for different things — `Type` 2 in `ContentLanes` is not `Type` 2 in `ExpressionLanes`.

**So the conversion has to cope with lanes Live 11 has never heard of.** Converting a Live 12 set
produces lanes of `Type` 2 and 3 in `ContentLanes`, and `Type` 5 in `ExpressionLanes`. Live 11 has
no lanes of those types, so it cannot render them; and a Live 11 set has a lane of `Type` 5 in
`ContentLanes` that Live 12 has no use for.

The conversion does not try to reconcile this. It renames the element and leaves the lanes alone,
because:

- **The `Type` values are not portable.** There is no mapping from a Live 12 lane to a Live 11
  lane, because the two versions number their lanes differently within the same family.
- **The lanes are application state, not material.** They record which panel is open and how wide
  it is. Nothing in the set's audio depends on them.

Whether Live 11 tolerates a lane of an unknown `Type` is not known. It is a small thing to test:
convert a Live 12 set, open the result in Live 11, and look at the lanes.

**Neither treatment works.** Removing `ContentLanes`, `ExpressionLanes` and `Oversampling`
crashes Live 11, and so does translating them, because the translated file still has lanes of an
unknown `Type`:

> A serious program error has occurred.
> Live will shut down after this message box is closed.

This is not a theoretical problem. The round-tripped file was opened in Live 11 Suite 11.3.43
and it crashed Live, with the log showing the exception a second after `Begin ExchangeDocument`:

```
2026-10-22T16:22:56.753332: info: Default App: Begin ExchangeDocument
2026-10-22T16:22:58.144252: info: Exception: Windows Exception
2026-10-22T16:22:58.144280: info: Exception: Fatal Error: Unhandled exception
```

The original Live 11 demo set loads cleanly, through `Begin ExchangeDocument` and
`End ExchangeDocument`, with no exception. So a set with no `ContentLanes` and no
`ExpressionLanes` is no more acceptable to Live 11 than a set with lanes of an unknown `Type`,
and **the conversion does not yet produce a set that Live 11 can open.** What the crash is
caused by is not yet known: the `Type` values are the obvious suspect, but the converted file
also differs from a Live 11 set in its `Creator`, `Revision` and `SchemaChangeCount`. See
TODO.md N42.

### 2.5 What a round trip establishes

TODO this section is verbose garbage and should probably be deleted.

Converting the Live 12 version of the Live 11 demo set back to Live 11 produces a file that is a
Live 11 set in every respect that can be checked without Live 11:

| | Live 11 original | Round tripped |
| --- | --- | --- |
| `Creator` | Ableton Live 11.3d1 | Ableton Live 11.3.21 |
| `MinorVersion` | `11.0_11300` | `11.0_11300` |
| Lane element name | `ExpressionLane` | `ExpressionLane` |
| `Oversampling` values | 5 of `"1"`, 1 of `"0"` | 5 of `"1"`, 1 of `"0"` |
| Audio tracks | 14 | 14 |
| MIDI tracks | 14 | 14 |
| Group tracks | 1 | 1 |
| Clips | 255 | 255 |

The material is untouched, and the two elements that Live 12 spells differently are now spelled
the Live 11 way.

**The one thing the round trip cannot settle** is the lanes. The round-tripped file has three
lanes Live 11 has never seen, and has lost one that it has:

| | Live 11 original | Round tripped | |
| --- | --- | --- | --- |
| `ContentLanes` | 4, 5 | 2, 3, 4 | `Type` 2 and 3 are unknown to Live 11; `Type` 5 is lost |
| `ExpressionLanes` | 0, 1, 2, 3 | 0, 1, 2, 3, 5 | `Type` 5 is unknown to Live 11 |

The file is a well-formed Live 11 file, but it contains lanes Live 11 has never seen, and Live
11 crashes on it rather than opening it. See TODO.md N42 and section 2.4.


## Every value is in a `Value` attribute

This important fact about the format is easy to get wrong.

Every value in every `.als` file is stored in a `Value` attribute, in every Live
version from 8.2 through 12.4:

```xml
<EffectiveName Value="My Track"/>
<RelativePath Value="Samples/Imported/song1.mp3"/>
<Freeze Value="true"/>
```

There is no text-only shape in practice. Do not read values with `element.text`
because that will return `""` and silently produce empty results.

`lib/common/xml.rb` provides two readers:

```ruby
xml_value(element)   # the Value attribute, or nil
xml_bool?(element)   # true or false, never nil
```

`xml_bool?` treats a missing element as `false` — an `<AudioTrack>` with no `<Freeze>` element is
not frozen. A value that is neither `"true"` nor `"false"` is also `false`, but it is logged, so
malformed data does not pass unnoticed.


## Track names

A track's `<Name>` element has four children, all of which are `Value` attributes:

```xml
<Name>
  <EffectiveName Value="3-3-Audio 1-1"/>
  <UserName Value=""/>
  <Annotation Value=""/>
  <MemorizedFirstClipName Value="3-Audio 1-1"/>
</Name>
```

| Element                  | Meaning                                                                                             |
| ------------------------ | --------------------------------------------------------------------------------------------------- |
| `EffectiveName`          | The name Ableton resolved. Accounts for renames, and for the numbering it adds to duplicate tracks. |
| `UserName`               | The raw name the user typed. Often empty.                                                           |
| `Annotation`             | Free text the user typed. Not a name.                                                               |
| `MemorizedFirstClipName` | A clip name, not a track name.                                                                  |

For Live 9+, `EffectiveName` is the display named for the track, and `UserName`
is the fallback value. For Live 8, `UserName` contains the track name.


## Clip slots

The session view of a track is a list of clip slots:

```text
DeviceChain / MainSequencer / ClipSlotList / ClipSlot
```

The slot layout did not change between Live 8 and Live 12. Every slot in every surveyed set
uses the nested form:

```xml
<ClipSlot Id="0">
  <LomId Value="0"/>
  <ClipSlot>
    <Value>
      ... the clip, or nothing ...
    </Value>
  </ClipSlot>
  <HasStop Value="true"/>
  <NeedRefreeze Value="false"/>
</ClipSlot>
```

| Layout                                   | Occurrences |
| ---------------------------------------- | ----------- |
| Nested — `<ClipSlot><Value/></ClipSlot>` | 1896        |
| Flat   — `<Value/>` directly in the slot | 0           |

TODO The nested form is sometimes called the "Live 8" layout in this project's code
comments. That label is wrong.

`<ClipSlotList>` also appears under `FreezeSequencer` and `Mixer`; the
`MainSequencer` one is the session view.

## Audio clips live in two different places

This is easy to get wrong, because a track's audio can be in either place, and
the two places are not versions of each other.

### Session View

```text
ClipSlotList / ClipSlot / ClipSlot / Value / AudioClip
```

The `AudioClip` is a child of the slot's `Value` element, and is a complete clip
in its own right:

```xml
<ClipSlot Id="0">
  <LomId Value="0"/>
  <ClipSlot>
    <Value>
      <AudioClip Id="0" Time="0">
        <LomId Value="0"/>
        <CurrentStart Value="0"/>
        <CurrentEnd Value="92"/>
        <Loop>...</Loop>
        <Name Value="3-Audio 1-1"/>
        <SampleRef>
          <FileRef>
            <RelativePath Value="Samples/Recorded/3-Audio 0001 [2024-11-25 182402]-1.wav"/>
            <Path Value="E:/media/.../3-Audio 0001 [2024-11-25 182402]-1.wav"/>
            <Type Value="1"/>
            <OriginalFileSize Value="525896"/>
          </FileRef>
          <LastModDate Value="1703033260"/>
        </SampleRef>
      </AudioClip>
    </Value>
  </ClipSlot>
</ClipSlot>
```

How often a session slot holds an `AudioClip`:

| Live version | Session slots holding an `AudioClip` |
| ------------ | ------------------------------------ |
| 11           | yes (TODO WTF?)                      |
| 12           | 62 of 4206                           |

TODO this seems incorrect:
So in Live 12, the session view is usually empty of audio.


### The arrangement and the take lanes

```text
DeviceChain / MainSequencer / Sample / ArrangerAutomation / Events / AudioClip
TakeLanes / TakeLanes / TakeLane[N] / ClipAutomation / Events / AudioClip
```

All 4657 `AudioClip` elements in the surveyed files are in one of these two
places. None are under a `ClipSlot`.

The arrangement holds the audio on the timeline, which is what you see in the
arrangement view. A take lane holds the audio recorded onto a take. These are
different from the session view's slots.


### The two are not the same clips, and their ids do not overlap

TODO WTF is this supposed to be?

In one file, the session slots are numbered `0`–`7` and the arrangement's
`AudioClip` elements are numbered `140`+. They are separate id spaces, and they
hold separate clips.

A track can have clips in both places, and the same audio file can appear in
both. The report shows all three sources, under separate headings:

```text
  Track '3-3-Audio 1-1' **not frozen** (5 clips, 5 files, totaling 13.3 MB)
  Session view: 3 clips, 3 files
    Samples/Recorded/3-Audio 0001 [2024-11-25 182402]-1.wav        6.0 MB  2024-11-25 23:24:02
    ...
  Arrangement: 3 clips, 3 files
    ...
  Take lanes: 3 clips, 3 files
    ...
```

### The same file can be referenced several times

A file may be referenced from the session view, the arrangement, and one or more
take lanes at the same time. One track in `above_clouds.als` has 9 clip
references to 5 distinct files:

```text
3x  Samples/Recorded/3-Audio 0001 [2024-11-25 182402]-1.wav
2x  Samples/Recorded/3-3-Audio 1-1 0003 [2024-11-25 182953].wav
2x  Samples/Recorded/3-Audio 0001 [2024-11-25 182402].wav
```

A file occupies space once, however many times it is referenced, so:

* The **clip listing** shows every reference, under the heading for where it
  came from. The set really does contain those references, and the headings make
  that clear.
* The **total size** counts each distinct file once.
* The **"has not been collected" warnings** name each distinct missing file
  once, rather than repeating itself for every reference to it.


## File references

Inside a clip's `<SampleRef><FileRef>`:

| Element            | Meaning                                                                                 |
| ------------------ | --------------------------------------------------------------------------------------- |
| `RelativePath`     | Path relative to the set's directory. Empty when the file is not in the project folder. |
| `Path`             | Absolute path. Empty for some references.                                               |
| `Type`             | Numeric file type.                                                                      |
| `OriginalFileSize` | Size in bytes. Live 8 calls this `FileSize`.                                            |

`RelativePath` is empty in 47084 of the surveyed references. A clip whose
`RelativePath` is empty is not collected into the project folder.

### The recorded size can be zero, and the file on disk can disagree

`OriginalFileSize` is the size of the *source* file as Live saw it. It is not
always the size of the file on disk, and it is sometimes zero even when the file
exists and is not empty.

In one track of `above_clouds.als`:

| File                                         | `OriginalFileSize` | On disk   |
| -------------------------------------------- | ------------------ | --------- |
| `3-Audio 0001 [2024-11-25 182402]-1.wav`     | 5,969,624          | 5,969,624 |
| `3-3-Audio 1-1 0006 [2024-11-25 183403].wav` | **0**              | 4,027,856 |
| `3-3-Audio 1-1 0007 [2024-11-25 183429].wav` | **0**              | 1,499,216 |

The totals disagree too: 6.50 MB summed from the XML against 13.35 MB on disk,
for the same 5 distinct files. Live warps, resamples and otherwise processes
audio when it saves a set, so the file on disk is often larger than the source.

**The rule `live_set` follows:** report the size from the XML, but fall back to
the filesystem when the XML says zero and the file is present locally. The XML
is the only source that is always available — the set may have been written on
another machine — but a zero is not a useful answer when the file is right
there.


## Devices

**There are no `<Device>` elements in any real set.** The corpus has zero.


## PluginDevice

Plugins are `<PluginDevice>` elements — 229 of them, in 23 of 40 sampled files.

FIXME: The plugin's name is not where `live_set` looks for it:

```xml
<PluginDevice Id="6">
  <LomId Value="0"/>
  <Name Value=""/>
  <UserName Value=""/>
  <PluginDesc>
    <VstPluginInfo Id="0">
      <Path Value="C:/Program Files/VstPlugins/MeldaProduction/Pitch Shift/MAutoPitch.dll"/>
      <PlugName Value="MAutoPitch"/>
```

There are two shapes of `PluginDesc`, and the name is in a different place in
each. Across the whole corpus:

| `PluginDesc` child      | Count | Name element | Live versions |
| ----------------------- | ----- | ------------ | ------------- |
| `VstPluginInfo` (VST2)  | 351   | `PlugName`   | 8, 11, 12     |
| `Vst3PluginInfo` (VST3) | 1153  | `Name`       | 11, 12        |

A VST2 plugin has `PlugName` — 351 of 351 have it, with values such as
`"MAutoPitch"`.

A VST3 plugin has **no `PlugName` at all** — 0 of 1153 — and its name is at
`Name`, with values such as `"T-De-Esser"`, `"LALA"`, `"Kontakt"`, `"SSQ"`,
`"MCompressor"` and `"OTT"`.

```xml
<PluginDesc>
  <Vst3PluginInfo Id="0">
    <WinPosX Value="47"/>
    <NumAudioInputs Value="1"/>
    <NumAudioOutputs Value="1"/>
    <IsPlaceholderDevice Value="false"/>
    <Preset><Vst3Preset/></Preset>
    <Name Value="T-De-Esser"/>
    <Uid Value="..."/>
    <DeviceType Value="2"/>
```

`DeviceType` is `1` for an instrument (96 of 1153) and `2` for an effect (1057 of 1153).

There is no `Manufacturer` element at all — it is absent from every plugin in the corpus.

TODO The following sounds like a confused LLM wrote this garbage. Must look at
the corpus again, and describe findings more clearly:

There is also **no reliable way to tell a third-party plugin from an
Ableton-native one** from the XML alone. A native Ableton device is not a
`PluginDevice` at all — it is its own element, such as `Eq8`, `GlueCompressor`,
`Limiter`, `Saturator`, `Compressor2`, `Reverb`, `Tube`, `Cabinet`, `Spectral`,
`AutoFilter`, `StereoGain` and `Tuner`. The `PluginDevice` element therefore
means "a plug-in", and every plug-in in the corpus is third-party — but that is
a property of the corpus, not something the file states. `Path` is present on
317 of 1504 plugins and always points outside Ableton's own directories; the
other 1187 have no `Path` at all.

`IsPlaceholderDevice` is `"false"` on 1430 plugins, and absent on the other 74.

TODO what does the following statement mean, and what should be done?

The elements `live_set` currently looks for are all absent from real sets:

| Element                                                      | Occurrences in 40 sets |
| ------------------------------------------------------------ | ---------------------- |
| `<Device>`                                                   | 0                      |
| `<PresetManifestV1>`                                         | 0                      |
| `<CurrentPreset>`                                            | 0                      |
| `<VstPlugin>`, `<VstPluginCategory>`, `<VstId>`              | 0                      |
| `<AudioUnitPlugin>`, `<AudioUnitPreset>`, `<AudioComponent>` | 0                      |
| `<ClapPlugin>`, `<PluginId>`                                 | 0                      |
| `<VstPreset>`                                                | 10, in one file        |

See TODO.md N21 for the plan to rewrite this.

### The device chain

The devices on a track are the children of `DeviceChain/DeviceChain/Devices`. The path is
doubled: `DeviceChain` (the track's) contains a `DeviceChain` (the chain) which contains
`Devices`.

| Element                  | Occurrences in 40 sets (audio and MIDI tracks) |
| ------------------------ | ---------------------------------------------- |
| `AudioEffectGroupDevice` | 56                                             |
| `AutoFilter`             | 2                                              |
| `Compressor2`            | 18                                             |
| `Cabinet`                | 4                                              |
| `DrumGroupDevice`        | 16                                             |
| `Eq8`                    | 179                                            |
| `GlueCompressor`         | 125                                            |
| `InstrumentGroupDevice`  | 4                                              |
| `Limiter`                | 24                                             |
| `MultibandDynamics`      | 24                                             |
| `MxDeviceAudioEffect`    | 6                                              |
| `OriginalSimpler`        | 2                                              |
| `PluginDevice`           | 153                                            |
| `Reverb`                 | 4                                              |
| `Saturator`              | 24                                             |
| `Spectral`               | 2                                              |
| `StereoGain`             | 37                                             |
| `Tube`                   | 9                                              |
| `Tuner`                  | 15                                             |

`AudioEffectGroupDevice` is not a device that processes audio itself — it
**holds** a group's device chain, in its branches. See section 9.3.

### A device chain can be nested

A chain is not always one level deep. An `AudioEffectGroupDevice` holds a chain
in its branches, at this path:

```text
DeviceChain / DeviceChain / Devices / AudioEffectGroupDevice / Branches / AudioEffectBranch /
  DeviceChain / AudioToAudioDeviceChain / Devices
```

The devices inside it are the ones that actually run. A reader that looks only
at the top level of the chain misses them: in a 40-set sample, **14 of the 87
tracks that have a plug-in** hold their plug-ins only inside a group branch, and
no plug-in appears at the top level of their chain.

The same applies to a `DrumGroupDevice`, which holds a drum rack, and an
`InstrumentGroupDevice`, which holds a rack.

**So the devices to report are every device in any `Devices` element, at any
depth.** The container devices themselves are not reported — they are not
devices that process audio — but their contents are.

| Container                | Occurrences in 40 sets |
| ------------------------ | ---------------------- |
| `AudioEffectGroupDevice` | 68                     |
| `DrumGroupDevice`        | 16                     |
| `InstrumentGroupDevice`  | 4                      |

All 68 of the `AudioEffectGroupDevice` elements in the sample contain devices in
their branches.

## Group tracks

A group track is a **summing container**, not a track that plays clips.
Ableton's manuals are explicit about this in both Live 11 (section 16.3) and
Live 12 (section 18.3):

> Group Tracks cannot contain clips, but they are similar to audio tracks in
> that they have mixer controls and can host audio effects.

Group tracks exist in Live 11 as well as Live 12. Live 11 sets in the corpus
rarely have them, and 29 of the 32 Live 11 sets in `$songs` were written by
`live_set -11` itself, so the corpus is a poor guide to how common they are. The
repo's own `after_real_pain.xsd` includes `GroupTrack` and `GroupTrackSlot`
elements.

### 9.1 A group track has no clips

Measured over the whole corpus:

| Measurement                                     | Result                                 |
| ----------------------------------------------- | -------------------------------------- |
| `GroupTrack` elements                           | 1603                                   |
| `AudioClip` inside any of them                  | **0**                                  |
| `MidiClip` inside any of them                   | **0**                                  |
| `GroupTrackSlot` elements                       | 14031                                  |
| …that contain a `ClipSlot/Value`                | **0** — every one is a bare `<LomId/>` |
| `GroupTrack` with a `DeviceChain/MainSequencer` | **0**                                  |

A group track *looks* like it has a session view. It has a `Slots` element
holding eight `GroupTrackSlot` children, but every slot is empty and has no
`ClipSlot` child at all. Its `DeviceChain` has no `MainSequencer` — it has a
`FreezeSequencer` instead, whose `ClipSlotList` is likewise empty.

**So a group track contributes nothing to clip reporting.** `live_set` ignores
group tracks when it reports clips, their sizes, and whether their samples have
been collected.

### 9.2 A group track is not a track in the data model

The membership is a single attribute on the member track. A track's
`TrackGroupId` holds the `Id` of the group it belongs to, and `-1` means it is
at the top level.

| Live version | Sets | Sets with groups | Groups |
| ------------ | ---- | ---------------- | ------ |
| 8            | 21   | 0                | 0      |
| 11           | 32   | 0                | 0      |
| 12           | 407  | 281              | 1603   |

Groups nest: a group track has its own `TrackGroupId`, so a group can contain
another group. In the sample set `Urban_Agony.als`, group 47 has
`TrackGroupId="27"` — it is inside group 27.

A group track has a full mixer, like a regular track: `Sends`, `Pan`, `Volume`,
`CrossFadeState`. That is what makes it a submixer.

### 9.2.1 How nesting is represented

**`live_set` has found no `FakeGroup` element.** There is a claim that the
`.als` format uses a `<FakeGroup>` element — a phantom routing target that wraps
a group inside another group. No such element has been found in any set that has
been examined.

That is a statement about the evidence, not a proof of absence. The corpus is
one person's collection, and it holds 314 nested group tracks, so nesting
plainly does occur. The evidence against `FakeGroup` is:

| Check | Result |
| ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------- |
| The string "fake", any case, anywhere in 460 sets                                                      | **0** occurrences — not an element, attribute, or value |
| The string "fake" in the 61,000-line `evasiva.xml` test file in `pyableton`                            | **0** occurrences                                       |
| `FakeGroup` in the source of `pyableton`, `als-parser`, `abletron`, `AbletonParsing`, `ableton-parser` | **0** occurrences                                       |
| `FakeGroup` in the repo's `after_real_pain.xsd`                                                        | **0** occurrences                                       |
| Web search for `"FakeGroup"` with Ableton / Live / `.als`                                              | Nothing but unrelated projects named "fakegroup"        |

And the specific elements that the claim names do not appear either. In a
120-file sample:

| Element                                      | Occurrences |
| -------------------------------------------- | ---         |
| `TrackWrapperType`                           | 0           |
| `RoutingTarget`                              | 0                                                                                                                                                                                                                                |
| any element matching `*Wrapper*`             | only the real ones: `ParametersListWrapper`, `DevicesListWrapper`, `ClipSlotsListWrapper`, `ArrangementClipsListWrapper`, `TakeLanesListWrapper`, `SendsListWrapper`, `ChainsListWrapper`, `ReturnChainsListWrapper`, and others |
| any attribute *value* containing "FakeGroup" | 0           |

The strongest evidence is structural. A nested group and a top-level group have
**exactly the same child elements** — the same 21 of them, in the same order,
with the same `*ListWrapper` elements. The only difference between them is the
value of `TrackGroupId` and the routing target. If `FakeGroup` existed as a
structural wrapper, a nested group would have to contain something a top-level
group does not.

What nesting actually uses is the same two mechanisms as everything else in the
format: an `Id` and an `AudioOut/GroupTrack` routing target.

A group track's `TrackGroupId` names its parent group, and `-1` means it is at
the top level. Its `AudioOutputRouting/Target` is `AudioOut/GroupTrack` when it
is inside another group, and `AudioOut/Main` when it is not.

The `Tracks` element is a **flat list**. A group is not a container element in
the XML — it is a sibling of the tracks it contains, and the membership is
expressed by attribute. From `Urban_Agony.als`, in document order:

```xml
<GroupTrack Id="27" ...>            <!-- TrackGroupId="-1", routes to AudioOut/Main -->
  <GroupTrack Id="47" ...>          <!-- TrackGroupId="27",  routes to AudioOut/GroupTrack -->
    <AudioTrack Id="8" ... />       <!-- TrackGroupId="47",  routes to AudioOut/GroupTrack -->
    <AudioTrack Id="46" ... />
    <AudioTrack Id="45" ... />
  </GroupTrack>
  <AudioTrack Id="15" ... />        <!-- TrackGroupId="27",  routes to AudioOut/GroupTrack -->
  <AudioTrack Id="54" ... />
</GroupTrack>
```

(The indentation is for readability only — in the file these are all siblings
under `Tracks`.)

So a member's routing target names its **immediate** parent, and the signal path
is the chain of parents: a track in group 47 is routed into group 47, which is
routed into group 27, which is routed into Main.

Two things follow:

- **The hierarchy is recoverable** by following `TrackGroupId` up from a track.
  Nothing needs to be inferred.
- **A track's own routing target is not enough to know its group.** A member
  routed to `AudioOut/GroupTrack` does not say *which* group. That is what
  `TrackGroupId` is for.

The corpus has **314** nested group tracks — groups whose `TrackGroupId` is not
`-1`. Every one of them routes to `AudioOut/GroupTrack`.

`LinkedTrackGroupId` is **not** the parent indicator, despite the name. It is
`-1` for every group in the corpus — all 1289 top-level groups and all 314
nested ones — so it carries no information about the hierarchy. `TrackGroupId`
is the only thing that does.

There is also a plural `LinkedTrackGroups` element. It appears 439 times in the
corpus, and it is **always empty**.


### 9.3 A group's devices are in its members' signal path

The output of a track that is a member of a group is routed to the group:

```xml
<AudioOutputRouting>
  <Target Value="AudioOut/GroupTrack"/>
  <UpperDisplayString Value="Group"/>
</AudioOutputRouting>
```

In a 40-set sample:

| Track output target        | Tracks |
| -------------------------- | ---    |
| `AudioOut/GroupTrack`      | 543    |
| `AudioOut/Main`            | 136    |
| `AudioOut/Track.8/TrackIn` | 2      |

Almost every member is routed into its group: across the whole corpus, **6761 of
6775** group members route to `AudioOut/GroupTrack`. The 14 that do not are
routed to an external output (`AudioOut/External/S0` and the like), so their
audio does not pass through the group.

A group's own output then goes to `AudioOut/Main` (110 groups) or to a parent
group (8 groups), so audio flows up the tree.

A member track holds an `AudioEffectGroupDevice`, and that device holds the
group's chain in its branches. The member's own top-level chain does **not**
repeat the group's devices — group 43 in `Urban_Agony.als` owns `FilterEQ3`,
`Limiter`, `PluginDevice` and `Reverb`, and its member tracks have chains of
their own that contain only the `AudioEffectGroupDevice` and, sometimes, a
native device.

|                | Group 43 | Member track 30 |
| -------------- | -------- | --------------- |
| `FilterEQ3`    | 1        | 0               |
| `Limiter`      | 1        | 0               |
| `Reverb`       | 1        | 0               |
| `PluginDevice` | 1        | 0               |

The devices inside the branch are the ones that run. A member's branch holds the
group's chain together with the member's own devices, so the devices to report
are at every depth — see section 8.2.

TODO WTF is this discussion about blocking transfers and blocking group device?

**Consequence for the Push 3 Standalone check:** a third-party plugin in a
group's chain blocks transfer just as much as one on a track, because the
member's audio passes through it. A report that only inspects member tracks
would say "no blocking devices" when the group blocks transfer. `live_set`
therefore checks a group's devices and reports a blocking group device as an
error naming the group and the tracks whose audio it affects.

Across the corpus, 151 group tracks have a `PluginDevice` in their chain.

### 9.3.1 Freezing a member does not get the group's device out of the way

A group track cannot be frozen, so the device cannot be rendered away by
freezing the group. Nor does freezing a member help: a frozen member stays
routed into its group, so the group's device is still in the signal path. All 21
frozen members in the corpus are still routed to `AudioOut/GroupTrack`.

The remedy is to remove the device from the group's chain, or to bounce the
group.

> Note that while Group Tracks cannot be frozen, they can be bounced to audio,
> which can help reduce their CPU load.

— Live 12 manual, section 38.1.4. Bouncing a group is a different operation from
bouncing an individual track: the manual notes that "Group Tracks are bounced
post-mixer", so the bounced audio includes the group's mixer settings and its
effects, whereas an individual track is bounced pre-mixer.


### 9.4 A group track cannot be frozen

> Note that you can only freeze tracks that hold clips, so it is not possible to
> freeze a Group Track, a return track, or the Main track.

— Live 12 manual, section 38.1.4 "Track Freeze". The Live 11 manual (section
33.1.4) says the same.

A group track holds no clips, so it cannot be frozen. The corpus agrees: **0 of
1603** group tracks have `Freeze="true"`, and 195 of 195 in a 60-set sample have
`Freeze="false"`.

This answers the question of whether freezing a group track also freezes the
tracks inside it: **the question does not arise**, because a group track cannot
be frozen at all.

#### 9.4.1 The `Options.txt` hidden option

Ableton's `Options.txt` file can enable "a few experimental and unsupported
features".

**`live_set` does not support experimental features.** It ignores `Options.txt`
entirely, and treats every setting that `Options.txt` can control as having its
standard behaviour, as though the experimental option had not been specified. A
set that uses `GroupTrackFreeze` is therefore read as though the group were not
frozen, and the group's members are read as unfrozen.


## Booleans

`Freeze` (on audio, group and MIDI tracks) and `IsTempoEnabled` (on scenes) hold
`"true"` or `"false"` in a `Value` attribute.


## 11. Frozen tracks and the `FreezeSequencer`

A track that is frozen has a second sequencer. `MainSequencer` holds the
editable material; `FreezeSequencer` holds the rendered audio cache that
replaces it during playback. The cache files live in the project folder under
`Samples/Processed/Freeze`.

> When you right-click a track and choose Freeze Track, Ableton does not destroy
> or replace your original data. Instead, it compiles that track into a
> background audio file and modifies the XML layout.

Both sequencers exist at the same time, and a frozen track's clips can be found
in either.

Measured over the corpus's 256 frozen tracks:

|                                                    | Tracks |
| -------------------------------------------------- | ------ |
| Clips in `MainSequencer` **and** `FreezeSequencer` | 155    |
| Clips **only** in `FreezeSequencer`                | **20** |
| Clips only in `MainSequencer`                      | 0      |
| No clips at all                                    | 81     |

**A frozen track's audio is not always in `MainSequencer`.** `live_set` must
look in both places, or it reports zero clips — and therefore no
uncollected-sample warnings and a size of zero — for a track that is holding
hundreds of megabytes of frozen audio.

The two sequencers hold the same kinds of clip. Under `MainSequencer` the paths
are:

```text
DeviceChain / MainSequencer / ClipSlotList / ClipSlot / ClipSlot / Value / AudioClip
DeviceChain / MainSequencer / Sample / ArrangerAutomation / Events / AudioClip
```

and under `FreezeSequencer` they are:

```text
DeviceChain / FreezeSequencer / ClipSlotList / ClipSlot / ClipSlot / Value / AudioClip
DeviceChain / FreezeSequencer / Sample / ArrangerAutomation / Events / AudioClip
```

A frozen track's arrangement clips live under
`FreezeSequencer/Sample/ArrangerAutomation/Events` rather than under
`MainSequencer`.


## How `live_set` reads all this

| Element                                                                           | Read with                                                                |
| --------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| `ArrangerAutomation/Events/AudioClip`, `TakeLane/ClipAutomation/Events/AudioClip` | `xpath`, then `xml_value` for the values                                 |
| `AudioOutputRouting/Target`                                                       | `xml_value`, to see whether a member is routed into its group            |
| `ClipSlotList/ClipSlot/ClipSlot/Value/AudioClip`                                  | `xpath`, then `xml_value` for the values                                 |
| `FileRef/RelativePath`, `FileRef/Path`, `FileRef/OriginalFileSize`                | `xml_value`                                                              |
| `Freeze`, `IsTempoEnabled`                                                        | `xml_bool?`                                                              |
| `Name/EffectiveName`, `Name/UserName`                                             | `xml_value`                                                              |
| `PluginDesc/VstPluginInfo/PlugName`, `PluginDesc/Vst3PluginInfo/Name`             | `xml_value`                                                              |
| The devices in a chain                                                            | `xml_chain_devices`, which looks in every `Devices` element at any depth |
| `TrackGroupId`                                                                    | `xml_value`, to find a track's group                                     |

Do not use `Nokogiri::Slop` accessors for these. A Slop accessor returns a
single `Element` for one match, a `NodeSet` for two or more, and raises
`NoMethodError` for none — so the same expression behaves three different ways
depending on the document. `xpath` always returns a `NodeSet`.
