<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!--
  Converts a Live 12 set to the Live 11 format.

  Each transformation below is one of the differences between the two versions of the format. The transformations  were found by opening a Live 11 demo set in Live 12, saving it, and comparing the two files.

  The stylesheet is applied with Nokogiri, and the result is written by LiveXmlWriter, because
  libxml2 does not write XML the way Live does. The stylesheet decides what the set says; the
  writer decides how the file looks.

  See docs/als_work.md, "Transform Implementation", and docs/live_11_12_diff.md, "The elements the
  two versions name differently", and "The values the two versions write differently".
-->

<xsl:output method="xml" encoding="UTF-8" indent="no"/>

<!--
  The identity template copies everything that no other template matches.
-->
<xsl:template match="node() | @*">
  <xsl:copy>
    <xsl:apply-templates select="@* | node()"/>
  </xsl:copy>
</xsl:template>

<!--
  These attributes record which panel of the device chain of a track is selected. Live 11 does
  not have them. A template that matches nothing leaves the attribute out of the copy.
-->
<xsl:template match="@SelectedToolPanel | @SelectedTransformationName | @SelectedGeneratorName"
              priority="1"/>

<!--
  The version strings are those of a Live 11 set. They describe the format of the file, and
  Live uses them to decide what it can open. Live writes them in this order, and the order is
  part of the format.
-->
<xsl:template match="Ableton">
  <xsl:element name="Ableton">
    <xsl:attribute name="MajorVersion">5</xsl:attribute>
    <xsl:attribute name="MinorVersion">11.0_11300</xsl:attribute>
    <xsl:attribute name="SchemaChangeCount">3</xsl:attribute>
    <xsl:attribute name="Creator">Ableton Live 11.3.21</xsl:attribute>
    <xsl:attribute name="Revision">5ac24cad7c51ea0671d49e6b4885371f15b57c1e</xsl:attribute>
    <xsl:apply-templates select="node()"/>
  </xsl:element>
</xsl:template>

<!--
  These elements are Live 12 constructs that Live 11 does not have. They are removed, and
  everything they hold goes with them.
-->
<xsl:template match="InstrumentMeld|Roar|ArrangementClipsListWrapper|TakeLanesListWrapper
                     |MpePitchBendUsesTuning|BreakoutIsExpanded|SelectedBreakpointValue
                     |KeepRecordMonitoringLatency|TransientEnvelopeModulationTarget
                     |ComplexProFormantsModulationTarget|ComplexProEnvelopeModulationTarget
                     |SourceHint|LocalFiltersJson|IsTuned|MpeTuningEnabled|AudioOutputsListWrapper
                     |AudioInputsListWrapper|MidiOutputsListWrapper|MidiInputsListWrapper|IsUndoable
                     |MxDIntParameter|ControllerLayoutRemoteable|ControllerLayoutCustomization
                     |ShouldSceneTempoAndTimeSignatureBeVisible|WaveformVerticalZoomFactor
                     |IsWaveformVerticalZoomActive|AutomationEnvelopesListWrapper
                     |SelectedDocumentViewInMainWindow|DefaultGrooveId|NoteProbabilityGroups
                     |ProbabilityGroupIdGenerator|TuningSystems|SamplesToAutoWarp|NoteAlgorithms
                     |ViewStateMainWindowClipDetailOpen
                     |ViewStateMainWindowHiddenOtherDocViewTypeClipDetailOpen
                     |ViewStateMainWindowHiddenOtherDocViewTypeDeviceDetailOpen
                     |ViewStateMainWindowDeviceDetailOpen|ViewStateSecondWindowClipDetailOpen
                     |ViewStateSecondWindowDeviceDetailOpen"/>

<!--
  Live 12 puts some elements inside a parent that Live 11 does not. Live 12 puts
  <MidiControllerRange> inside <CrossFadeState>, and Live 11 puts it inside device parameters.
  Removing such an element by name alone would also remove it from the places Live 11 needs it,
  so these transformations name the parent the element has to be removed from.
