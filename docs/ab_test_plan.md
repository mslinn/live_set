# The A/B program of nearly-empty sets

TODO: The user's suggestion was not properly captured. thus this explanation
is misleading. Ignore this document until further notice.

The program for finding out what Live 12 does to a Live 11 set, one small thing at a time.

## What the program is

We will do a lot of testing of nearly-empty Live 11 sets. A set is nearly empty when it holds
one thing — a track, a clip, a device, whatever the case needs — and as little else as Live
allows.

Each set of the program is written by Live 11, opened in Live 12, written by Live 12, and the two
documents are compared. What Live 12 did to the set is what the bridge has to reproduce, and
what the version_diff document has to record. The sets are small on purpose: a difference
between two versions of Live is easy to read in a set that holds one thing, and hard to read in
a set that holds the demo set.

## The steps of a case

1. **Author it in Live 11, and save it there.** Live 11 writes the set, so the set is in the
   format of Live 11 as Live 11 itself writes it. A set that was written by hand, by editing the
   XML, is not a case: Live has not accepted it, and until it has, nothing the set says about
   the format of Live 11 is known to be true.
2. **Open it in Live 12, and save it there.** The tool that does that is
   `dev/make_reference_set`:

   ```shell
   bundle exec ruby dev/make_reference_set 12 <name> sets/live_11/projects_and_als/<set>
   ```

   It opens the set in Live 12, waits for Live to say that it has loaded it, and saves it under
   the name it is given. The set is written as the Live that is installed writes it, so a set
   written by another build of Live 12 is not the same set.
3. **Compare the two documents.** The machinery for that is the version_diff machinery, and the
   differences between Live 11 and Live 12 are recorded in
   [live_11_12_diff.md](live_11_12_diff.md). Every difference that the bridge does not already
   account for is new work: it goes into the bridge in `lib/live_set/tx/`, and into that
   document.
4. **Write down what the set holds.** The analysis of the set is the report `live_set` writes
   for it: the tracks, the state of each one, the effects on it, and the clips of it. The
   analyses are in the reports directory of the version of the set, in the repository of the
   reference sets, and they are made by `dev/generate_reference_als_reports`.

A case is done when the bridge reproduces what Live 12 did, and the version_diff document says
what the difference is.

## Where the sets live

A set of Live is a project folder: the set is the `.als` file in it, and only that file is
checked in.

```text
sets/live_11/projects_and_als/<name>_11 Project/<name>_11.als
sets/live_12/projects_and_als/<name>_12_converted_by_live Project/<name>_12_converted_by_live.als
```

The name of a set says what it holds, so that the corpus can be read: `one_midi_track_only_11`
is a set with one MIDI track in the arrangement. The return tracks are part of what Live writes
in every set, and are not part of what a case is about.

The first case of the program is already made:

```text
sets/live_11/projects_and_als/one_midi_track_only_11 Project/one_midi_track_only_11.als
```

It was written by Live 11.3.43 and holds one MIDI track in the arrangement, the two return
tracks of the arrangement, the master return track, and no audio track. Its Live 12 counterpart
has not been made yet.

## The factory-default set

The sets of the program are made from the set that Live makes when it is asked for a new one,
and that set has to be the factory default and not the template of the user. To get it:

> Hold down the Shift key while going to File > New Live Set in the top menu.

That set is **not** an empty Live set. It holds an audio track and a MIDI track. Every case of
the program starts from those two tracks, and what follows from that is what the interface
allows:

- The MIDI track can be deleted.
- Once the MIDI track is gone, the audio track cannot be deleted: Live will not delete the last
  track that is left.
- Restoring the MIDI track, and deleting the audio track again, works. The result is a set with
  one MIDI track and no audio track.

So the smallest set that can be made through the interface is a set with one track. A set with
no tracks at all cannot be made that way, and the cases of the program are therefore not sets
with no tracks — unless the questions below are settled otherwise.

## The factory default, and the set that was saved under its name

Ableton's article on the default and template sets
(https://help.ableton.com/hc/en-us/articles/209067189-Default-Set-and-Template-Sets) says of the
default set:

> "The Default Set is the project that automatically opens when you launch Ableton Live."
> "The factory Default Set contains two audio tracks, two MIDI tracks, and two return tracks."

and gives the places the sets of the user live: the template sets in
`C:\Users\[Username]\Documents\Ableton\User Library\Templates`, and, for Live 10 and earlier,
the default set in `…\AppData\Roaming\Ableton\Live x.x.x\Preferences\Template.als`. The Shift
key is not in the article: holding it down while choosing File > New Live Set is not written
down anywhere by Ableton.

Live keeps its own copy of the factory default set, and it is on disk:

| version | where the factory default set is | what it holds |
| --- | --- | --- |
| Live 11 | `%APPDATA%\Ableton\Live 11.3.43\Preferences\BaseFiles\DefaultLiveSet.als` | `1-MIDI`, `2-MIDI`, `3-Audio`, `4-Audio`, `A-Reverb`, `B-Delay`, `Master` |
| Live 12 | `C:\ProgramData\Ableton\Live 12 Suite\Resources\Builtin\Templates\DefaultLiveSet.als` | the same tracks, and `Main` in place of `Master` |

Both were written by Live 11.1d1 and Live 12.1d1 respectively, and both hold two audio tracks,
two MIDI tracks and two return tracks, as the article says. The copy of Live 11's is not in the
folder where it belongs at the moment: the crash machinery moved it into the crash archive, and
it is moved again at every crash.

**The set saved as `factory_default_11.als` is not the factory default.** It holds one audio
track (`1-Audio`), one MIDI track (`2-MIDI`) and the return tracks `A-Return` and `B-Return`,
and it is Live's *new empty set*: the set Live makes when it is asked for a new one. On this
machine there are no user template sets and no user default set, so the Shift key has nothing to
bypass and the shortcut makes no difference.

The factory default set is the better case, and it is a case that has not been made: it has
four tracks instead of two, and its return tracks are named `A-Reverb` and `B-Delay` where the
empty set's are named `A-Return` and `B-Return`. The two sets of the factory default, one per
version, differ in exactly one way that the analyses have found: Live 11 writes the master track
as `<MasterTrack>` and Live 12 writes it as `<MainTrack>`.

## The questions that are open

**What happens when every track is removed?** The interface will not do it, but a set that has
no tracks can be written by hand. Whether Live 11 and Live 12 load such a set is not known, and
it matters: a set with no tracks is the first case of the program, and it is the case in which
the differences between the versions have least to say.

**Will Live 11 and Live 12 load a programmatically created empty Live set?** A set written by
hand, with no tracks, that Live has never written. Live is strict about the sets it opens, and a
set that Live rejects is not a case at all — it is a file. The question is whether the format
allows a set with no tracks, and whether the two versions agree about it.

**Can the MIDI track be deleted when it is the only track left?** The refusal to delete the
audio track when the MIDI track was gone says that Live protects the arrangement from being
emptied. Whether the protection is about the last track of any kind, or about an audio track
being the last one, is not settled by what was observed: in the case above the audio track
could be deleted once a MIDI track was there again, which rules out the second reading.

## The dependency on the harness

The program needs many runs, and each run switches the version of Live that is running. Live
asks for the permission of an administrator when it starts and finds that another version ran
last, which used to stop the program for a person to answer. The harness now writes a per-user
registration of the `ableton:` protocol before it starts Live, and takes it away when the run is
over, so that no prompt comes and the machine is as it was before the run. That is described in
the `gui_harness` project, in `docs/elevation.md`.

The tool that opens a set in Live 12 is `dev/make_reference_set`, and it uses the harness.
