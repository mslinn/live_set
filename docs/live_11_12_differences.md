# The Differences Between the Live 11 and the Live 12 Formats

The evidence behind the rules in `lib/live_set/tx/live_11_and_12.rb`.

Two sets were compared: the Live 11 Suite demo song, and the same song after Live 12 had opened
it and saved it. The second file is what Live's own conversion produces, so it is the standard the
up direction is measured against.

## The down direction is settled

The down direction (Live 12 → Live 11) is implemented in `lib/live_set/tx/live_12_to_live_11.xsl`
and is now expressed as the tables of `Live11And12`. It was checked node for node against the
stylesheet on the Live 12 demo set, and the two produce the same document.

The down direction is lossy: constructs the Live 11 format cannot represent are dropped, and
they cannot be recovered. The up direction is not the inverse of it.

## The up direction, Live 11 → Live 12

### Renames

These are symmetric: the rule matches either spelling and emits the other.

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
| `SongMasterValues/SessionScrollerPos` | `LiveSet/SessionScrollPos` |

The Live 11 spelling of the mixer width has a typo in it, and the typo is part of the format.

### Elements Live 12 adds

Live 12 writes elements the Live 11 format does not have. Their values are the defaults Live
gives them, and their positions follow the order of the Live 12 schema.

| Where | What Live 12 adds |
| --- | --- |
| `LiveSet` | `SelectedBreakpointValue`, `SelectedDocumentViewInMainWindow`, `ShouldSceneTempoAndTimeSignatureBeVisible`, `IsWaveformVerticalZoomActive`, `NoteAlgorithms`, `NoteSpellingPreference` |
| `LiveSet/ViewStates` | `MixerInArrangement`, `MixerInSession`, and the split of `ArrangerMixer` and `SessionMixer` into `ArrangerMixerIO`, `ArrangerMixerSends`, `ArrangerMixerReturns`, `ArrangerMixerVolume`, `ArrangerMixerTrackOptions`, `ArrangerMixerCrossFade`, `ArrangerMixerTrackPerformanceImpactMeter`, `SessionVolume`, `SessionTrackOptions`, `SessionTrackPerformanceImpactMeter` |
| `LiveSet/GroovePool` | `DefaultGrooveId`, `GroovesListWrapper` |
| every track | `ArrangementClipsListWrapper`, `TakeLanesListWrapper`, `IsTuned`, `ControllerLayoutRemoteable`, `ControllerLayoutCustomization` |
| `TakeLane` | `LomId`, `ArrangementClipsListWrapper` |
| `MidiClip`, `AudioClip` | `AutomationEnvelopesListWrapper`; `ScaleInformation` and `IsInKey` on an audio clip |
| `MidiClip/Notes` | `NoteProbabilityGroups`, `ProbabilityGroupIdGenerator` |
| `AudioSequencer` | the clip slots of the main sequencer |
| every device | `BreakoutIsExpanded`, `MpePitchBendUsesTuning`, `SamplesToAutoWarp` |
| `FileRef` | `SourceHint` |
| `SourceContext` | `LocalFiltersJson` |

### What is not yet done

The up direction does not yet reproduce the device-level part of Live's own conversion. Three
things stand in the way, and each needs the Live 12 schema and a table of defaults:

1. **Devices whose parameters were restructured.** Live 11's `WaveShaper` has the parameters
   `Curve`, `Damp`, `Depth`, `Lin` and `Period`; Live 12's has `WsCurve`, `WsDamp`, `WsDepth`,
   `WsDrive`, `WsLin` and `WsPeriod`. Live 11's `Compressor2` has a `SideChainEq` element; Live
   12's has `SideChainEq_On`, `SideChainEq_Mode`, `SideChainEq_Freq`, `SideChainEq_Q` and
   `SideChainEq_Gain`. Live 12's `Delay` has `Modulation_Time`, `Modulation_Morph` and the rest;
   Live 11's does not. Live 12's `Limiter` has `Maximize`, `MaximizeOutput`, `MaximizeThreshold`,
   `LinkAmount` and `LinkAmountMidSide`; Live 11's does not.

2. **Parameters Live 12 adds to devices that keep their name.** Live 12's `Saturator` has
   `BassShaperThreshold`, Live 12's `Transmutex3` has `Global_UseScale` and
   `PartialFrequencies_QuantizeToScaleOrTuning`, and Live 12's `SignalChain2` has
   `FilterControllee`. The value of each is the default of the device.

3. **Identifiers Live allocates.** Some of the added parameters carry an `AutomationTarget` with
   an `Id` that Live allocates when it saves the set. The identifier has to be unique within the
   set, and Live's own choice of it cannot be reproduced.

The down direction is unaffected by all of this: it copies the device through unchanged, and the
Live 11 schema accepts it.

### The comparison

`docs/cpfir.md` §5 compares two sets by bringing both to the same version. Until the device-level
part of the up direction is done, that comparison has to allow for the differences listed above,
or it has to compare sets that hold the same devices.