-->
<xsl:template match="CrossFadeState/MidiControllerRange
                     |LiveSet/ViewStateArrangerMixerVolumeSectionHeight
                     |MidiClip/AccidentalSpellingPreference
                     |LiveSet/NoteSpellingPreference
                     |AudioClip/IsInKey
                     |AudioClip/ScaleInformation
                     |TimeSignature/MidiControllerRange
                     |GroovePool/GroovesListWrapper"/>

<!--
  These elements are named differently in Live 11.

  The name of the ReWire target of a MIDI track changed, and so did the name of the width of a
  mixer. The latter is spelled with a typo in Live 11, and the typo is part of the format.
-->
<xsl:template match="ReWireDeviceMidiTargetId">
  <xsl:element name="ReWireSlaveMidiTargetId">
    <xsl:apply-templates select="@* | node()"/>
  </xsl:element>
</xsl:template>

<xsl:template match="ViewStateSessionTrackWidth">
  <xsl:element name="ViewStateSesstionTrackWidth">
    <xsl:apply-templates select="@* | node()"/>
  </xsl:element>
</xsl:template>

<xsl:template match="AutoColorPickerForReturnAndMainTracks">
  <xsl:element name="AutoColorPickerForReturnAndMasterTracks">
    <xsl:apply-templates select="@* | node()"/>
  </xsl:element>
</xsl:template>

<xsl:template match="IsSongTempoLeader">
  <xsl:element name="IsSongTempoMaster">
    <xsl:apply-templates select="@* | node()"/>
  </xsl:element>
</xsl:template>

<!--
  These elements are named differently in Live 11, in the context they appear in. The same
  element is named the same way in Live 12 elsewhere.
-->
<xsl:template match="ScaleInformation/Root">
  <xsl:element name="RootNote">
    <xsl:apply-templates select="@* | node()"/>
  </xsl:element>
</xsl:template>

<xsl:template match="LiveSet/ViewStateSessionMixerVolumeSectionHeight">
  <xsl:element name="ViewStateSessionMixerHeight">
    <xsl:apply-templates select="@* | node()"/>
  </xsl:element>
</xsl:template>

<xsl:template match="PatchSlot/Value/MxPatchRef">
  <xsl:element name="MxDPatchRef">
    <xsl:apply-templates select="@* | node()"/>
  </xsl:element>
</xsl:template>

<!--
  A lane is an ExpressionLane in Live 11 and a MidiEditorLaneModel in Live 12. Apart from the
  name they are the same.
-->
<xsl:template match="ContentLanes/MidiEditorLaneModel | ExpressionLanes/MidiEditorLaneModel">
  <xsl:element name="ExpressionLane">
    <xsl:apply-templates select="@* | node()"/>
  </xsl:element>
</xsl:template>

<!-- The master track is a MasterTrack in Live 11. -->
<xsl:template match="MainTrack">
  <xsl:element name="MasterTrack">
    <xsl:apply-templates select="@* | node()"/>
  </xsl:element>
</xsl:template>

<!--
  A Saturator's Oversampling is "1" or "0" in Live 11, and "true" or "false" in Live 12. A
  Pedal's Oversampling uses "true"/"false" in both versions, so only a Saturator's is rewritten.
-->
<xsl:template match="Saturator/Oversampling">
  <xsl:copy>
    <xsl:apply-templates select="@*[not(name()='Value')]"/>
    <xsl:attribute name="Value">
      <xsl:choose>
        <xsl:when test="@Value='true'">1</xsl:when>
        <xsl:when test="@Value='false'">0</xsl:when>
        <xsl:otherwise><xsl:value-of select="@Value"/></xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
    <xsl:apply-templates select="node()"/>
  </xsl:copy>
</xsl:template>

<!-- Live 12 routes to "AudioOut/Main" and Live 11 routes to "AudioOut/Master". -->
<xsl:template match="Target[@Value='AudioOut/Main']">
  <xsl:copy>
    <xsl:apply-templates select="@*[not(name()='Value')]"/>
    <xsl:attribute name="Value">AudioOut/Master</xsl:attribute>
    <xsl:apply-templates select="node()"/>
  </xsl:copy>
</xsl:template>

<!--
  Live 12 keeps the scroll position of the song master in an element of its own. Live 11 keeps
  it in the song master values, so the element is wrapped in them.
