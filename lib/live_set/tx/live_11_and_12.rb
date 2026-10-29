require_relative 'live_version_converter'

# The differences between the Live 11 format and the Live 12 format.
#
# This class is the bridge between Live 11 and Live 12. It inherits the machinery of the base
# class and nothing else: a bridge never inherits from another bridge, and a conversion across
# several versions is the composition of the bridges between them.
#
# How the down direction works
#
# The direction is not given to the bridge. The bridge reads the version of the document it is
# handed and converts it to the other version of its version_diff, so one set of transformations
# carries both directions of the version_diff: a rename matches either spelling and emits the
# other.
#
# The lists hold the transformations, and each of them is declared by calling the method of the
# base class that owns it:
#
#   remove, remove_under         the elements the older version does not have
#   rename, rename_under         the elements the two versions name differently
#   empty                        the elements the older version keeps empty
#   remove_attribute             the attributes the older version does not have
#   default_attribute            the attributes the older version always writes
#   add, add_attribute           what the newer version adds
#   child_order                  where the children of an element go
#
# The base class owns the lists and this class declares what each of them holds. Every list is
# declared, even the ones that are empty, and a declaration adds to what the list already holds.
#
# The transformations that a list cannot express are in #special_transformations. Each of them
# is a case a list cannot express: a value that the two versions write differently, an element
# that one version wraps and the other keeps bare, an element that has to move to another parent.
#
# Where the names come from
#
# The schema of a version is an index of the format: it lists every element and every attribute
# of that version, so diffing the schema of Live 12 against the schema of Live 11 gives the
# candidates — the names one version has and the other does not.
#
# The diff gives the candidates; it does not decide them. Every name in the lists below was
# decided by hand, and some of them have been decided wrongly so far. The Live 11 schema is an
# inference from the XML stored in the sets of Live 11, so a device that Live 11 has, but that no
# Live 11 demo set happens to contain, is absent from the Live 11 schema, and a diff against that
# schema says to remove a device Live 11 understands.
#
# The release notes of Live 12 are written for the musicians who use Live. They describe the
# features in the words a musician would use — "the Master Track was renamed to the Main
# Track" — and they never give an element name, an attribute name, or any part of the file
# format. So they are a filter over the differences rather than a source of them: they say
# which differences to expect, and which version introduced each one, and the names
# themselves have to come from the XML stored in the sets.
#
# The release notes tell you what Ableton changed between two versions of Live. The XML stored in
# the sets of those two versions can be inspected to reveal the structure of each one, and
# comparing the two structures reveals the changes between the Live versions that produced those
# files. The release notes of Live 12 are in docs/release_notes/; the differences between the two
# versions are summarized in docs/live_11_12_diff.md.
#
# The kinds of difference, and the operation each kind calls for, are in docs/conversion.md, "The
# kinds of difference". A transform takes its direction from the document it is given: see
# docs/cpfir.md, "The Lifecycle of a Conversion".
#
# The terms used here are defined in docs/glossary.md.
class Live11And12 < LiveVersionConverter
  # The version strings of each direction.
  #
  # Live rewrites the revision every time it saves a set, so the value here describes the file
  # rather than the set, and it is left out of any comparison of two sets. See docs/cpfir.md,
  # "Comparing Two Live Sets".
  version(
    down: { # sorted alphabetically by key
      'Creator'           => 'Ableton Live 11.3.21',
      'MajorVersion'      => '5',
      'MinorVersion'      => '11.0_11300',
      'Revision'          => '5ac24cad7c51ea0671d49e6b4885371f15b57c1e',
      'SchemaChangeCount' => '3',
    },
    up:   {
      'Creator'           => 'Ableton Live 12.4.6',
      'MajorVersion'      => '5',
      'MinorVersion'      => '12.0_12402',
      'Revision'          => '0de5c8fa9a692293676cb7700a15afb2046ee1f7',
      'SchemaChangeCount' => '5',
    }
  )

  # The elements the older version does not have, wherever they appear.
  #
  # The list is read in the direction the set is going, because the two directions do not
  # remove the same elements. Going down, the elements Live 12 has and Live 11 does not are
  # removed. Going up, the elements Live 11 has and Live 12 does not are removed. Neither
  # removal touches the elements the other version has, because they are named in the list of
  # the other direction only.
  remove(
    # sorted alphabetically
    down: %w[
      ArrangementClipsListWrapper
      AudioInputsListWrapper
      AudioOutputsListWrapper
      AutomationEnvelopesListWrapper
      BreakoutIsExpanded
      ComplexProEnvelopeModulationTarget
      ComplexProFormantsModulationTarget
      ControllerLayoutCustomization
      ControllerLayoutRemoteable
      DefaultGrooveId
      InstrumentMeld
      IsTuned
      IsUndoable
      IsWaveformVerticalZoomActive
      KeepRecordMonitoringLatency
      LocalFiltersJson
      MidiInputsListWrapper
      MidiOutputsListWrapper
      MpePitchBendUsesTuning
      MpeTuningEnabled
      MxDIntParameter
      NoteAlgorithms
      NoteProbabilityGroups
      ProbabilityGroupIdGenerator
      Roar
      SamplesToAutoWarp
      SelectedBreakpointValue
      SelectedDocumentViewInMainWindow
      ShouldSceneTempoAndTimeSignatureBeVisible
      SourceHint
      TakeLanesListWrapper
      TransientEnvelopeModulationTarget
      TuningSystems
      ViewStateMainWindowClipDetailOpen
      ViewStateMainWindowDeviceDetailOpen
      ViewStateMainWindowHiddenOtherDocViewTypeClipDetailOpen
      ViewStateMainWindowHiddenOtherDocViewTypeDeviceDetailOpen
      ViewStateSecondWindowClipDetailOpen
      ViewStateSecondWindowDeviceDetailOpen
      WaveformVerticalZoomFactor
    ],
    up:   []
  )

  # The elements the older version does not have, under a named parent.
  #
  # Live 12 puts some elements inside a parent that Live 11 does not. Live 12 puts
  # <MidiControllerRange> inside <CrossFadeState>, and Live 11 puts it inside device parameters.
  # Removing such an element by name alone would also remove it from the places Live 11 needs it,
  # so these entries name the parent the element has to be removed from.
  #
  # Going up, the elements Live 11 has and Live 12 does not are removed the same way. Live 11
  # writes the height of the session mixer as <ViewStateSessionMixerHeight>, and Live 12 writes
  # it as <ViewStateSessionMixerVolumeSectionHeight>; the element is renamed, not removed. The
  # four elements of the view states that Live 12 replaced with a different set of elements are
  # removed, and the three that Live 12 dropped outright are removed.
  remove_under(
    # sorted alphabetically
    down: %w[
      AudioClip/IsInKey
      AudioClip/ScaleInformation
      CrossFadeState/MidiControllerRange
      GroovePool/GroovesListWrapper
      LiveSet/NoteSpellingPreference
      LiveSet/ViewStateArrangerMixerVolumeSectionHeight
      MidiClip/AccidentalSpellingPreference
      TimeSignature/MidiControllerRange
    ],
    up:   %w[
      LiveSet/ViewStateArrangerHasDetail
      LiveSet/ViewStateDetailIsSample
      LiveSet/ViewStateSessionHasDetail
      ViewStates/ArrangerMixer
      ViewStates/ArrangerTrackDelay
      ViewStates/SessionMixer
      ViewStates/SessionTrackDelay
    ]
  )

  # The elements the two versions spell differently.
  #
  # The base class reads this list in both directions, so the name of the element is enough.
  rename( # sorted alphabetically by key
    'AutoColorPickerForReturnAndMainTracks' => 'AutoColorPickerForReturnAndMasterTracks',
    'IsSongTempoLeader'                     => 'IsSongTempoMaster',
    'MainTrack'                             => 'MasterTrack',
    'ReWireDeviceMidiTargetId'              => 'ReWireSlaveMidiTargetId',
    'ViewStateSessionTrackWidth'            => 'ViewStateSesstionTrackWidth'
  )

  # The elements the two versions spell differently, under a named parent.
  #
  # The parent holds the element under a different name in each version, so the path of a rename is
  # the path of the element in the version the set is coming from, and the list holds one path
  # for each direction.
  rename_under(
    down: { # sorted alphabetically by key
      'ContentLanes/MidiEditorLaneModel'                 => 'ExpressionLane',
      'ExpressionLanes/MidiEditorLaneModel'              => 'ExpressionLane',
      'LiveSet/ViewStateSessionMixerVolumeSectionHeight' => 'ViewStateSessionMixerHeight',
      'PatchSlot/Value/MxPatchRef'                       => 'MxDPatchRef',
      'ScaleInformation/Root'                            => 'RootNote',
    },
    up:   {
      'ContentLanes/ExpressionLane'         => 'MidiEditorLaneModel',
      'ExpressionLanes/ExpressionLane'      => 'MidiEditorLaneModel',
      'LiveSet/ViewStateSessionMixerHeight' => 'ViewStateSessionMixerVolumeSectionHeight',
      'PatchSlot/Value/MxDPatchRef'         => 'MxPatchRef',
      'ScaleInformation/RootNote'           => 'Root',
    }
  )

  # The elements that are empty in Live 11.
  #
  # Live 12 has content in them that Live 11 cannot represent, so the conversion drops it. The
  # other way, a Live 11 set has them empty already, so there is nothing to restore.
  empty(
    down: [ # sorted alphabetically
      'AudioSequencer/ClipSlotList',
      'MidiTrack/TakeLanes/TakeLanes',
      'Mixer/Sends',
      'SendsPre',
      'TimeAndValueTransforms'
    ],
    up:   []
  )

  # The attributes Live 11 does not have.
  #
  # They record which panel of the device chain is selected, and are not part of the sound of the
  # set.
  # sorted alphabetically
  remove_attribute %w[
    SelectedGeneratorName
    SelectedToolPanel
    SelectedTransformationName
  ]

  # The attributes Live 11 always writes, and the value it writes.
  #
  # Live 12 keeps the probability of a note in the probability groups of the clip, and Live 11
  # keeps it on the note itself. A note that Live 12 does not put in a group always plays.
  #
  # Live 11 writes the four curve control attributes of every note event, and Live 12 writes them
  # only when the curve is not the default.
  #
  # The attributes are written in the order Live writes them in, so this list is in that order
  # and not in alphabetical order, even though the keys could be sorted.
  default_attribute( # sorted alphabetically by key
    'MidiNoteEvent' => {
      'VelocityDeviation' => '0',
      'Probability'       => '1',
      'IsEnabled'         => 'true',
    },
    'PerNoteEvent'  => {
      'CurveControl1X' => '0.5',
      'CurveControl1Y' => '0.5',
      'CurveControl2X' => '0.5',
      'CurveControl2Y' => '0.5',
    }
  )

  # The order Live 12 writes the children of an element in.
  #
  # where the elements that moved between the versions are moved to. Live 11 writes the scale of a MIDI clip at the end
  # of the clip, and Live 12 writes it near the beginning; the order says so.
  #
  # The spec spec/live_set/tx/live_up_ground_truth_spec.rb checks the list against the set Live itself wrote, so the
  # list is known to be right rather than believed to be.
  child_order(
    down: {},
    up:   {
      'LiveSet'                                    => %w[
        NextPointeeId
        OverwriteProtectionNumber
        LomId
        LomIdView
        Tracks
        MainTrack
        PreHearTrack
        SendsPre
        Scenes
        Transport
        SessionScrollPos
        SelectedBreakpointValue
        SignalModulations
        GlobalQuantisation
        AutoQuantisation
        Grid
        ScaleInformation
        InKey
        SmpteFormat
        TimeSelection
        SequencerNavigator
        IsContentSplitterOpen
        IsExpressionSplitterOpen
        ExpressionLanes
        ContentLanes
        ViewStateFxSlotCount
        ViewStateSessionMixerVolumeSectionHeight
        ViewStateArrangerMixerVolumeSectionHeight
        ShouldSceneTempoAndTimeSignatureBeVisible
        WaveformVerticalZoomFactor
        IsWaveformVerticalZoomActive
        Locators
        DetailClipKeyMidis
        TracksListWrapper
        VisibleTracksListWrapper
        ReturnTracksListWrapper
        ScenesListWrapper
        CuePointsListWrapper
        SelectedDocumentViewInMainWindow
        Annotation
        SoloOrPflSavedValue
        SoloInPlace
        CrossfadeCurve
        LatencyCompensation
        HighlightedTrackIndex
        GroovePool
        AutomationMode
        SnapAutomationToGrid
        ArrangementOverdub
        ColorSequenceIndex
        AutoColorPickerForPlayerAndGroupTracks
        AutoColorPickerForReturnAndMainTracks
        ViewData
        ResetNonautomatedMidiControllersOnClipStarts
        MidiFoldIn
        MidiFoldMode
        MultiClipFocusMode
        MultiClipLoopBarHeight
        MidiPrelisten
        LinkedTrackGroups
        NoteSpellingPreference
        AccidentalSpellingPreference
        PreferFlatRootNote
        UseWarperLegacyHiQMode
        VideoWindowRect
        ShowVideoWindow
        TuningSystems
        TrackHeaderWidth
        ViewStateMainWindowClipDetailOpen
        ViewStateMainWindowHiddenOtherDocViewTypeClipDetailOpen
        ViewStateMainWindowHiddenOtherDocViewTypeDeviceDetailOpen
        ViewStateMainWindowDeviceDetailOpen
        ViewStateSecondWindowClipDetailOpen
        ViewStateSecondWindowDeviceDetailOpen
        ViewStates
        NoteAlgorithms
      ],
      'LiveSet/ViewStates'                         => %w[
        MixerInArrangement ArrangerMixerIO ArrangerMixerSends ArrangerMixerReturns
        ArrangerMixerVolume ArrangerMixerTrackOptions ArrangerMixerCrossFade
        ArrangerMixerTrackPerformanceImpactMeter MixerInSession SessionIO SessionSends
        SessionReturns SessionVolume SessionTrackOptions SessionCrossFade
        SessionTrackPerformanceImpactMeter SessionShowOverView ArrangerIO ArrangerReturns
        ArrangerVolume ArrangerTrackOptions ArrangerShowOverView
      ],
      'LiveSet/GroovePool'                         => %w[LomId Grooves DefaultGrooveId GroovesListWrapper],
      'MidiTrack'                                  => %w[
        LomId LomIdView IsContentSelectedInDocument PreferredContentViewMode TrackDelay Name Color
        AutomationEnvelopes TrackGroupId TrackUnfolded DevicesListWrapper ClipSlotsListWrapper
        ArrangementClipsListWrapper TakeLanesListWrapper ViewData TakeLanes LinkedTrackGroupId
        SavedPlayingSlot SavedPlayingOffset Freeze PostProcessFreezeClips DeviceChain
        ReWireDeviceMidiTargetId PitchbendRange IsTuned ControllerLayoutRemoteable
        ControllerLayoutCustomization
      ],
      'GroupTrack'                                 => %w[
        LomId LomIdView IsContentSelectedInDocument PreferredContentViewMode TrackDelay Name Color
        AutomationEnvelopes TrackGroupId TrackUnfolded DevicesListWrapper ClipSlotsListWrapper
        ArrangementClipsListWrapper TakeLanesListWrapper ViewData TakeLanes LinkedTrackGroupId
        Slots Freeze DeviceChain
      ],
      'AudioTrack'                                 => %w[
        LomId LomIdView IsContentSelectedInDocument PreferredContentViewMode TrackDelay Name Color
        AutomationEnvelopes TrackGroupId TrackUnfolded DevicesListWrapper ClipSlotsListWrapper
        ArrangementClipsListWrapper TakeLanesListWrapper ViewData TakeLanes LinkedTrackGroupId
        SavedPlayingSlot SavedPlayingOffset Freeze PostProcessFreezeClips DeviceChain IsTuned
      ],
      'MainTrack'                                  => %w[
        LomId LomIdView IsContentSelectedInDocument PreferredContentViewMode TrackDelay Name Color
        AutomationEnvelopes TrackGroupId TrackUnfolded DevicesListWrapper ClipSlotsListWrapper
        ArrangementClipsListWrapper TakeLanesListWrapper ViewData TakeLanes LinkedTrackGroupId
        DeviceChain
      ],
      'ReturnTrack'                                => %w[
        LomId LomIdView IsContentSelectedInDocument PreferredContentViewMode TrackDelay Name Color
        AutomationEnvelopes TrackGroupId TrackUnfolded DevicesListWrapper ClipSlotsListWrapper
        ArrangementClipsListWrapper TakeLanesListWrapper ViewData TakeLanes LinkedTrackGroupId
        DeviceChain
      ],
      'PreHearTrack'                               => %w[
        LomId LomIdView IsContentSelectedInDocument PreferredContentViewMode TrackDelay Name Color
        AutomationEnvelopes TrackGroupId TrackUnfolded DevicesListWrapper ClipSlotsListWrapper
        ArrangementClipsListWrapper TakeLanesListWrapper ViewData TakeLanes LinkedTrackGroupId
        DeviceChain
      ],
      'TakeLane'                                   => %w[
        LomId Height IsContentSelectedInDocument ClipAutomation Name Annotation Audition
        ArrangementClipsListWrapper
      ],
      'MidiClip'                                   => %w[
        LomId LomIdView CurrentStart CurrentEnd Loop Name Annotation Color LaunchMode
        LaunchQuantisation TimeSignature Envelopes ScrollerTimePreserver TimeSelection Legato Ram
        GrooveSettings Disabled VelocityAmount FollowAction Grid FreezeStart FreezeEnd IsWarped
        TakeId IsInKey ScaleInformation AutomationEnvelopesListWrapper Notes BankSelectCoarse
        BankSelectFine ProgramChange NoteEditorFoldInZoom NoteEditorFoldInScroll
        NoteEditorFoldOutZoom NoteEditorFoldOutScroll NoteEditorFoldScaleZoom
        NoteEditorFoldScaleScroll NoteSpellingPreference AccidentalSpellingPreference
        PreferFlatRootNote ExpressionGrid
      ],
      'AudioClip'                                  => %w[
        LomId LomIdView CurrentStart CurrentEnd Loop Name Annotation Color LaunchMode
        LaunchQuantisation TimeSignature Envelopes ScrollerTimePreserver TimeSelection Legato Ram
        GrooveSettings Disabled VelocityAmount FollowAction Grid FreezeStart FreezeEnd IsWarped
        TakeId IsInKey ScaleInformation AutomationEnvelopesListWrapper SampleRef Onsets WarpMode
        GranularityTones GranularityTexture FluctuationTexture TransientResolution TransientLoopMode
        TransientEnvelope ComplexProFormants ComplexProEnvelope Sync HiQ Fade Fades PitchCoarse
        PitchFine SampleVolume WarpMarkers SavedWarpMarkersForStretched MarkersGenerated
        IsSongTempoLeader
      ],
      'MidiClip/Notes'                             => %w[
        KeyTracks PerNoteEventStore NoteProbabilityGroups ProbabilityGroupIdGenerator NoteIdGenerator
      ],
      'MidiTrack/ControllerLayoutCustomization'    => %w[
        PitchClassSource OctaveSource KeyNoteTarget StepSize OctaveEvery AllowedKeys FillerKeysMapTo
      ],
      'MidiClip/Notes/ProbabilityGroupIdGenerator' => %w[NextId],
    }
  )

  # The attributes Live 12 writes on every track.
  #
  # They say which panel of the device chain is selected, and Live 11 writes none of them.
  TRACK_ATTRIBUTES = { # sorted alphabetically by key
    'SelectedGeneratorName'      => '',
    'SelectedToolPanel'          => '7',
    'SelectedTransformationName' => '',
  }.freeze

  # The attributes the newer version writes on an element.
  add_attribute(
    down: {},
    up:   {
      'AudioTrack'   => TRACK_ATTRIBUTES,
      'GroupTrack'   => TRACK_ATTRIBUTES,
      'MainTrack'    => TRACK_ATTRIBUTES,
      'MidiTrack'    => TRACK_ATTRIBUTES,
      'PreHearTrack' => TRACK_ATTRIBUTES,
      'ReturnTrack'  => TRACK_ATTRIBUTES,
    }
  )

  # The elements of the controller layout customization of a MIDI track.
  #
  # Live 12 writes the settings of the note layout of the track, and Live 11 does not.
  #
  # The elements are written in the order Live writes them in, so this list is in that order and
  # not in alphabetical order, even though the names could be sorted.
  CONTROLLER_LAYOUT = [ # sorted alphabetically by name
    { name: 'PitchClassSource', attributes: { 'Value' => '0' } },
    { name: 'OctaveSource',     attributes: { 'Value' => '2' } },
    { name: 'KeyNoteTarget',    attributes: { 'Value' => '60' } },
    { name: 'StepSize',         attributes: { 'Value' => '1' } },
    { name: 'OctaveEvery',      attributes: { 'Value' => '12' } },
    { name: 'AllowedKeys',      attributes: { 'Value' => '0' } },
    { name: 'FillerKeysMapTo',  attributes: { 'Value' => '0' } }
  ].freeze

  # The elements of the probability group id generator.
  PROBABILITY_GROUP_GENERATOR = [{ # sorted alphabetically by key
    attributes: { 'Value' => '1' },
    name:       'NextId',
  }].freeze

  # What Live 12 adds to a set that came from Live 11.
  #
  # Each entry names the parent the element goes in, the element itself, and the attributes it
  # has. Where the element goes among the children of its parent is not said here: the order of
  # CHILD_ORDER says that, and the same order applies to the elements the conversion moves.
  add(
    down: [],
    up:   [
      { parent: 'LiveSet', name: 'SelectedBreakpointValue', attributes: { 'Value' => '0' } },
      { parent: 'LiveSet', name: 'ViewStateArrangerMixerVolumeSectionHeight',
        attributes: { 'Value' => '120' } },
      { parent: 'LiveSet', name: 'ShouldSceneTempoAndTimeSignatureBeVisible',
        attributes: { 'Value' => 'false' } },
      { parent: 'LiveSet', name: 'WaveformVerticalZoomFactor', attributes: { 'Value' => '1' } },
      { parent: 'LiveSet', name: 'IsWaveformVerticalZoomActive', attributes: { 'Value' => 'true' } },
      { parent: 'LiveSet', name: 'SelectedDocumentViewInMainWindow', attributes: { 'Value' => '0' } },
      { parent: 'LiveSet', name: 'NoteSpellingPreference', attributes: { 'Value' => '0' } },
      { parent: 'LiveSet', name: 'TuningSystems', attributes: {} },
      { parent: 'LiveSet', name: 'ViewStateMainWindowClipDetailOpen', attributes: { 'Value' => 'false' } },
      { parent: 'LiveSet', name: 'ViewStateMainWindowHiddenOtherDocViewTypeClipDetailOpen',
        attributes: { 'Value' => 'false' } },
      { parent: 'LiveSet', name: 'ViewStateMainWindowHiddenOtherDocViewTypeDeviceDetailOpen',
        attributes: { 'Value' => 'true' } },
      { parent: 'LiveSet', name: 'ViewStateMainWindowDeviceDetailOpen', attributes: { 'Value' => 'true' } },
      { parent: 'LiveSet', name: 'ViewStateSecondWindowClipDetailOpen', attributes: { 'Value' => 'true' } },
      { parent: 'LiveSet', name: 'ViewStateSecondWindowDeviceDetailOpen', attributes: { 'Value' => 'false' } },
      { parent: 'LiveSet', name: 'NoteAlgorithms', attributes: {} },

      { parent: 'LiveSet/ViewStates', name: 'MixerInArrangement', attributes: { 'Value' => '0' } },
      { parent: 'LiveSet/ViewStates', name: 'MixerInSession', attributes: { 'Value' => '1' } },
      { parent: 'LiveSet/ViewStates', name: 'ArrangerMixerIO', attributes: { 'Value' => '1' } },
      { parent: 'LiveSet/ViewStates', name: 'ArrangerMixerSends', attributes: { 'Value' => '1' } },
      { parent: 'LiveSet/ViewStates', name: 'ArrangerMixerReturns', attributes: { 'Value' => '1' } },
      { parent: 'LiveSet/ViewStates', name: 'ArrangerMixerVolume', attributes: { 'Value' => '1' } },
      { parent: 'LiveSet/ViewStates', name: 'ArrangerMixerTrackOptions', attributes: { 'Value' => '0' } },
      { parent: 'LiveSet/ViewStates', name: 'ArrangerMixerCrossFade', attributes: { 'Value' => '0' } },
      { parent: 'LiveSet/ViewStates', name: 'ArrangerMixerTrackPerformanceImpactMeter',
        attributes: { 'Value' => '0' } },
      { parent: 'LiveSet/ViewStates', name: 'SessionVolume', attributes: { 'Value' => '1' } },
      { parent: 'LiveSet/ViewStates', name: 'SessionTrackOptions', attributes: { 'Value' => '0' } },
      { parent: 'LiveSet/ViewStates', name: 'SessionTrackPerformanceImpactMeter',
        attributes: { 'Value' => '0' } },
      { parent: 'LiveSet/ViewStates', name: 'ArrangerVolume', attributes: { 'Value' => '1' } },
      { parent: 'LiveSet/ViewStates', name: 'ArrangerTrackOptions', attributes: { 'Value' => '0' } },

      { parent: 'LiveSet/GroovePool', name: 'DefaultGrooveId', attributes: { 'Value' => '-1' } },
      { parent: 'LiveSet/GroovePool', name: 'GroovesListWrapper', attributes: { 'LomId' => '0' } },

      { parent: 'MidiTrack', name: 'ArrangementClipsListWrapper', attributes: { 'LomId' => '0' } },
      { parent: 'MidiTrack', name: 'TakeLanesListWrapper', attributes: { 'LomId' => '0' } },
      { parent: 'MidiTrack', name: 'ControllerLayoutRemoteable', attributes: { 'Value' => '0' } },
      { parent: 'MidiTrack', name: 'ControllerLayoutCustomization', attributes: {},
        children: CONTROLLER_LAYOUT },

      { parent: 'AudioTrack', name: 'ArrangementClipsListWrapper', attributes: { 'LomId' => '0' } },
      { parent: 'AudioTrack', name: 'TakeLanesListWrapper', attributes: { 'LomId' => '0' } },
      { parent: 'AudioTrack', name: 'IsTuned', attributes: { 'Value' => 'true' } },

      { parent: 'MainTrack', name: 'ArrangementClipsListWrapper', attributes: { 'LomId' => '0' } },
      { parent: 'MainTrack', name: 'TakeLanesListWrapper', attributes: { 'LomId' => '0' } },

      { parent: 'ReturnTrack', name: 'ArrangementClipsListWrapper', attributes: { 'LomId' => '0' } },
      { parent: 'ReturnTrack', name: 'TakeLanesListWrapper', attributes: { 'LomId' => '0' } },

      { parent: 'PreHearTrack', name: 'ArrangementClipsListWrapper', attributes: { 'LomId' => '0' } },
      { parent: 'PreHearTrack', name: 'TakeLanesListWrapper', attributes: { 'LomId' => '0' } },

      { parent: 'GroupTrack', name: 'ArrangementClipsListWrapper', attributes: { 'LomId' => '0' } },
      { parent: 'GroupTrack', name: 'TakeLanesListWrapper', attributes: { 'LomId' => '0' } },
      { parent: 'GroupTrack', name: 'Freeze', attributes: { 'Value' => 'false' } },

      { parent: 'TakeLane', name: 'LomId', attributes: { 'Value' => '0' } },
      { parent: 'TakeLane', name: 'ArrangementClipsListWrapper', attributes: { 'LomId' => '0' } },

      { parent: 'MidiClip', name: 'AutomationEnvelopesListWrapper', attributes: { 'LomId' => '0' } },
      { parent: 'MidiClip', name: 'AccidentalSpellingPreference', attributes: { 'Value' => '3' } },

      { parent: 'AudioClip', name: 'AutomationEnvelopesListWrapper', attributes: { 'LomId' => '0' } },
      { parent: 'AudioClip/SampleRef', name: 'SamplesToAutoWarp', attributes: { 'Value' => '0' } },
      { parent: 'AudioClip', name: 'ScaleInformation', attributes: {},
        children: [{ name: 'Root', attributes: { 'Value' => '0' } },
                   { name: 'Name', attributes: { 'Value' => '0' } }] },
      { parent: 'AudioClip', name: 'IsInKey', attributes: { 'Value' => 'false' } },

      { parent: 'MidiClip/Notes', name: 'NoteProbabilityGroups', attributes: {} },
      { parent: 'MidiClip/Notes', name: 'ProbabilityGroupIdGenerator', attributes: {},
        children: PROBABILITY_GROUP_GENERATOR },

      { parent: 'FileRef', name: 'SourceHint', attributes: { 'Value' => '' } },
      { parent: 'SourceContext/SourceContext', name: 'LocalFiltersJson', attributes: { 'Value' => '' } }
    ]
  )

  # The scales of the two versions, and how they are written.
  #
  # Live 11 writes the name of a scale, and Live 12 writes its index in the list of the scales
  # of Live. Only the scales that have been seen in a set of each version are in the list.
  SCALE_NAMES = { 'Major' => '0' }.freeze
  SCALE_INDEXES = { '0' => 'Major' }.freeze

  # The elements of a MIDI clip that hold the scale of the clip.
  #
  # Live 11 writes them at the end of the clip, next to the settings of the note editor.
  CLIP_SCALE_ELEMENTS = %w[ScaleInformation IsInKey].freeze

  # The transformations that a list cannot express.
  #
  # @return [void]
  def special_transformations # TODO: can these be sorted alphabetically?
    oversampling
    audio_out_target
    scroll_position
    freeze_elements
    need_refreeze
    chooser_bar
    clip_scale
    midi_take_lanes
    take_lane_lom_id
    device_view_data
    id_ref_list
    source_context
    tuning
    track_names
    follow_action_link

    super # This must be the last line in the method
  end

  private

  # A Saturator's Oversampling is "1" or "0" in Live 11, and "true" or "false" in Live 12.
  #
  # Although semantically any truthy or falsey values should work, we try to emulate what Live actually does very
  # closely.
  #
  # A Pedal's Oversampling uses "true"/"false" in both versions, so only a Saturator's is rewritten.
  def oversampling
    # FIXME: This implementation does not test the Live version before outputting a value
    values = { 'true' => '1', 'false' => '0', '1' => 'true', '0' => 'false' }
    document.xpath('//Saturator/Oversampling').each do |element|
      value = element['Value'].to_s
      element['Value'] = values[value] if values.key?(value)
    end
  end

  # Live 12 routes to "AudioOut/Main" and Live 11 routes to "AudioOut/Master".
  def audio_out_target
    # FIXME: This implementation does not test the Live version before outputting a value
    values = { 'AudioOut/Main' => 'AudioOut/Master', 'AudioOut/Master' => 'AudioOut/Main' }
    document.xpath('//Target').each do |element|
      value = element['Value'].to_s
      element['Value'] = values[value] if values.key?(value)
    end
  end

  # The scroll position of the song master.
  #
  # Live 12 keeps the scroll position in an element of its own, and Live 11 keeps it in the song
  # master values, so the element is wrapped on the way down and unwrapped on the way up.
  def scroll_position
    if down?
      document.xpath('//LiveSet/SessionScrollPos').each do |scroll|
        values = build('SongMasterValues')
        position = build('SessionScrollerPos', 'X' => scroll['X'], 'Y' => scroll['Y'])
        values.add_child(position)
        scroll.add_next_sibling(values)
        scroll.remove
      end
    else
      document.xpath('//LiveSet/SongMasterValues').each do |values|
        position = values.at_xpath('./SessionScrollerPos')
        next if position.nil?

        scroll = build('SessionScrollPos', 'X' => position['X'], 'Y' => position['Y'])
        values.add_previous_sibling(scroll)
        values.remove
      end
    end
  end

  # The freeze state of a track.
  #
  # Live 11 describes it with three elements, and Live 12 with only the last of them. The two
  # that Live 12 dropped are written with the values that Live 11 gives a track that is not
  # frozen.
  def freeze_elements
    if down?
      document.xpath('//*[PostProcessFreezeClips]').each do |track|
        freeze = track.at_xpath('./PostProcessFreezeClips')
        freeze.add_previous_sibling(build('VelocityDetail', 'Value' => '0'))
        freeze.add_previous_sibling(build('NeedArrangerRefreeze', 'Value' => 'true'))
      end
    else
      document.xpath('//VelocityDetail | //NeedArrangerRefreeze').each(&:remove)
    end
  end

  # The refreeze of a clip slot.
  #
  # Live 11 says that a clip slot needs a refreeze, and Live 12 leaves the question out.
  #
  # FIXME "Live 12 leaves the question out" wtf does that mean?
  def need_refreeze
    if down?
      document.xpath('//ClipSlot[HasStop and not(NeedRefreeze)]').each do |slot|
        slot.at_xpath('./HasStop').add_next_sibling(build('NeedRefreeze', 'Value' => 'true'))
      end
    else
      document.xpath('//ClipSlot/NeedRefreeze').each(&:remove)
    end
  end

  # The state of the chooser bar.
  #
  # Live 11 writes it, and Live 12 does not.
  def chooser_bar
    if down?
      document.xpath('//LiveSet[not(ChooserBar)]').each do |set|
        annotation = set.at_xpath('./Annotation')
        chooser = build('ChooserBar', 'Value' => '0')
        annotation ? annotation.add_previous_sibling(chooser) : set.add_child(chooser)
      end
    else
      document.xpath('//LiveSet/ChooserBar').each(&:remove)
    end
  end

  # The scale of a MIDI clip.
  #
  # Live 12 keeps the scale with the clip, near its beginning, and Live 11 keeps it with the
  # settings of the note editor, at the end of the clip.
  #
  # Going up, the order of the children of the clip says where the scale goes, so nothing is
  # done here.
  def clip_scale
    return unless down?

    document.xpath('//MidiClip[(ScaleInformation or IsInKey) and ' \
                   '(NoteSpellingPreference or ExpressionGrid)]').each do |clip|
      anchor = clip.at_xpath('./NoteSpellingPreference') || clip.at_xpath('./ExpressionGrid')
      CLIP_SCALE_ELEMENTS.each do |name|
        element = clip.at_xpath("./#{name}")
        next if element.nil?

        anchor.add_previous_sibling(element)
      end
    end
  end

  # The take lanes of a MIDI track.
  #
  # Live 11 has take lanes on audio tracks only, and the MIDI track of a Live 11 set has an empty
  # one. A MIDI track in Live 12 can have take lanes, and they are dropped by the conversion.
  def midi_take_lanes
    return unless down?

    document.xpath('//MidiTrack/TakeLanes/TakeLanes/*').remove
  end

  # The identifier of a take lane.
  #
  # Live 12 gives every take lane a LomId and an Id attribute. Live 11 gives it neither.
  #
  # Going up, the LomId is added by the list of the elements Live 12 adds.
  def take_lane_lom_id
    return unless down?

    document.xpath('//TakeLane/LomId').remove
    document.xpath('//TakeLane').each { it.remove_attribute('Id') }
  end

  # The view data of a device.
  #
  # Live 11 keeps the view data of a track, but not the view data of a device.
  def device_view_data
    return unless down?

    document.xpath('//ViewData[parent::*[SourceContext]]').each(&:remove)
  end

  # The list of the identifiers of the patches of an Mx device.
  #
  # Live 11 keeps an empty list there, where Live 12 keeps the identifiers of the patches of the
  # device.
  def id_ref_list
    return unless down?

    document.xpath('//MxDeviceMidiEffect/IdRefList | //MxDeviceAudioEffect/IdRefList').each do |list|
      list.children.remove
      list.add_child(build('IdRefList'))
    end
  end

  # The source context of an Mx device.
  #
  # Live 11 does not record where an Mx device came from, and Live 12 does.
  def source_context
    return unless down?

    document.xpath('//MxDeviceMidiEffect/SourceContext/Value | //MxDeviceAudioEffect/SourceContext/Value')
            .each { |value| value.children.remove }
  end

  # The tuning of the set and of its tracks.
  #
  # Live 11 writes the name of a scale, and Live 12 writes its index in the list of the scales
  # of Live. Live 12 says that the set is in key, and that a MIDI track is tuned, unless the
  # track holds a drum rack: the notes of a drum rack are not pitches.
  #
  # Going down, the name of the scale is put back, and the tuning of the tracks is dropped.
  def tuning
    if down?
      document.xpath('//ScaleInformation/Name').each do |name|
        value = name['Value'].to_s
        name['Value'] = SCALE_INDEXES[value] if SCALE_INDEXES.key?(value)
      end
      return
    end

    document.xpath('//LiveSet/InKey').each { |in_key| in_key['Value'] = 'true' }
    document.xpath('//ScaleInformation/Name').each do |name|
      value = name['Value'].to_s
      name['Value'] = SCALE_NAMES[value] if SCALE_NAMES.key?(value)
    end
    document.xpath('//MidiTrack').each do |track|
      value = track.at_xpath('.//DrumGroupDevice') ? 'false' : 'true'
      element = track.at_xpath('./IsTuned')
      if element.nil?
        track.add_child(build('IsTuned', 'Value' => value))
      else
        element['Value'] = value
      end
    end
  end

  # The name of the track that Live 11 calls the master track.
  #
  # Live 12 calls it the main track and names it "Main". The pre-hear track follows the main
  # track, and Live 12 names it after the main track it follows.
  def track_names
    return unless up?

    rename_effective_name('//MainTrack', 'Main')
    rename_effective_name('//PreHearTrack', "#{lom_id_of('//PreHearTrack')}-Main")
  end

  # The linking of a follow action.
  #
  # Live 12 says that a follow action that is enabled is not linked.
  def follow_action_link
    return unless up?

    document.xpath('//LiveSet/Scenes/Scene/FollowAction[FollowActionEnabled/@Value="true"]/IsLinked')
            .each { |is_linked| is_linked['Value'] = 'false' }
  end

  # Renames the effective name of the tracks a path finds.
  #
  # Only a name that Live 11 gives the master track is renamed: a name the user chose is kept.
  #
  # @param path [String] the path of the tracks
  # @param name [String] the name Live 12 gives the track
  # @return [void]
  def rename_effective_name(path, name)
    document.xpath(path).each do |track|
      effective = track.at_xpath('./Name/EffectiveName')
      next if effective.nil?
      next unless effective['Value'] == 'Master'

      effective['Value'] = name
    end
  end

  # The identifier of the first element a path finds.
  #
  # @param path [String] the path of the elements
  # @return [String] the identifier, or zero when there is none
  def lom_id_of(path)
    document.xpath(path).first&.at_xpath('./LomId')&.[]('Value') || '0'
  end
end
