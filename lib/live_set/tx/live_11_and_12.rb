require_relative 'live_version_converter'

# The differences between the Live 11 format and the Live 12 format.
#
# The tables hold the differences that are the same whichever way the set is going: a rule that
# renames an element matches either spelling and emits the other. The special rules hold the
# ones that cannot be expressed that way, because one version has a construct the other does
# not.
#
# The evidence behind each rule is in docs/live_11_12_differences.md.
class Live11And12 < LiveVersionConverter
  # The version strings of each direction.
  #
  # Live rewrites the revision every time it saves a set, so the value here describes the file
  # rather than the set, and it is left out of any comparison of two sets. See docs/cpfir.md
  # section 5.
  VERSION = { # sorted alphabetically by key
    down: {
      'Creator' => 'Ableton Live 11.3.21',
      'MajorVersion' => '5',
      'MinorVersion' => '11.0_11300',
      'Revision' => '5ac24cad7c51ea0671d49e6b4885371f15b57c1e',
      'SchemaChangeCount' => '3',
    },
    up:   {
      'Creator' => 'Ableton Live 12.4.6',
      'MajorVersion' => '5',
      'MinorVersion' => '12.0_12402',
      'Revision' => '0de5c8fa9a692293676cb7700a15afb2046ee1f7',
      'SchemaChangeCount' => '5',
    },
  }.freeze

  # The elements the older version does not have, wherever they appear.
  #
  # The table is read in the direction the set is going, because the two directions do not
  # remove the same elements. Going down, the elements Live 12 has and Live 11 does not are
  # removed. Going up, the elements Live 11 has and Live 12 does not are removed. Neither
  # removal touches the elements the other version has, because they are named in the table of
  # the other direction only.
  REMOVE = {
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
    up:   [],
  }.freeze

  # The elements the older version does not have, under a named parent.
  #
  # Live 12 puts some elements inside a parent that Live 11 does not. Live 12 puts
  # <MidiControllerRange> inside <CrossFadeState>, and Live 11 puts it inside device parameters.
  # Removing such an element by name alone would also remove it from the places Live 11 needs it,
  # so these rules name the parent the element has to be removed from.
  #
  # Going up, the elements Live 11 has and Live 12 does not are removed the same way. Live 11
  # writes the height of the session mixer as <ViewStateSessionMixerHeight>, and Live 12 writes
  # it as <ViewStateSessionMixerVolumeSectionHeight>; the element is renamed, not removed. The
  # four elements of the view states that Live 12 replaced with a different set of elements are
  # removed, and the three that Live 12 dropped outright are removed.
  REMOVE_UNDER = { # sorted alphabetically
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
    ],
  }.freeze

  # The elements the two versions spell differently.
  #
  # The base class reads this table in both directions, so the name of the element is enough.
  RENAME = { # sorted alphabetically by key
    'AutoColorPickerForReturnAndMainTracks' => 'AutoColorPickerForReturnAndMasterTracks',
    'IsSongTempoLeader'                     => 'IsSongTempoMaster',
    'MainTrack'                             => 'MasterTrack',
    'ReWireDeviceMidiTargetId'              => 'ReWireSlaveMidiTargetId',
    'ViewStateSessionTrackWidth'            => 'ViewStateSesstionTrackWidth',
  }.freeze

  # The elements the two versions spell differently, under a named parent.
  #
  # The parent holds the element under a different name in each version, so the path of a rule is
  # the path of the element in the version the set is coming from, and the table holds one path
  # for each direction.
  RENAME_UNDER = { # sorted alphabetically by key
    down: {
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
    },
  }.freeze

  # The elements that are empty in Live 11.
  #
  # Live 12 has content in them that Live 11 cannot represent, so the conversion drops it. The
  # other way, a Live 11 set has them empty already, so there is nothing to restore.
  EMPTY = { # sorted alphabetically
    down: [
      'AudioSequencer/ClipSlotList',
      'MidiTrack/TakeLanes/TakeLanes',
      'Mixer/Sends',
      'SendsPre',
      'TimeAndValueTransforms',
    ],
    up:   [],
  }.freeze

  # The attributes Live 11 does not have.
  #
  # They record which panel of the device chain is selected, and are not part of the sound of the
  # set.
  # sorted alphabetically
  REMOVE_ATTRIBUTE = %w[
    SelectedGeneratorName
    SelectedToolPanel
    SelectedTransformationName
  ].freeze

  # The attributes Live 11 always writes, and the value it writes.
  #
  # Live 12 keeps the probability of a note in the probability groups of the clip, and Live 11
  # keeps it on the note itself. A note that Live 12 does not put in a group always plays.
  #
  # Live 11 writes the four curve control attributes of every note event, and Live 12 writes them
  # only when the curve is not the default.
  DEFAULT_ATTRIBUTE = { # the order of the attributes is the order Live writes them in
    'MidiNoteEvent' => {
      'VelocityDeviation' => '0',
      'Probability' => '1',
      'IsEnabled' => 'true',
    },
    'PerNoteEvent'  => {
      'CurveControl1X' => '0.5',
      'CurveControl1Y' => '0.5',
      'CurveControl2X' => '0.5',
      'CurveControl2Y' => '0.5'
    },
  }.freeze

  # The order Live 12 writes the children of an element in.
  #
  # TODO I strongly suspect that the order of these elements is not fixed. We should test this.
  #
  # TODO This is suspect: The order is where the conversion learns where to put the elements Live 12 adds, and it is
  # where the elements that moved between the versions are moved to. Live 11 writes the scale of a MIDI clip at the end
  # of the clip, and Live 12 writes it near the beginning; the order says so.
  #
  # The spec spec/live_set/tx/live_up_ground_truth_spec.rb checks the table against the set Live itself wrote, so the
  # table is known to be right rather than believed to be.
  CHILD_ORDER = { # DO NOT SORT THESE UNTIL WE ARE SURE ORDER DOES NOT MATTER
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
    },
  }.freeze

  # The elements of the controller layout customization of a MIDI track.
  #
  # Live 12 writes the settings of the note layout of the track, and Live 11 does not.
  CONTROLLER_LAYOUT = [ # the order is the order Live writes the elements in
    { name: 'PitchClassSource', attributes: { 'Value' => '0' } },
    { name: 'OctaveSource',     attributes: { 'Value' => '2' } },
    { name: 'KeyNoteTarget',    attributes: { 'Value' => '60' } },
    { name: 'StepSize',         attributes: { 'Value' => '1' } },
    { name: 'OctaveEvery',      attributes: { 'Value' => '12' } },
    { name: 'AllowedKeys',      attributes: { 'Value' => '0' } },
    { name: 'FillerKeysMapTo',  attributes: { 'Value' => '0' } },
  ].freeze

  # The elements of the probability group id generator.
  PROBABILITY_GROUP_GENERATOR = [{ # sorted alphabetically by key
    attributes: { 'Value' => '1' },
    name: 'NextId',
  }].freeze

  # What Live 12 adds to a set that came from Live 11.
  #
  # Each entry names the parent the element goes in, the element itself, and the attributes it
  # has. Where the element goes among the children of its parent is not said here: the order of
  # CHILD_ORDER says that, and the same order applies to the elements the conversion moves.
  ADD = {
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
      { parent: 'MidiTrack', name: 'IsTuned', attributes: { 'Value' => 'false' } },
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
      { parent: 'AudioClip', name: 'ScaleInformation', attributes: {},
        children: [{ name: 'Root', attributes: { 'Value' => '0' } },
                   { name: 'Name', attributes: { 'Value' => '0' } }] },
      { parent: 'AudioClip', name: 'IsInKey', attributes: { 'Value' => 'false' } },

      { parent: 'MidiClip/Notes', name: 'NoteProbabilityGroups', attributes: {} },
      { parent: 'MidiClip/Notes', name: 'ProbabilityGroupIdGenerator', attributes: {},
        children: PROBABILITY_GROUP_GENERATOR }
    ],
  }.freeze

  # The rules that are not tables.
  #
  # @return [void]
  def special_rules # TODO can these be sorted alphabetically?
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
    # FIXME This implementation does not test the Live version before outputting a value
    values = { 'true' => '1', 'false' => '0', '1' => 'true', '0' => 'false' }
    document.xpath('//Saturator/Oversampling').each do |element|
      value = element['Value'].to_s
      element['Value'] = values[value] if values.key?(value)
    end
  end

  # Live 12 routes to "AudioOut/Main" and Live 11 routes to "AudioOut/Master".
  def audio_out_target
    # FIXME This implementation does not test the Live version before outputting a value
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
      %w[ScaleInformation IsInKey].each do |name|
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
  # Going up, the LomId is added by the table of the elements Live 12 adds.
  def take_lane_lom_id
    return unless down?

    document.xpath('//TakeLane/LomId').remove
    document.xpath('//TakeLane').each { _1.remove_attribute('Id') }
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
end
