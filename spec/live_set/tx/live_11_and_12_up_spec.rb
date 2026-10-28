require 'spec_helper'
require 'support/live_versions'

# The rules of the conversion between the Live 11 and the Live 12 formats, going up.
#
# A Live 11 set in, a Live 12 set out. The conversion is lossless: it preserves everything the
# set contains and changes only how it is expressed. It reproduces what Live itself does when it
# opens an older set in a newer Live and saves it.
#
# The other direction is in live_11_and_12_down_spec.rb. The two files walk the same rules.
RSpec.describe Live11And12, 'going up to Live 12' do # rubocop:disable RSpec/DescribeClass
  it 'writes the version strings of a Live 12 set' do
    document = live_document(LIVE_11)
    Live11And12.new(document).convert

    expect(document.root['MinorVersion']).to eq LIVE_12
    expect(document.root['Creator']).to eq 'Ableton Live 12.4.6'
    expect(document.root['MajorVersion']).to eq '5'
    expect(document.root['SchemaChangeCount']).to eq '5'
  end

  it 'renames the master track' do
    expect(convert_fragment(LIVE_11, '<MasterTrack/>'))
      .to eq ['<MainTrack><ArrangementClipsListWrapper LomId="0"/><TakeLanesListWrapper LomId="0"/></MainTrack>']
  end

  it 'renames the width of the mixer, typo and all' do
    expect(convert_fragment(LIVE_11, '<ViewStateSesstionTrackWidth/>')).to eq ['<ViewStateSessionTrackWidth/>']
  end

  it 'renames the lane of a MIDI clip' do
    fragment = '<ContentLanes><ExpressionLane/></ContentLanes>'
    expect(convert_fragment(LIVE_11, fragment)).to eq ['<ContentLanes><MidiEditorLaneModel/></ContentLanes>']
  end

  it 'renames the root of a scale' do
    fragment = '<ScaleInformation><RootNote/></ScaleInformation>'
    expect(convert_fragment(LIVE_11, fragment)).to eq ['<ScaleInformation><Root/></ScaleInformation>']
  end

  it 'renames the patch reference of a device' do
    fragment = '<PatchSlot><Value><MxDPatchRef/></Value></PatchSlot>'
    expect(convert_fragment(LIVE_11, fragment)).to eq ['<PatchSlot><Value><MxPatchRef/></Value></PatchSlot>']
  end

  it 'unwraps the scroll position of the song master' do
    fragment = '<SongMasterValues><SessionScrollerPos X="-2086" Y="0"/></SongMasterValues>'
    expect(convert_element(LIVE_11, 'LiveSet', fragment)).to include('<SessionScrollPos X="-2086" Y="0"/>')
  end

  it 'removes the freeze elements Live 12 does not have' do
    fragment = '<VelocityDetail Value="0"/><NeedArrangerRefreeze Value="true"/>' \
               '<PostProcessFreezeClips Value="false"/>'
    expect(convert_element(LIVE_11, 'AudioTrack', fragment))
      .to eq '<AudioTrack><ArrangementClipsListWrapper LomId="0"/><TakeLanesListWrapper LomId="0"/>' \
             '<PostProcessFreezeClips Value="false"/><IsTuned Value="true"/></AudioTrack>'
  end

  it 'removes the refreeze Live 12 does not have' do
    fragment = '<ClipSlot><HasStop Value="true"/><NeedRefreeze Value="true"/></ClipSlot>'
    expect(convert_fragment(LIVE_11, fragment)).to eq ['<ClipSlot><HasStop Value="true"/></ClipSlot>']
  end

  it 'removes the chooser bar Live 12 does not have' do
    expect(convert_element(LIVE_11, 'LiveSet', '<ChooserBar Value="0"/>')).not_to include 'ChooserBar'
  end

  it 'rewrites the oversampling of a Saturator' do
    expect(convert_fragment(LIVE_11, '<Saturator><Oversampling Value="1"/></Saturator>'))
      .to eq ['<Saturator><Oversampling Value="true"/></Saturator>']
  end

  it 'rewrites the output target' do
    expect(convert_fragment(LIVE_11, '<Target Value="AudioOut/Master"/>')).to eq ['<Target Value="AudioOut/Main"/>']
  end

  it 'moves the scale of a MIDI clip to the beginning of the clip' do
    fragment = '<Name/><ScaleInformation/><IsInKey/><NoteSpellingPreference/>'
    expect(convert_element(LIVE_11, 'MidiClip', fragment))
      .to eq '<MidiClip><Name/><IsInKey/><ScaleInformation/>' \
             '<AutomationEnvelopesListWrapper LomId="0"/><NoteSpellingPreference/>' \
             '<AccidentalSpellingPreference Value="3"/></MidiClip>'
  end

  it 'adds the identifier of a take lane' do
    expect(convert_element(LIVE_11, 'TakeLane', '<Height/>'))
      .to eq '<TakeLane><LomId Value="0"/><Height/><ArrangementClipsListWrapper LomId="0"/></TakeLane>'
  end

  it 'adds the wrappers of a track' do
    expect(convert_element(LIVE_11, 'MidiTrack', '<ClipSlotsListWrapper/><ViewData/>'))
      .to eq '<MidiTrack><ClipSlotsListWrapper/><ArrangementClipsListWrapper LomId="0"/>' \
             '<TakeLanesListWrapper LomId="0"/><ViewData/><IsTuned Value="false"/>' \
             '<ControllerLayoutRemoteable Value="0"/><ControllerLayoutCustomization>' \
             '<PitchClassSource Value="0"/><OctaveSource Value="2"/><KeyNoteTarget Value="60"/>' \
             '<StepSize Value="1"/><OctaveEvery Value="12"/><AllowedKeys Value="0"/>' \
             '<FillerKeysMapTo Value="0"/></ControllerLayoutCustomization></MidiTrack>'
  end

  it 'adds the wrapper of the envelopes of a clip' do
    expect(convert_element(LIVE_11, 'MidiClip', '<Notes/>'))
      .to eq '<MidiClip><AutomationEnvelopesListWrapper LomId="0"/>' \
             '<Notes><NoteProbabilityGroups/><ProbabilityGroupIdGenerator><NextId Value="1"/>' \
             '</ProbabilityGroupIdGenerator></Notes><AccidentalSpellingPreference Value="3"/></MidiClip>'
  end

  it 'adds the probability groups of a clip' do
    fragment = '<KeyTracks/><NoteIdGenerator/>'
    expect(convert_element(LIVE_11, 'MidiClip/Notes', fragment))
      .to eq '<Notes><KeyTracks/><NoteProbabilityGroups/>' \
             '<ProbabilityGroupIdGenerator><NextId Value="1"/></ProbabilityGroupIdGenerator>' \
             '<NoteIdGenerator/></Notes>'
  end

  it 'adds the default groove and the wrapper of the grooves' do
    fragment = '<LomId Value="0"/><Grooves/>'
    expect(convert_element(LIVE_11, 'LiveSet/GroovePool', fragment))
      .to eq '<GroovePool><LomId Value="0"/><Grooves/><DefaultGrooveId Value="-1"/>' \
             '<GroovesListWrapper LomId="0"/></GroovePool>'
  end

  it 'adds the settings of the note layout of a MIDI track' do
    fragment = '<DeviceChain/><PitchbendRange/>'
    expect(convert_element(LIVE_11, 'MidiTrack', fragment))
      .to eq '<MidiTrack><ArrangementClipsListWrapper LomId="0"/><TakeLanesListWrapper LomId="0"/>' \
             '<DeviceChain/><PitchbendRange/><IsTuned Value="false"/>' \
             '<ControllerLayoutRemoteable Value="0"/><ControllerLayoutCustomization>' \
             '<PitchClassSource Value="0"/><OctaveSource Value="2"/><KeyNoteTarget Value="60"/>' \
             '<StepSize Value="1"/><OctaveEvery Value="12"/><AllowedKeys Value="0"/>' \
             '<FillerKeysMapTo Value="0"/></ControllerLayoutCustomization></MidiTrack>'
  end

  it 'adds the view states Live 12 has' do
    fragment = '<SessionIO Value="1"/><SessionSends Value="1"/><SessionReturns Value="1"/>' \
               '<SessionMixer Value="1"/><SessionTrackDelay Value="0"/><SessionCrossFade Value="0"/>' \
               '<SessionShowOverView Value="0"/><ArrangerIO Value="0"/><ArrangerReturns Value="0"/>' \
               '<ArrangerMixer Value="1"/><ArrangerTrackDelay Value="0"/><ArrangerShowOverView Value="1"/>'
    expect(convert_element(LIVE_11, 'LiveSet/ViewStates', fragment))
      .to include('<MixerInArrangement Value="0"/>', '<ArrangerMixerIO Value="1"/>',
                  '<SessionVolume Value="1"/>', '<ArrangerVolume Value="1"/>')
  end

  it 'does not add the constructs of Live 12 to a set that is going down' do
    expect(convert_fragment(LIVE_12, '<MidiTrack><ClipSlotsListWrapper/><ViewData/></MidiTrack>'))
      .to eq ['<MidiTrack><ClipSlotsListWrapper/><ViewData/></MidiTrack>']
  end
end
