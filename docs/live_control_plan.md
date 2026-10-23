# A plan to test the Live 11 conversion against Live 11 itself

`live_set -11` is supposed to convert a Live 12 set into the best representation
possible in Live 11 format; any use of unsupported Live 12 features is stripped
away and is not saved in the converted file.


## Problem Background

We needed to run Ableton Live many times when reverse engineering various
versions of the Ableton Live `als` file format. However, we encountered a
problem: our test runs of Ableton Live were non-deterministic. The source of the
problem was that if Live crashed, the next launch would pop up a dialog box and
test automation would stop. This document describes a solution in every detail.

We wrote some checks (specs) to inspect the converted file: the XML was well formed,
the element names were right, the version strings were right.
TODO: Where are these checks? They probably need to be made more effective. find
them and present them for discussion.

## Purpose

This document describes the round-trip test that proves a conversion from Live
12 data back to the Live 11 format is valid. The purpose is not to treat a
Live 12 demo set as a fixed oracle. The purpose is to take a real Live 11 set,
save it in Live 12, convert it back with `live_set -11`, inspect the converted
XML, and then ask Live 11 whether it accepts the result.

The end-to-end test is the proving instrument, but it is not the first gate. We
must first check the converted ALS file itself: if the XML is structurally
invalid, or if the conversion has lost required elements or default values, Live
11 is not the next step.

This document is the plan for building the round-trip mechanism: code that uses
an original Live 11 set as the source, converts it through Live 12 and back to
Live 11, probes the converted `.als` file, feeds the result to Live 11, and
reports back to the unit test what happened.

### The actual round-trip sequence

The round trip is the core of the plan, and it starts from a real Live 11 set:

1. Start from the official Live 11 demo set shipped with Ableton 11, found by the
   repository helper in `spec/demo_sets.rb` via `DemoSets.edition '11', 'Suite'` (or the
   equivalent version-specific lookup).
2. Open it in Live 12 and save it, creating the Live 12 version of the same song.
3. Run `live_set -11` to convert that Live 12 result back to the Live 11 format.
4. Probe the converted `.als` file as XML before invoking Live 11.
5. Run the structural sanity checks on the converted file.
6. Only if the converted file passes those checks, launch Live 11 against it.
7. Record whether Live 11 accepts it, crashes, or blocks on a prompt.
8. Read back the relevant document content and compare it with the original Live 11 set:
   - track structure
   - clip structure
   - group membership
   - lane data
   - version strings and invariant values

This is the whole point of the round trip: convert the same material across
versions, inspect the result, and see whether Live 11 accepts it and preserves
the meaningful data.

### Required pre-flight gate: XML sanity checks before Live 11 launch

The Live 12 source is a generated artifact, not a canonical or fixed oracle. It
is still valuable, but it is not the ground truth in the same sense as the
starting Live 11 set. The conversion must therefore be proven in stages: first
structure, then acceptance by Live 11.

The round-trip flow therefore needs this pre-flight gate:

1. convert the Live 12 source set to the Live 11 format;
2. parse the resulting `.als` file as XML;
3. run the structural sanity checks before launching Live 11;
4. only if the file passes those checks should Live 11 be started.

The official Live 11 demo sets are already searched for and located in the repository helper
`spec/demo_sets.rb`, which follows Ableton's documented location and falls back to the known
installed paths on the test machine. That helper is the place the plan should call out as the
source of the initial Live 11 set used in the round trip.

The existing XML checks live in the suite and are the obvious starting point:

- `spec/live_set/live_set_modify_als_spec.rb`
  - checks the Live 11 creator/version strings;
  - checks track, group, clip, and device counts;
  - checks group membership and lane renames;
  - checks unsupported Live 12-only elements are removed;
  - checks the Oversampling rewrite and the Live 11 round-trip comparisons.

These checks are useful, but they are not yet a formal gate in the harness play.
They should be reviewed and made explicit as the pre-flight contract before the
Live 11 launch step.

