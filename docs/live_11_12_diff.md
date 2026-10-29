# The Differences Between the Live 11 and the Live 12 Formats

The version_diff document for Live 11 and Live 12. The transformations it describes are
the lists of `lib/live_set/tx/live_11_and_12.rb`, and the headings below are
what the code cites.

The format itself — the elements, the attributes, and the shapes they take — is
in [als_notes.md](als_notes.md). The release notes of Live 12 are in
[release_notes/](release_notes/), and what they say is summarized below. The
terms used here are defined in [glossary.md](glossary.md).

## The Live 12 release notes

The release notes of Live 12 are written for the musicians who use Live. They
describe the features in the words a musician would use, and they never give an
element name, an attribute name, or any part of the file format. So they are a
filter over the differences rather than a source of them: they say which
differences to expect, and the names themselves have to come from the XML
stored in the sets.

An item is a candidate for a difference when it adds something the format has
to record — a device, a kind of track, a kind of clip, a new element in a
dialogue. An item that changes the interface without changing what a set
holds is not.

### 12.0

The first release of Live 12. The items that add something a set records:

- **Meld**, a new instrument.
- **Roar**, a new audio effect.
- **CC Control**, a new utility device.
- **Pitch and Time Utilities**, a new panel in the Clip View, in place of the
  Notes tab.
- **MIDI Tools**, a new set of transformations and generators, with their
  parameters saved in the set.
- **MIDI Note Probability Groups**, where a chance value belongs to a group of
  notes rather than to one note.
- **Scale Awareness**, a scale that a clip can hold, and that devices can
  follow.
- **Tuning Systems**, a tuning a set can hold.
- **Editor View Modes**, which replace the tabs of the Clip View.
- **The Sampler's round robin**, and **the Shaper's play modes**.
- **Expression Control**, in a new implementation, with the old one renamed
  Expression Control Legacy. A set written by Live 11 that holds Expression
  Control loads the legacy version.
- **The Main Track**, which is the Master Track renamed. The routing target
  `Main` is the Master renamed.
- **The mixers of the Arrangement View and the Session View**, which are one
  element in Live 11 and several in Live 12.

### 12.1

- **Drum Sampler**, a new instrument.
- **Auto Shift**, and updated **Limiter** and **Saturator** devices.
- **Scale Awareness for Audio Clips**, and updated **Echo** and **Meld**.

### 12.2

- **The Auto Filter**, with new filter types and updated filter circuits.
- **Resonators** and the **Spectral Resonator**, in **Meld** and **Roar**.
- **Bounce Tracks to Audio**, which is an operation on a set rather than a
  construct in it.

### 12.3

- **Stem Separation**, which splits a set into stems.
- **Splice Integration**.
- **Bounce Group Tracks**, and **Device A/B Comparison**.

### 12.4

- **Erosion**, a new audio effect.
- **Chorus-Ensemble**, a new audio effect.
- **Delay**, a new device, distinct from the one Live 11 has.
- **Link Audio**, and **Separate Stems for Time Selection**.

### 12.4 and later, and the minor releases that follow

The later releases add devices and revise them, and the notes of each are in
`release_notes/live-12.html`.

## The differences

### The elements the two versions name differently

A rename is symmetric: it matches either spelling and emits the other, so
one list serves both directions.

| Live 11 | Live 12 |
| --- | --- |
| `MasterTrack` | `MainTrack` |
| `AutoColorPickerForReturnAndMasterTracks` | `AutoColorPickerForReturnAndMainTracks` |
| `IsSongTempoMaster` | `IsSongTempoLeader` |
| `ReWireSlaveMidiTargetId` | `ReWireDeviceMidiTargetId` |
| `ViewStateSesstionTrackWidth` | `ViewStateSessionTrackWidth` |
| `ViewStateSessionMixerHeight` | `ViewStateSessionMixerVolumeSectionHeight` |
| `ExpressionLane` | `MidiEditorLaneModel` |
| `ScaleInformation/RootNote` | `ScaleInformation/Root` |
| `MxDPatchRef` | `MxPatchRef` |

The Live 11 spelling of the mixer width has a typo in it, and the typo is part
of the format.

### The values the two versions write differently

Two values are translated rather than removed, because the two versions write
them differently.

| Element | Live 11 | Live 12 |
| --- | --- | --- |
| `Target/@Value` | `AudioOut/Master` | `AudioOut/Main` |
| `Saturator/Oversampling/@Value` | `1` or `0` | `true` or `false` |

The `Target` is the output a track or a device routes to. A `Pedal`'s
`Oversampling` is `true` or `false` in both versions, so only the
`Saturator`'s is rewritten.

### The elements Live 12 adds

Live 12 writes elements the Live 11 format does not have. They are added at
four levels: the set itself, a track, a clip, and a device. Their values are
the defaults Live gives them, and their positions follow the order of the
Live 12 schema.