-->
<xsl:template match="LiveSet/SessionScrollPos">
  <xsl:element name="SongMasterValues">
    <xsl:element name="SessionScrollerPos">
      <xsl:attribute name="X"><xsl:value-of select="@X"/></xsl:attribute>
      <xsl:attribute name="Y"><xsl:value-of select="@Y"/></xsl:attribute>
    </xsl:element>
  </xsl:element>
</xsl:template>

<!--
  These elements are empty in Live 11 and have content in Live 12.
-->
<xsl:template match="TimeAndValueTransforms|SendsPre|AudioSequencer/ClipSlotList|Mixer/Sends">
  <xsl:element name="{name()}">
    <xsl:apply-templates select="@*"/>
  </xsl:element>
</xsl:template>

<!--
  Live 11 describes a track's freeze state with three elements, and Live 12 with only the last
  of them. The two that Live 12 dropped are written with the values that Live 11 gives a track
  that is not frozen.
-->
<xsl:template match="*[PostProcessFreezeClips]">
  <xsl:copy>
    <xsl:apply-templates select="@*"/>
    <xsl:for-each select="node()">
      <xsl:choose>
        <xsl:when test="self::PostProcessFreezeClips">
          <xsl:element name="VelocityDetail">
            <xsl:attribute name="Value">0</xsl:attribute>
          </xsl:element>
          <xsl:element name="NeedArrangerRefreeze">
            <xsl:attribute name="Value">true</xsl:attribute>
          </xsl:element>
          <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
          </xsl:copy>
        </xsl:when>
        <xsl:otherwise><xsl:apply-templates select="."/></xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:copy>
</xsl:template>

<!--
  Live 11 says that a clip slot needs a refreeze, and Live 12 leaves the question out.
-->
<xsl:template match="ClipSlot[HasStop and not(NeedRefreeze)]">
  <xsl:copy>
    <xsl:apply-templates select="@*"/>
    <xsl:for-each select="node()">
      <xsl:apply-templates select="."/>
      <xsl:if test="self::HasStop and not(preceding-sibling::HasStop)">
        <xsl:element name="NeedRefreeze">
          <xsl:attribute name="Value">true</xsl:attribute>
        </xsl:element>
      </xsl:if>
    </xsl:for-each>
  </xsl:copy>
</xsl:template>

<!--
  Live 11 has take lanes on audio tracks only, and the MIDI track of a Live 11 set has an empty
  one. A MIDI track in Live 12 can have take lanes, and they are dropped by the conversion.
-->
<xsl:template match="MidiTrack/TakeLanes/TakeLanes">
  <xsl:element name="TakeLanes">
    <xsl:apply-templates select="@*"/>
  </xsl:element>
</xsl:template>

<!-- Live 12 gives every take lane a LomId. Live 11 does not. -->
<xsl:template match="TakeLane/LomId"/>

<!-- Live 11 gives a take lane no Id attribute. -->
<xsl:template match="TakeLane">
  <xsl:copy>
    <xsl:apply-templates select="@*[not(name()='Id')]"/>
    <xsl:apply-templates select="node()"/>
  </xsl:copy>
</xsl:template>

<!--
  Live 11 keeps the view data of a track, but not the view data of a device.
-->
<xsl:template match="ViewData[parent::*[SourceContext]]"/>

<!-- Live 11 tunes MIDI tracks, and does not tune audio tracks. -->
<xsl:template match="AudioTrack/IsTuned"/>

<!--
  Live 11 does not record where an Mx device came from, and Live 12 does.
-->
<xsl:template match="MxDeviceMidiEffect/SourceContext/Value | MxDeviceAudioEffect/SourceContext/Value">
  <xsl:element name="Value">
    <xsl:apply-templates select="@*"/>
  </xsl:element>
</xsl:template>

<!--
  Live 11 keeps an empty list there, where Live 12 keeps the IDs of the patches of the device.
-->
<xsl:template match="MxDeviceMidiEffect/IdRefList | MxDeviceAudioEffect/IdRefList">
  <xsl:element name="IdRefList">
    <xsl:apply-templates select="@*"/>
    <xsl:element name="IdRefList"/>
  </xsl:element>
