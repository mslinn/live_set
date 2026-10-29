# The Release Notes of Live

The release notes tell you what Ableton changed between two versions of Live.
The XML stored in the sets of those two versions can be inspected to reveal
the structure of each one, and comparing the two structures reveals the
changes between the Live versions that produced those files.

The two are the evidence the version_diff documents are built from: the
release notes tell you what changed, and the comparison of the two structures
shows you what the change looks like in the XML.

The release notes are written for the musicians who use Live, so they describe
the features in the words a musician would use, and they never give an element
name, an attribute name, or any part of the file format. They are therefore a
filter over the differences rather than a source of them: they say which
differences to expect and which version introduced each one, and the names
themselves have to come from the XML stored in the sets.

## The files in this directory

One HTML file per version, downloaded from Ableton's web site:

| File | Version | Page it came from |
| ---- | ------- | ----------------- |
| `live-8.html` | Live 8 | <https://www.ableton.com/en/release-notes/live-8/> |
| `live-9.html` | Live 9 | <https://www.ableton.com/en/release-notes/live-9/> |
| `live-10.html` | Live 10 | <https://www.ableton.com/en/release-notes/live-10/> |
| `live-11.html` | Live 11 | <https://www.ableton.com/en/release-notes/live-11/> |
| `live-12.html` | Live 12 | <https://www.ableton.com/en/release-notes/live-12/> |

The index that lists them is at
[All Ableton Release Notes](https://help.ableton.com/hc/en-us/articles/212040005-All-Ableton-Release-Notes).
The index lists Live 10 and later; the Live 9 and Live 8 pages are reached
directly. The beta variant of each page is ignored.

## How to read them

The files are HTML, written for a browser. `exe/release_notes` prints them as
markdown, which is what a person writing a version_diff document wants:

```shell
exe/release_notes 12          # the notes of Live 12
exe/release_notes 12.0        # the notes of the release 12.0
exe/release_notes 12 --find "scale awareness"
```

The last form prints the lines that match, each with the release it belongs to,
which is how a question like "which version added this?" is answered. The notes
of a version begin with its first release and run backwards from there, so the
newest release is printed first.

The markdown can be kept beside the HTML it came from:

```shell
exe/release_notes 12 > docs/release_notes/live-12.md
```

## Where the release notes live

**Live does not install a copy of its release notes.** No version of Live puts
one on the computer, so the web pages are the only source, and they are copied
here.

The help centre, at `help.ableton.com`, is behind a Cloudflare bot check. A
plain fetch of the index there returns HTTP 403 and a "Just a moment…"
page, and neither `curl` nor `WebFetch` gets past it. The pages that carry
the notes themselves are on `www.ableton.com`, which serves plain HTML, so
they are fetched directly:

```shell
mkdir -p docs/release_notes
for v in 8 9 10 11 12; do
  wget -q -O "docs/release_notes/live-$v.html" \
    "https://www.ableton.com/en/release-notes/live-$v/"
done
```

`curl` fetches these pages as well as `wget` does. The bot check is on the
help centre host only, and only the index page is behind it.

## What the notes are for

A version_diff document covers two versions of Live, and every difference in
it is something the newer of the two changed relative to the older one. The
release notes of that newer version are therefore the list of candidates for
the document, and they supply its items. The outline is the same in every
version_diff document: the newer version's release notes summarized, and then
the format differences that follow from each item.

A difference is attributed to the version that introduced it. It appears in
the version_diff document for the two versions between which the introduction
falls, and not in the document above it. A similarity is not a difference, and
does not belong in a version_diff document at all.

## What the notes do not cover

The notes of a version begin with its first release, but the earliest releases
of the older versions are thinly recorded:

| Version | The notes begin | What the first entry says |
| ------- | ---------------- | ------------------------- |
| Live 12 | 12.0 | a full account of the new features |
| Live 11 | 11.0 | a full account of the new features |
| Live 10 | 10.0 | a full account of the new features |
| Live 9 | 9.0 | "Initial release (DVD only)" — the features are described from 9.1 on |
| Live 8 | 8.2 | the features of 8.0 and 8.1 are not described at all |

So the release notes are a complete account of what Live 10, 11 and 12
changed, and a partial account of what Live 8 and 9 changed. Where the notes
are silent, the differences between two versions have to be found by diffing
the schemas of the two versions, which is the method described in
[`../als_work.md`](../als_work.md) under "Mapping XSD to Ruby Classes".