This ordering matters: the round-trip test is the proof, but the XML gate is the
first filter. Without it, the harness can waste time launching Live on a file
that is already structurally invalid.

### Terminology

The plan uses these terms consistently:

- `source set`: the original Live 12 `.als` file produced by Ableton Live.
- `converted file`: the Live 11-compatible file produced by `live_set`.
- `round-tripped result`: the converted file after it is opened in Live 11 and
  checked by the harness.
- `harness`: the Ruby test infrastructure that launches Live, watches the log,
  answers dialogs, and reports the outcome.
- `research finding`: an observation or fact established from Live's behavior,
  documentation, or log files.
- `implementation action`: the code or test step that turns a finding into an
  executable part of the harness.

These terms are used throughout the document: research findings describe what
is true about Live's behavior, while implementation actions describe what the
code in this repository is meant to do.

## Current validation coverage

The existing validation checks are already in the suite and are the baseline for
this work. They are not a replacement for the harness, but they do provide the
first layer of evidence:

- `spec/live_set/live_set_modify_als_spec.rb`
  - checks the Live 11 creator/version strings
  - checks track counts, group membership, clips, devices, and lane renames
  - verifies unsupported Live 12-only elements are removed
  - checks the oversampling rewrite and the round-trip against a Live 11 demo set

- `spec/integration/live_set_round_trip_spec.rb`
  - launches Live 11 against the converted set
  - asserts no error dialog is shown
  - asserts the log reaches `End ExchangeDocument`

- `spec/support/live_harness/live_log_spec.rb`
  - validates the log parser in success, crash, restore, and missing-log cases

- `spec/support/live_harness/live_recovery_spec.rb`
  - validates recovery-file parsing for pending crashes
  - validates extraction of the set path from `CrashRecoveryInfo.cfg`
  - validates UTF-16 string parsing used to recover the file name

This is the important point for the plan: the repository already contains a
meaningful validation layer, and the remaining work is to make the harness and
the conversion checks explicit, repeatable, and strong enough to support the
round trip as a formal test. The key requirement is that the XML sanity checks
must be run as a gate before the Live 11 launch, because the round trip is meant
to prove conversion validity across version boundaries, not simply to launch Live
11 on a file that has not yet been read back and checked.

## Research Is Complete

Everything in this section was checked during this work, or in Ableton's own
documentation.  Nothing here is assumed.

### The installation

On macOS the installation is an application bundle,
`/Applications/Live <Version>.app`, with the executable at `Contents/MacOS/` and the demo sets
at `Contents/App Resources/Core Library/Lessons/Demo Songs`.

On Windows, Live installs every edition under one directory:

```text
%ProgramData%\Ableton\Live <Version> <Edition>\
```

For all operating systems, the executable and the demo sets are stored in
subdirectories of the installation directory:

```text
Program\Ableton Live <Version> <Edition>[.exe]
Resources\Core Library\Lessons\Demo Songs
```