The names are in the `ADD` list of `lib/live_set/tx/live_11_and_12.rb`. Three
of the additions are not elements but splits: the mixer of the arrangement view
and the mixer of the session view are each one element in Live 11 and several
in Live 12.

### The element Live 12 puts at another depth

`SongMasterValues/SessionScrollerPos` and `LiveSet/SessionScrollPos` are not a
rename. Live 12 keeps the scroll position where Live 11 keeps it in a wrapper,
and Live 11's `SongMasterValues` holds nothing else — the schema says its only
child is `SessionScrollerPos`. So the wrapper is built on the way down and
unwrapped on the way up.

### The lane types

A lane is identified by the container it is in and its `Type` value, and the
set of lanes is the same in every set of a given Live version:

| Live version | `ContentLanes` types | `ExpressionLanes` types |
| --- | --- | --- |
| 11 | 4, 5 | 0, 1, 2, 3 |
| 12 | 2, 3, 4 | 0, 1, 2, 3, 5 |

The two families use the same numbers for different things: `Type` 2 in
`ContentLanes` is not `Type` 2 in `ExpressionLanes`. There is no mapping
between the two versions' lane numbering, because the numbering is per family
and per version.

### The lane types Live 11 does not have

Converting a Live 12 set to Live 11 produces lanes of `Type` 2 and 3 in
`ContentLanes` and `Type` 5 in `ExpressionLanes`, none of which Live 11 has
ever had.

What to do with a lane the target version does not have — drop it, map it to
another one, leave it alone, or refuse to convert — is an open question,
tracked as **TODO N42**.

## The conversion

### Converting a set to Live 11 uses a fixed schema

`live_set -11` writes a set in the Live 11 format, and the version strings it
writes are fixed, so that the set can be recognized as the result of a
conversion by `live_set` instead of a set saved by Ableton Live:

```xml
<Ableton MajorVersion="5"
         MinorVersion="11.0_11300"
         SchemaChangeCount="3"
         Creator="Ableton Live 11.3.21"
         Revision="5ac24cad7c51ea0671d49e6b4885371f15b57c1e" />
```

`MajorVersion` with value `5` indicates that the file contains a Live 11 set.

`MinorVersion` is `11.0_11300` while `Creator` says `11.3.21`. The two are
different numbering schemes: `Creator` is the version of Live that wrote the
set, and `MinorVersion` identifies the set format that the specified version
of Live 11 reads.

The `Revision` is a fixed value rather than one Live allocates, because Live
rewrites the revision every time it saves a set, and a converted set was never
saved by Live at all.

### The down direction is settled

The down direction (Live 12 → Live 11) is implemented in the lists of
`Live11And12`. It was checked node for node against the stylesheet it
replaced, on the Live 12 demo set, and the two produce the same document.

The down direction is lossy: constructs the Live 11 format cannot represent
are dropped, and they cannot be recovered. The up direction is not the inverse
of it.

### What the up direction does not do yet

The up direction does not yet reproduce the device-level part of Live's own
conversion. Three things stand in the way, and each needs the Live 12 schema
and a list of defaults:

1. **Devices whose parameters were restructured.** Live 11's `WaveShaper` has
   the parameters `Curve`, `Damp`, `Depth`, `Lin` and `Period`; Live 12's has
   `WsCurve`, `WsDamp`, `WsDepth`, `WsDrive`, `WsLin` and `WsPeriod`. Live
   11's `Compressor2` has a `SideChainEq` element; Live 12's has
   `SideChainEq_On`, `SideChainEq_Mode`, `SideChainEq_Freq`, `SideChainEq_Q`
   and `SideChainEq_Gain`. Live 12's `Delay` has `Modulation_Time`,
   `Modulation_Morph` and the rest; Live 11's does not. Live 12's `Limiter` has
   `Maximize`, `MaximizeOutput`, `MaximizeThreshold`, `LinkAmount` and
   `LinkAmountMidSide`; Live 11's does not.

2. **Parameters Live 12 adds to devices that keep their name.** Live 12's
   `Saturator` has `BassShaperThreshold`, Live 12's `Transmutex3` has
   `Global_UseScale` and `PartialFrequencies_QuantizeToScaleOrTuning`, and
   Live 12's `SignalChain2` has `FilterControllee`. The value of each is the
   default of the device.

3. **Identifiers Live allocates.** Some of the added parameters carry an
   `AutomationTarget` with an `Id` that Live allocates when it saves the set.
   The identifier has to be unique within the set, and Live's own choice of it
   cannot be reproduced.

The down direction is unaffected by all of this: it copies the device through
unchanged, and the Live 11 schema accepts it.

### The comparison of two sets

`docs/cpfir.md`, "Comparing Two Live Sets", compares two sets by bringing both to the same version.
Until the device-level part of the up direction is done, that comparison has to
allow for the differences listed above, or it has to compare sets that hold
the same devices.
