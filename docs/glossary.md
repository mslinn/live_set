# Glossary

The terms these documents use. Where a word has been used in more than one
sense, the sense meant here is the one the documents mean by it.

## A/B set

TODO: The user's suggestion was not properly captured. thus this explanation
is misleading. Consider this term to be undefined until further notice.

A nearly-empty set of one version of Live, holding one thing — a track, a clip,
a device — and as little else as Live allows. It is written by that version of
Live and then written by the next version, so that the two documents can
be compared, and what the second version did to the set is what the bridge has
to reproduce.

The A/B sets are reference sets, and the program that makes and reads them is in
[ab_test_plan.md](ab_test_plan.md).

## Bridge

A bridge converts a set from one version of Live to another.
`lib/live_set/tx/live_11_and_12.rb` is the bridge between Live 11 and Live 12.

It is handed a set, reads the version the set carries, and works out which way
the set has to go: up to the newer version, or down to the older one. It is not
told which way to go, and it raises an error if the set carries a version it
does not handle.

Most of the conversions it makes are held as lists of names: the elements to
remove, the elements to rename, the attributes to give a value, the elements to
add, and the order the children of an element go in. The machinery that applies
them is in `lib/live_set/tx/live_version_converter.rb`, and it applies the same
list whichever way the set is going — a rename matches either spelling and emits
the other. A list that applies in one direction only holds an entry for each
direction, and the bridge takes the one that applies.

Each list is declared by calling the method of the base class that owns it, and
a bridge has to declare every list, even the ones it has nothing to say about.
A list that is not declared is an error, and it is named.

A bridge never inherits from another bridge. The conversion from Live 12 to
Live 9 is the composition of the bridges between Live 12 and Live 11, Live 11
and Live 10, and Live 10 and Live 9, and each of those bridges stands on its
own. A bridge inherits the machinery of the base class and nothing else.

The rest are hand-written methods in the bridge, for the differences that
lists of names cannot express: a value the two versions write differently, an
element one version wraps and the other keeps bare, an element that has to move
to another parent.

The differences between a version and the previous version are memorialized in
the appropriate `version_diff` document. For example, the bridge
`lib/live_set/tx/live_11_and_12.rb` provides the conversions that transform the
Live 11 XML to and from Live 12 XML, and the differences between those two
versions are recorded in [live_11_12_diff.md](live_11_12_diff.md).

## Clip

A passage of musical material in a set: a melody, a drum pattern, a bassline. A
clip belongs to a place — a slot of the session view, a position on the
arrangement timeline, a take lane. There are many types of clips, including MIDI
and audio.

Two clips that carry the same name and play the same file are alike, but they
are not the same clip. `als_report` counts how many places have a copy of a clip.

See [als_notes.md](als_notes.md) for `AudioClip` and `MidiClip`.

## Conversion

The act of converting a set from one version of Live to another. See classes
`LiveSetConverter` and `LiveVersions`.

## Corpus

The reference sets available to be examined, including the demo sets of every installed
version of Live, specially prepared sets for A/B testing, and the 460-set Mike
Slinn has under `$songs`. See [als_work.md](als_work.md), "Corpus of Demo Sets".


## Demo set