</xsl:template>

<!--
  Live 12 keeps the scale of a MIDI clip with the clip itself, and Live 11 keeps it with the
  settings of the note editor, at the end of the clip.
-->
<xsl:template match="MidiClip[(ScaleInformation or IsInKey) and (NoteSpellingPreference or ExpressionGrid)]">
  <xsl:copy>
    <xsl:apply-templates select="@*"/>
    <xsl:variable name="scale" select="ScaleInformation[1]"/>
    <xsl:variable name="in_key" select="IsInKey[1]"/>
    <xsl:variable name="anchor" select="NoteSpellingPreference[1] | ExpressionGrid[1]"/>
    <xsl:for-each select="node()">
      <xsl:choose>
        <xsl:when test="self::NoteSpellingPreference[not(preceding-sibling::NoteSpellingPreference)]
                        or (not($anchor/self::NoteSpellingPreference)
                            and self::ExpressionGrid[not(preceding-sibling::ExpressionGrid)])">
          <xsl:apply-templates select="$scale"/>
          <xsl:apply-templates select="$in_key"/>
          <xsl:apply-templates select="."/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="self::ScaleInformation or self::IsInKey"/>
            <xsl:otherwise><xsl:apply-templates select="."/></xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:copy>
</xsl:template>

<!--
  Live 12 keeps the probability of a note in the probability groups of the clip, and Live 11
  keeps it on the note itself. A note that Live 12 does not put in a group always plays.
-->
<xsl:template match="MidiNoteEvent">
  <xsl:copy>
    <xsl:apply-templates select="@*"/>
    <xsl:if test="not(@VelocityDeviation)">
      <xsl:attribute name="VelocityDeviation">0</xsl:attribute>
    </xsl:if>
    <xsl:if test="not(@Probability)">
      <xsl:attribute name="Probability">1</xsl:attribute>
    </xsl:if>
    <xsl:if test="not(@IsEnabled)">
      <xsl:attribute name="IsEnabled">true</xsl:attribute>
    </xsl:if>
    <xsl:apply-templates select="node()"/>
  </xsl:copy>
</xsl:template>

<!--
  Live 11 writes the four curve control attributes of every note event. Live 12 writes them
  only when the curve is not the default, and so a note event without them has the default
  curve.
-->
<xsl:template match="PerNoteEvent">
  <xsl:copy>
    <xsl:apply-templates select="@*"/>
    <xsl:if test="not(@CurveControl1X)">
      <xsl:attribute name="CurveControl1X">0.5</xsl:attribute>
    </xsl:if>
    <xsl:if test="not(@CurveControl1Y)">
      <xsl:attribute name="CurveControl1Y">0.5</xsl:attribute>
    </xsl:if>
    <xsl:if test="not(@CurveControl2X)">
      <xsl:attribute name="CurveControl2X">0.5</xsl:attribute>
    </xsl:if>
    <xsl:if test="not(@CurveControl2Y)">
      <xsl:attribute name="CurveControl2Y">0.5</xsl:attribute>
    </xsl:if>
    <xsl:apply-templates select="node()"/>
  </xsl:copy>
</xsl:template>

<!--
  Live 11 writes the state of the chooser bar, and Live 12 does not.
-->
<xsl:template match="LiveSet[not(ChooserBar)]">
  <xsl:copy>
    <xsl:apply-templates select="@*"/>
    <xsl:variable name="annotation" select="Annotation[1]"/>
    <xsl:for-each select="node()">
      <xsl:choose>
        <xsl:when test="self::Annotation[not(preceding-sibling::Annotation)]">
          <xsl:element name="ChooserBar">
            <xsl:attribute name="Value">0</xsl:attribute>
          </xsl:element>
          <xsl:apply-templates select="."/>
        </xsl:when>
        <xsl:otherwise><xsl:apply-templates select="."/></xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    <xsl:if test="not($annotation)">
      <xsl:element name="ChooserBar">
        <xsl:attribute name="Value">0</xsl:attribute>
      </xsl:element>
    </xsl:if>
  </xsl:copy>
</xsl:template>

</xsl:stylesheet>