Because the demo sets are a subdirectory of the installation, finding the
installations also finds the demo sets. The location is documented at [Location
of the default Demo
Set](https://help.ableton.com/hc/en-us/articles/209774005-Location-of-the-default-Demo-Set).

Four installations are present on the machine this was developed on:

* Live 8.4.2 Standard
* Live 9.7.7_64 Standard
* Live 10.1.43 Standard
* Live 11.3.43 Suite
* Live 12 Suite

### Windows and WSL Roles

The Ruby in this repository runs under WSL, on Ubuntu Linux. It cannot invoke
`dlopen("user32.dll")`, because a PE binary is not an ELF binary. But it *can*:

- launch Windows executables, through the WSL interop;
- read and write the Windows filesystem, at `/mnt/c`;
- reach the Windows process table, through `tasklist.exe` and `taskkill.exe`,
  which are in `System32` and are always present.

### Single-Instance Behavior

The command line that launches Ableton Live might have no parameters, or it
might contain the name of a Ableton Live Set to open. If so, this file will have
an `.als` filetype.

If Live is launched twice, the second instance forwards its command line to the
older running instance, then the second instance exits.

### Startup and Shutdown

This first version of a test harness shall close any pre-existing Live instance
before each run, and shut it down after the test completes.

### Live writes a log of what it does

This log can be used to get an approximate idea of what Live did.

```text
%APPDATA%\Ableton\Live <version>\Preferences\Log.txt
```

TODO: This is supposed to be a plain file, but I saw lots of fussing trying
to parse it. I suspect garbage code was written. Show me the code and discuss.
This plain file is readable from Ruby on WSL. The lines that matter are:

| Line | Meaning |
| --- | --- |
| `Loading document "<path>"` | which file Live opened |
| `Begin ExchangeDocument` | a load started |
| `End ExchangeDocument` | the load finished |
| `Exception: Fatal Error: Unhandled exception` | Live fell over |
| `Message Box: <text>` | Live put up a dialog, with its text |
| `Live App: GlobalExit( ): End or Exit: End` | Live quit normally |

Ableton's [Reading Ableton Live Crash
Reports](https://help.ableton.com/hc/en-us/articles/5301568366354-Reading-Ableton-Live-Crash-Reports)
describes the last one: *"When Live is quit normally (without crashing), the
last line of the run is logged as `Live App: GlobalExit( ): End or Exit: End`."*
A run that ends with hashmarks and no `Exit: End` is a crash. That gives the
harness a clean way to tell a normal exit from a crash, and it needs no
guessing.

### Crash Files Block The Next Launch

If a crash-recovery file is present in the Live Preferences folder, the next
Live launch will block with a user dialog.

Live's file recovery is triggered by an undo file in the Preferences folder. Per Ableton's
[Recovering a Set manually after a crash](https://help.ableton.com/hc/en-us/articles/115001878844-Recovering-a-Set-manually-after-a-crash):

> "Live's file recovery process is usually triggered by an undo file in Live's
> preferences folder. In case the process doesn't happen automatically, or if
> you clicked 'No' on the restore document dialog, the relevant files needed to
> recover the set are moved into a folder named 'Crash' located in Live's
> preferences folder."

So the recovery prompt is a consequence of the files being in `Preferences\`.
**Move them into `Crash\` and Live starts normally.** The documented manual
recovery procedure is the same thing in reverse: move them from `Crash\` back up
to `Preferences\`, and the prompt comes back.

The files are:

```text
Preferences\CrashRecoveryInfo.cfg
Preferences\BaseFiles\
Preferences\Undo\
```

`CrashRecoveryInfo.cfg` is a binary Ableton "RemoteableString", but the interesting parts are
UTF-16LE strings, and they name the set exactly:

```text
C:/ProgramData/Ableton/Live 11 Suite/Resources/Core Library/Lessons/Demo Songs/Ninajirachi - In The Rain (Live 11 Suite Demo).als
BaseFiles/Ninajirachi - In The Rain (Live 11 Suite Demo).als
```

That is the best evidence available of "which set Live was working on when it fell over" —
better than the log, which says only that Live crashed.

**The log records the recovery prompt, with its text:**

```text
info: Exception: The file "...\Preferences\CrashRecoveryInfo.cfg" cannot be copied.
info: Message Box: Live unexpectedly quit while you were working on the Live Set 'Untitled'. Would you like to recover your work?
```

That prompt is modal. It intercepts the launch, and Live opens `Untitled`
instead of the set that was asked for.  Moving the files aside is what fixes it.

### The crash dialog's text is not in the log

The log records *some* dialogs with their text, but not the crash message.
Grepping Live 11's log for `serious program error`, `shut down after` and
`Report a Crash` gives **zero hits**; the log has `Exception: Fatal Error:
Unhandled exception` and nothing more. The text on the screen is always the same
three lines for this class of failure, so it adds little:

> A serious program error has occurred.
> Live will shut down after this message box is closed.

The text is also hard to get at: Live is a Qt app, so `GetWindowText` on its
dialog returns nothing. UI Automation is the only technology guaranteed to be
available that can read crash dialog text.


### Exit Via Simulated Keypress

A keypress answers Live's recovery prompt, and the log says so.

The recovery prompt is a modal dialog with a **No** button, and pressing "n"
dismisses it. That was tried by hand on 2026-10-22, and Live's log records the
whole sequence:

```text
19:44:47  info: Default App: Checking whether to restore the document...
19:44:47  info: Message Box: Live unexpectedly quit while you were working on the Live Set 'Untitled'. Would you like to recover your work?
19:45:16  info: Default App: Restore Document: Rejected by the user
19:45:17  info: Loading document "...\DefaultLiveSet.als"
```

**"Restore Document: Rejected by the user"** is the confirmation that the
keypress landed. So the harness can dismiss the prompt, and know that it did,
without reading the dialog's text.

And Live tidies up after itself: answering the prompt moved the recovery files
into `Preferences\Crash\`, with a timestamp on each:

```text
Preferences/Crash/2026_10_22__19_44_43_BaseFiles/
Preferences/Crash/2026_10_22__19_44_43_CrashRecoveryInfo.cfg
Preferences/Crash/2026_10_22__19_44_43_Undo/
```

So **the harness does not have to move anything** — Live does it, and the
`Crash\` folder is the record of what happened.

The keypress is sent with `WScript.Shell.SendKeys`, which is in Windows itself
and needs nothing installed. The harness must make sure Live has the focus
first, with `AppActivate`.

### OSC cannot exit Live, and neither can anything else over the network

AbletonOSC exposes Live's whole Object Model, but its Application API is only:

| Address | What it does |
| --- | --- |
| `/live/test` | show a confirmation message |
| `/live/application/get/version` | Live's version |
| `/live/api/reload` | reload the OSC server code |
| `/live/api/get/log_level`, `/live/api/set/log_level` | logging |
| `/live/api/show_message` | show a message in the status bar |

There is no quit, no exit and no close, and no way to press a dialog's button.
The Song API has `stop_playing`, `undo` and `redo`, but nothing that ends the
application. **OSC cannot exit Live.**

### A Remote Script is possible, and is not needed

Live's Remote Script API is Python, and Live ships a Python 3 standard library
in `Resources/Python/lib/` — `socket.pyc` and `threading.pyc` among them — with
no `python.exe` in `Program\`, because the interpreter is embedded in Live's own
process. Live compiles a Remote Script's `.py` to `.pyc` itself, so a Remote
Script needs **nothing installed on Windows**.

It was the obvious way to answer a dialog from inside Live, and it can: the
Object Model's `open_dialog_count`, `current_dialog_message` and
`press_current_dialog_button` are exactly the right tools. But it is not needed,
because a keypress does the job, and a keypress has two advantages the script
does not:

- **A crash does not kill it.** The script runs inside Live's process, so it
  dies with it. The harness still has to report a crash from the log and the
  recovery file.
- **It needs no setup.** A Remote Script has to be **selected by a person** —
  Preferences → Link, Tempo & MIDI → Control Surface, with its MIDI input and
  output set to None — and until that is done it does not run at all.

### The conversion itself is not the problem

The round-tripped file was compared with the original Live 11 file, element by
element:

| | Live 11 original | Round tripped |
| --- | --- | --- |
| Element types | 1753 | 1829 |
| Live 12-only element types | — | **106** |
| Live 11-only element types | 29 | — |

A positional diff of the Live 12 source against the round-tripped file shows
**exactly 8 differences, all of them `MidiEditorLaneModel` → `ExpressionLane`**.
The conversion removes nothing, and renames only the lanes.

The 106 element types Live 12 added — `AdaptiveQAffectsShelves`,
`ArrangerMixerIO`, `AutomationEnvelopesListWrapper`, `BassShaperThreshold` and
so on — and the 29 it dropped, including `MasterTrack`, `SessionMixer` and
`WaveShaper`, were **already there when Live 12 saved the file**. Live 12 wrote
them; the conversion copied them through.

So the conversion cannot be blamed for the crash. And deleting the Live 12-only
elements is known to work: that was found by hand, and it is what the harness
should make into a test.

## How to read this plan

This document is split into two layers:

- **Research findings**: the evidence and conclusions about how Live behaves,
  where its logs and recovery files live, and which prompts must be handled.
- **Implementation actions**: the steps to code the harness, validate the log
  parser, and make the round-trip spec repeatable.

The research sections tell us what is true about Live; later sections tell us
what to build in Ruby to turn those findings into a test harness. Keeping this
boundary explicit makes it easier to trace a design decision back to the
observed behavior it depends on.

## The design

A program, in this repository, with a stable API. **Nothing to install.**

```text
spec/support/live_harness/
├── live_installations.rb   # where Live is, and where its log and preferences are
├── live_log.rb            # read the log: what was loaded, did it finish, did it crash
├── live_recovery.rb       # read the crash-recovery state
├── live_keys.rb           # send a keypress to Live
└── live_harness.rb        # the API the specs use
```

Plain Ruby, reading and writing `/mnt/c` directly, and running Windows programs
through the WSL interop. `WScript.Shell.SendKeys` is in Windows itself, so
sending a keypress needs nothing installed either.

There is no Windows helper, no Windows Ruby, and no Remote Script. See **Decisions**.

### The API the specs use

```ruby
harness = LiveHarness.new '11'
harness.open_set converted_path   # starts Live, opens the set, waits for it to settle
harness.loaded?                   # did Live finish loading it
harness.crashed?                  # did Live report a fatal error
harness.crashed_set               # which set Live was working on when it fell over
harness.close                     # close Live, and report how it closed
```

`open_set` returns one of four outcomes, so that a caller does not have to combine the
predicates to know what happened:

| Outcome | Meaning |
| --- | --- |
| `:loaded` | Live finished loading the set |
| `:crashed` | Live fell over; `crashed_set` says on which set |
| `:died` | Live went away without logging a crash |
| `:blocked` | Live is alive but stuck on a dialog; the harness answered it |

A dialog is not a failure. The harness answers the ones it knows how to answer, and says so
in the log, so a recovery prompt is handled rather than mistaken for a hang.

### What the harness does, in order

1. **Prepare a clean launch state**: close any existing Live instance, ensure the log is fresh,
   and clear or isolate recovery files so that the next run does not block on a stale prompt.
2. **Start from the official Live 11 demo set** located by the repository helper in
   `spec/demo_sets.rb` (`DemoSets.edition '11', 'Suite'` and related helpers), then save it in
   Live 12, creating the Live 12 source for the test.
3. **Convert that Live 12 source to the Live 11 format** with `live_set -11` and write the
   result to a known path.
4. **Probe the converted `.als` file as XML** before launching Live 11. This is the required
   structural gate: parse the file, assert the expected live set invariants, and stop with a
   clear failure if the file is malformed or missing required elements.
5. **Read back the converted file as XML** and compare the meaningful set content against the
   original Live 11 source: tracks, clips, group membership, lane values, version strings, and
   any required invariant fields.
6. **Start Live** with the set, using the WSL interop.
7. **Watch the log** until the run settles. There are four outcomes, and the harness must tell
   them apart:
   - `End ExchangeDocument` — the set loaded.
   - `Exception: Fatal Error` — Live crashed.
   - the process is gone, and the log's last line is not `Exit: End` — Live died.
   - `Checking whether to restore the document...` with no answer — Live is blocked on the
     recovery prompt. The harness sends "n", and waits for
     `Restore Document: Rejected by the user`. Live then moves the recovery files into
     `Crash\` by itself, and carries on.
8. **If it crashed, read `CrashRecoveryInfo.cfg`** and report which set it was working on.
9. **Close Live** gracefully, and confirm the log's last line is `Exit: End`.

### Closing Live

Killing Live is a bad idea, and not only because it is rude. A killed Live has not written its
preferences, has not closed its database, and leaves the crash-recovery state behind that
makes the *next* launch offer to recover.

The close sequence:

1. **`taskkill.exe` without `/F`.** This sends `WM_CLOSE` to Live's windows, which is what a
   person pressing the X does, and lets Live exit normally. Only `/F` kills it outright.
2. **Never `taskkill /F`.** Last resort, for a Live that will not respond, and the harness
   should say so when it does it.
3. **A "Save changes?" dialog is a real possibility**, because Live may consider the set
   dirty. The harness must not assume it will not appear. A keypress answers it — "n" for
   *No* — and Live logs `Restore Document: Rejected by the user` for the recovery prompt, so
   the harness can tell that the keypress landed. If the dialog turns out to need a different
   key, the harness says so rather than guessing silently.

### What does not need a Windows program

| Operation | How |
| --- | --- |
| Find Live | read `/mnt/c/ProgramData/Ableton` |
| Start Live with a set | WSL Ruby `exec`s the `.exe` — WSL interop |
| Find the Live process | `tasklist.exe` |
| Close Live | `taskkill.exe` without `/F` |
| Read the crash-recovery state | read the file under `/mnt/c` |
| Read the log | plain file read from `/mnt/c` |
| See and answer a dialog | `WScript.Shell.SendKeys`, with `AppActivate` first |

**Nothing needs a Windows program.** `WScript.Shell` is in Windows itself, and the
interpreter here is on the Windows side of the boundary already.

## Steps

1. **Write the log reader.** `live_log.rb`: given the log's path and a starting offset, report
   which file was loaded, whether the load finished, whether Live crashed, and whether it
   exited cleanly. Test it against captured log excerpts, so the parsing is right without
   starting Live. *Everything else depends on this.*

2. **Write the recovery-state reader.** `live_recovery.rb`: find the Preferences and `Crash`
   folders, and report which set a `CrashRecoveryInfo.cfg` refers to. It reads the file; it
   does not move it, because Live moves it itself once the prompt has been answered. Test it
   against a copy of a real Preferences folder.

3. **Write the keypress helper.** `live_keys.rb`: bring Live to the front with
   `AppActivate`, then send a key with `WScript.Shell.SendKeys`. It waits for the log to
   confirm the key landed, rather than sending and hoping.

4. **Write the harness.** `live_harness.rb`, using the two readers and the keypress helper. It
   starts Live, watches the log, answers the recovery prompt, reports the outcome, and closes
   Live.

5. **Write the XML sanity-check gate.** Before launching Live 11, read the converted `.als`
   file as XML and assert a small but explicit set of invariants: required top-level elements,
   version strings, lane names, removed Live 12-only nodes, and the expected set of track and
   clip counts. This is the step currently represented by the checks in
   `spec/live_set/live_set_modify_als_spec.rb`, and it should be made an explicit part of the
   plan rather than a loose collection of examples.

6. **Write the round-trip spec that exercises the full sequence.**
   `spec/integration/live_set_round_trip_spec.rb` should take a real Live 11 set, save it in
   Live 12, convert it back with `live_set -11`, run the XML sanity checks, and then launch Live
   11 with the converted file. It should assert the meaningful data still reads back correctly
   and that Live 11 accepts the file without a fatal crash. It is opt-in, because Live takes
   about half a minute to start and load a set, and the rest of the suite must stay quick:
   skipped unless `LIVE_SET_ROUND_TRIP` is set.

7. **Then, and only then, fix the conversion.** With the harness working, the loop is:
   Live 11 source → Live 12 save → `live_set -11` → XML sanity check → Live 11 open → log
   inspection → data read-back verification → adjust the conversion → repeat. The evidence says
   the answer is to remove the Live 12-only elements or otherwise reconcile the incompatible lane
   data, as has already been found by hand; the harness turns that into a test and lets the list
   be derived rather than guessed.

## Verification

1. `bundle exec rspec` — the whole suite still passes, with the round-trip spec skipped.
2. `bundle exec rspec spec/support/` — the harness's own specs, which do not need Live.
3. `LIVE_SET_ROUND_TRIP=1 bundle exec rspec spec/integration/live_set_round_trip_spec.rb` —
   the real thing, against a real Live 11, and it must be **repeatable**: run it twice, and
   it must give the same answer both times.
4. The round-trip spec must be shown to **fail** on a set that is known to crash Live, before
   it is trusted to pass on one that does not.
5. The harness must leave Live **not running**, its log ending in `Exit: End`, and its
   recovery state **moved aside** — so a second run behaves exactly like the first.

## Decisions

- The harness lives in `spec/support/`, not `lib/`. It is test infrastructure, and the gem
  should not grow a dependency on GUI automation.
- **No Windows helper, and no Remote Script.** Everything the harness needs is reachable
  without either:
  - Reading the log and reading the crash-recovery state are plain file operations under
    `/mnt/c`.
  - Launching and closing Live are `exec` and `taskkill.exe`, both through the WSL interop.
  - Answering a dialog is a keypress, sent with `WScript.Shell.SendKeys` — which is in Windows
    itself, and confirmed by the log line `Restore Document: Rejected by the user`.
- **Not OSC.** AbletonOSC exposes Live's whole Object Model, but it has no way to exit Live and
  no way to press a dialog's button. It is the wrong tool for closing Live.
- **Not the Object Model's dialog API.** `open_dialog_count`, `current_dialog_message` and
  `press_current_dialog_button` would work, but they need a Remote Script, which has to be
  enabled by hand and dies with a crash. A keypress needs neither.
- Ruby on Windows was rejected on evidence, not preference: RAutomation (the standard Ruby
  GUI-automation library, 879k downloads) is a Windows-platform gem, and its default adapter
  is FFI to `user32` — the API that returns *nothing* for Live's Qt-drawn dialogs, verified.
  Its UI Automation adapter is 32-bit only. So it would have been a large install to read one
  string that is not needed.
- No new gem dependencies in the `live_set` gemspec, and none in the WSL Ruby.
- The harness is a program with a stable API, not a script.
- **Live is closed gracefully, never killed.**
- The harness takes a Live *version* and finds the installation, rather than being Live 11
  shaped. The round trip eventually needs Live 12 to write the source file.

## Scope

**In:** finding Live, launching it with a set, reading the log, reading the crash-recovery
state, answering Live's dialogs with a keypress, closing Live gracefully, and the round-trip
spec that uses all of it.

**Out:** a general-purpose Ableton control API. OSC, the MCP integration, the Live Object
Model, and reading dialogs off the screen with UI Automation are all out of scope; this
harness asks one question — did Live open this set, and what did it say if it did not.

## Open questions

1. **Which key answers the "Save changes?" prompt?** "n" answered the recovery prompt. The
   save prompt may want a different key, or an accelerator. Worth one run to find out.
2. **Does Live write `CrashRecoveryInfo.cfg` on a clean exit?** If it does, the harness must
   clear it every time, not just after a crash.
3. **Does the keypress need Live to have the focus?** `AppActivate` on the process should do
   it, but a dialog that is not the active window may ignore the key. Worth checking.
4. **Does the crash dialog take a keypress too?** The crash dialog has an OK button, and
   pressing Enter or Space would dismiss it. The crash is already reported from the log, so
   this only affects how much the harness can say about it.