A set that ships with Live. See
[$live_reference_sets](https://github.com/mslinn/live_reference_sets).

## Difference

A node where two versions of Live differ. The kinds of difference are listed in
[conversion.md](conversion.md), "The kinds of difference":

1. an element one version has and the other does not;
2. an attribute one has and the other does not;
3. an element the two name differently;
4. an attribute value or an element value the two spell differently;
5. an element one version has and the other does not;
6. a value that is not legal in one of them;
7. an element one puts at another depth.

A difference belongs to the version that introduced it, so a difference between
Live 11 and Live 12 is described in `live_11_12_diff.md`. A fact all versions
share is by definition not a difference; it is a fact about the format, so it
belongs in [als_notes.md](als_notes.md).

## Direction

Which way a conversion is going: `:up` from an older version to a newer one, or
`:down` from a newer one to an older.

## Format

The way Live writes a set: its structure and its data together. Where a document
says "the Live 11 format", read "the Live 11 XML format", which means "the
elements, attributes and values that Live 11 writes". Thus "the Live 11 format"
does not actually refer to formatting.

## Fully resolved size

The size of everything a set draws on: the project, and the assets outside it — the samples
in the user library, the Live Packs, the Racks, the Live Clips.

A report gives it beside the size of the set file, the expected size of the project and the
actual size of the project, and says what each of them was computed from.

## Ground truth

A document that Live itself produced, used as the expected result of a
conversion. The up direction has one: a Live 11 set is opened in Live 12 and
saved, and the file Live wrote is the ground truth the upgrade is measured
against — including the elements Live adds and the default values it gives them.

## Lane type

The kind of a lane in a track: a MIDI clip lane, an audio clip lane, a MIDI note
lane, an automation lane. Every set of a given version has the same lane types,
and two versions do not have the same ones, so a converted set has to be given
the lane types of the version it is converted to. See
[live_11_12_diff.md](live_11_12_diff.md), "The lane types".

## Pair

The word is not used in these documents. Where two versions of Live are concerned,
the words are "bridge" and "version_diff"; where the same set in two versions is
concerned, the words are "reference sets".

## Project folder

What Live writes a set as: a directory that holds the set and what Live writes
around it. The set is the `.als` file in it, and the folder also holds
`Desktop.ini` and `Ableton Project Info/AProject.ico`. A file manager shows the
folder as a file.

Live appends ` Project` to the name of the set to make the folder, and it makes
the folder itself. Live does not write into a folder that is already there: it
makes a folder with a number on the end of the name instead.

Only the `.als` file of a project folder is checked in.

## Reference sets

Sets that are checked in, so that they are the same for everyone who works on this
project. The demo sets Ableton ships are not reference sets: they are installed with
Live, and they differ from one machine to the next.

`sets/live_11/projects_and_als/Fascination.als` and the Live 12 version of it,
`sets/live_12/projects_and_als/Fascination_12_converted_by_live Project/Fascination_12_converted_by_live.als`,
are the reference sets for Live 11 and Live 12. They are the same set in the two
versions, so the conversion down to Live 11 can be proved against the set Live 11
itself wrote.

## Registry

The list of bridges, keyed by version. The registry is in
`lib/live_set/tx/live_versions.rb`, and the key is the version a bridge leads
to: the entry for 12 is the bridge between Live 11 and Live 12. See
[fix_plan2.md](fix_plan2.md), M7.

## Schema

An XSD file describing the structure of the sets of one version of Live. Stored
in the `xsd/` directory of the repository of the reference sets, one per version,
named for the version that wrote them:
`live_10.1.3d1.xsd`, `live_11.3d1.xsd`, `live_12.4d1.xsd`.
They are generated by `dev/generate_xsds`, which calls `exe/als_to_xsd` on every
demo set of the version. They are checked in, so that a new contributor and a
new machine can work with the latest information without having to install
Live first; regenerating them is a matter of running `dev/generate_xsds` again.

A schema is an inference from the XML stored in the sets of that version, not a
specification of it: a name the schema does not declare is a name no set in the
corpus uses, which is not the same as a name the version does not have. A schema
inferred from too few sets is stricter than Live is.

## Set

An Ableton Live project, as the file Live writes it: a gzipped XML document whose
root element is `Ableton`. The version of Live that wrote it is in the
`MinorVersion` attribute of that root element.

## Special transformation

A transformation that a list of names cannot express: a value the two versions
write differently, an element one version wraps and the other keeps bare, an
element that has to move to another parent. They are the hand-written methods of
a bridge's `special_transformations`. There are fifteen of them in
`lib/live_set/tx/live_11_and_12.rb`.

## Structure

The elements a document has, the attributes they carry, and how they nest. It is
what a schema describes. Structure is distinct from data.

## Transformation

An operation that turns a document into another document. The transformations of
a bridge are the differences between the two versions it bridges, expressed as
operations on the document: a rename, a removal, an emptying, an addition.

A transformation does not say which way it goes. A rename matches either
spelling and emits the other, so the same transformation carries both
directions.

In `lib/live_set/tx/live_12_to_live_11.xsl`, the stylesheet that is kept for
comparison, the word is used in the XSLT sense: a stylesheet compiles to a
transformation, and that transformation is the whole conversion there, not one
operation.

## Up direction and down direction

Up is from an older version to a newer one. It is lossless: it preserves
everything the set contains and changes only how it is expressed, and it
reproduces Live's own conversion.

Down is from a newer version to an older one. It is lossy: constructs the older
version cannot represent are dropped and cannot be recovered. The down direction
is therefore not a functional inverse of the up direction, and down-then-up does
not return the original document.

## Version

The version of Live that wrote a set, read from the `MinorVersion` attribute of
the root element, e.g. `12.0_12402`. The major version is no help: Live 10, 11
and 12 all write `MajorVersion="5"`.

## Version_diff

Two adjacent versions of Live, together with the differences between them.
The document for a version_diff is one of `live_8_9_diff.md`, `live_9_10_diff.md`,
`live_10_11_diff.md`, `live_11_12_diff.md`; the code for one is a bridge.
