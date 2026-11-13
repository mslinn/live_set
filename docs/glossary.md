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
[ab_test_plan.md](dev/ab_test_plan.md).


## ALS File

An XML document whose root element is `<Ableton/>`, in a file with an `.als`
filetype. This file is usually gzipped.


## ALS XML

The XML within an [ALS file](#als-file).


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
versions are recorded in [live_11_12_diff.md](dev/live_11_12_diff.md).

## Clip

A passage of musical material in a set: a melody, a drum pattern, a bassline. A
clip belongs to a place — a slot of the session view, a position on the
arrangement timeline, a take lane. There are many types of clips, including MIDI
and audio.

Two clips that carry the same name and play the same file are alike, but they
are not the same clip. [`als_report`](../exe/als_report) counts how many places
have a copy of a clip.

See [als_notes.md](dev/als_notes.md) for `AudioClip` and `MidiClip`.

## Conversion

The act of converting a set from one version of Live to another. See classes
[`LiveSetConverter`](../lib/als_to_version/live_set_converter.rb) and
[`LiveVersions`](../lib/live_set/tx/live_versions.rb).

## Corpus

The reference sets available to be examined, including the demo sets of every
installed version of Live, specially prepared sets for A/B testing, and the
460-set Mike Slinn has in the `$songs` directory of computer Bear. See
[als_work.md](dev/als_work.md), "Corpus of Demo Sets".


## Demo set

A set that ships with Live. See
[$live_reference_sets/sets](https://github.com/mslinn/live_reference_sets/tree/master/sets).

## Difference

A node where two versions of Live differ. The kinds of difference are listed in
[conversion.md](dev/conversion.md), "The kinds of difference":

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
belongs in [als_notes.md](dev/als_notes.md).

## Direction

Which way a conversion is going: `:up` from an older version to a newer version,
or `:down` from a newer version to an older version.

## Format

The way Live writes a set: its structure and its data together. Where a document
says "the Live 11 format", read "the Live 11 XML format", which means "the
elements, attributes and values that Live 11 writes".

Thus "the Live 11 format" might seem to be misleading, because the phrase does
not actually refer to formatting.


## Fully resolved size

The size of everything a set draws on: the project, and the assets outside it —
the samples in the user library, the Live Packs, devices, and project samples.


## Ground Truth

A document that Live itself produced, used as the expected result of a
conversion from an older version of Live to a new version. For example, a Live
11 set opened in Live 12 and saved will be the ground truth, including the
XML elements Live adds, the default values it gives them, as well as deleted and
modified XML elements.


## Lane type

The kind of a lane in a track: a MIDI clip lane, an audio clip lane, a MIDI note
lane, or an automation lane. See [live_11_12_diff.md](dev/live_11_12_diff.md), "The
lane types".

TODO Move the discussion of lanes to `als_notes.md`.

## Pair

The word "pair" is not used in these documents because the word has so many
meanings and context is often insufficient to know what the word might mean.


## Project Folder

Live writes a set as a directory named after a set, with the word " Project"
after it. The directory contains the [ALS File](#als-file), along with other
files and a subdirectory with an icon called `Ableton Project
Info/AProject.ico`. OS file managers show the folder as a file.


## Reference sets

Reference sets are checked into the
[`$live_reference_sets`](https://github.com/mslinn/live_reference_sets) Git
project so that they are available for everyone who works on this project.


## Registry

The hash of bridges, keyed by version. The registry is defined in
`lib/live_set/tx/live_versions.rb`.

The hash key is the Live version a bridge coverts a set to. For example, the
registry value for key `12` is the bridge for converting a set from Live 11
[format](#format) to Live 12 format.


## Schema

An XSD file describing the structure of the sets of one version of Live. Stored
in
[$live_reference_sets/xsd](https://github.com/mslinn/live_reference_sets/tree/master/xsd/),
one per version, named for the version that wrote them: `live_10.1.3d1.xsd`,
`live_11.3d1.xsd`, `live_12.4d1.xsd`.

A schema is an inference from the XML stored in the sets of that version, not a
specification. If none of the processed Live sets contain an XML element, the
schema generated from those sets will not include that element. Thus a schema
is unnecessarily stricter than Live.

The schemas are generated by `../dev/als_generate_xsds`, which calls
`../exe/als_to_xsd` on every demo set for a specific Live version. The schemas
are checked into
[`$live_reference_sets/xsd`](https://github.com/mslinn/live_reference_sets/tree/master/xsd),
so that a new contributor can work with the latest information without having to
install that version of Live first.


## Set

A set is a complete Ableton Live project, contained within a [" Project"
folder](#project-folder). Contents include an XML document whose
root element is `Ableton`, in a file with an `.als` filetype. The version of Live that wrote it is in the
`MinorVersion` attribute of that root element.


## Special Transformation

A transformation that a list of names cannot express: a value the two versions
write differently, an element one version wraps and the other keeps bare, an
element that has to move to another parent. They are the hand-written methods of
a bridge's `special_transformations`. There are fifteen of them in
`lib/live_set/tx/live_11_and_12.rb`.

## XML Structure

The elements a document has, the attributes they carry, and how they nest. This
is what a schema describes. Structure is distinct from data.

## Transformation

An operation that turns the XML format for a Live version into the format for
another Live version. The transformations of a bridge are the differences
between the two versions it bridges, expressed as operations on the document: a
rename, a removal, an emptying, an addition.

A transformation is defined in both directions: a rename matches either spelling
and emits the other.

## Up And Down Directions

Converting ALS XML from an older Live version to a newer one is called
converting in the up direction. Up conversions are lossless because they
preserve everything the set contains and only change how it is expressed.
Round-trip conversions starting with the up direction, followed by a down
conversion, are lossless.

Down conversion is converting ALS XML from from a newer Live version to an older
Live version. In general, down conversions are lossy: often the older version
cannot represent XML elements from the newer version. XML elements that are not
present in the older version are dropped. The down direction is therefore not a
functional inverse of the up direction, and down-then-up does not return the
original document.

## Version

The version of Live that wrote a set, read from the `MinorVersion` attribute of
the root `<Ableton/>` element, e.g. `12.0_12402`. The `MajorVersion` attribute
is no use to anyone but Ableton: Live 10, 11 and 12 all write
`MajorVersion="5"`.

## Version_diff

Two adjacent versions of Live, together with the differences between them.  The
document for a version_diff is one of `live_8_9_diff.md`, `live_9_10_diff.md`,
`live_10_11_diff.md`, `live_11_12_diff.md`; the code for a version_diff is a
[bridge](#bridge).
