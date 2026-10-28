require 'spec_helper'
require 'support/live_versions'

# The rules of the conversion between the Live 11 and the Live 12 formats, going down.
#
# A Live 12 set in, a Live 11 set out. The conversion is lossy: the constructs the Live 11
# format cannot represent are dropped, and they cannot be recovered.
#
# The other direction is in live_11_and_12_up_spec.rb. The two files walk the same rules.
RSpec.describe Live11And12, 'going down to Live 11' do # rubocop:disable RSpec/DescribeClass
  it 'writes the version strings of a Live 11 set' do
    document = live_document(LIVE_12)
    Live11And12.new(document).convert

    expect(document.root['MinorVersion']).to eq LIVE_11
    expect(document.root['Creator']).to eq 'Ableton Live 11.3.21'
    expect(document.root['MajorVersion']).to eq '5'
    expect(document.root['SchemaChangeCount']).to eq '3'
  end

  it 'removes the constructs Live 11 does not have' do
    expect(convert_fragment(LIVE_12, '<Roar/><Kept/>')).to eq ['<Kept/>']
  end

  it 'removes a construct only under the parent it belongs to' do
    fragment = '<CrossFadeState><MidiControllerRange/></CrossFadeState><Elsewhere><MidiControllerRange/></Elsewhere>'
    expect(convert_fragment(LIVE_12, fragment))
      .to eq ['<CrossFadeState/>', '<Elsewhere><MidiControllerRange/></Elsewhere>']
  end

  it 'renames the master track' do
    expect(convert_fragment(LIVE_12, '<MainTrack/>')).to eq ['<MasterTrack/>']
  end

  it 'renames the width of the mixer, typo and all' do
    expect(convert_fragment(LIVE_12, '<ViewStateSessionTrackWidth/>')).to eq ['<ViewStateSesstionTrackWidth/>']
  end

  it 'renames the lane of a MIDI clip' do
    fragment = '<ContentLanes><MidiEditorLaneModel/></ContentLanes>'
    expect(convert_fragment(LIVE_12, fragment)).to eq ['<ContentLanes><ExpressionLane/></ContentLanes>']
  end

  it 'renames the root of a scale' do
    fragment = '<ScaleInformation><Root/></ScaleInformation>'
    expect(convert_fragment(LIVE_12, fragment)).to eq ['<ScaleInformation><RootNote/></ScaleInformation>']
  end

  it 'renames the patch reference of a device' do
    fragment = '<PatchSlot><Value><MxPatchRef/></Value></PatchSlot>'
    expect(convert_fragment(LIVE_12, fragment)).to eq ['<PatchSlot><Value><MxDPatchRef/></Value></PatchSlot>']
  end

  it 'empties the elements Live 11 has empty' do
    expect(convert_fragment(LIVE_12, '<SendsPre><SendPreBool/></SendsPre>')).to eq ['<SendsPre/>']
  end

  it 'empties the take lanes of a MIDI track' do
    fragment = '<MidiTrack><TakeLanes><TakeLanes><TakeLane/></TakeLanes></TakeLanes></MidiTrack>'
    expect(convert_fragment(LIVE_12, fragment)).to eq ['<MidiTrack><TakeLanes><TakeLanes/></TakeLanes></MidiTrack>']
  end

  it 'removes the attributes Live 11 does not have' do
    fragment = '<Track SelectedToolPanel="7" SelectedGeneratorName="" Kept="yes"/>'
    expect(convert_fragment(LIVE_12, fragment)).to eq ['<Track Kept="yes"/>']
  end

  it 'gives a note the attributes Live 11 writes' do
    expect(convert_fragment(LIVE_12, '<MidiNoteEvent/>'))
      .to eq ['<MidiNoteEvent VelocityDeviation="0" Probability="1" IsEnabled="true"/>']
  end

  it 'gives a note event the curve controls Live 11 writes' do
    expect(convert_fragment(LIVE_12, '<PerNoteEvent/>'))
      .to eq ['<PerNoteEvent CurveControl1X="0.5" CurveControl1Y="0.5" CurveControl2X="0.5" CurveControl2Y="0.5"/>']
  end

  it 'rewrites the oversampling of a Saturator' do
    expect(convert_fragment(LIVE_12, '<Saturator><Oversampling Value="true"/></Saturator>'))
      .to eq ['<Saturator><Oversampling Value="1"/></Saturator>']
  end

  it 'leaves the oversampling of a Pedal alone' do
    expect(convert_fragment(LIVE_12, '<Pedal><Oversampling Value="true"/></Pedal>'))
      .to eq ['<Pedal><Oversampling Value="true"/></Pedal>']
  end

  it 'rewrites the output target' do
    expect(convert_fragment(LIVE_12, '<Target Value="AudioOut/Main"/>')).to eq ['<Target Value="AudioOut/Master"/>']
  end

  it 'wraps the scroll position in the song master values' do
    fragment = '<LiveSet><SessionScrollPos X="-2086" Y="0"/><ChooserBar Value="0"/></LiveSet>'
    expect(convert_fragment(LIVE_12, fragment))
      .to eq ['<LiveSet><SongMasterValues><SessionScrollerPos X="-2086" Y="0"/></SongMasterValues>' \
              '<ChooserBar Value="0"/></LiveSet>']
  end

  it 'adds the freeze elements Live 11 writes' do
    fragment = '<AudioTrack><PostProcessFreezeClips Value="false"/></AudioTrack>'
    expect(convert_fragment(LIVE_12, fragment))
      .to eq ['<AudioTrack><VelocityDetail Value="0"/><NeedArrangerRefreeze Value="true"/>' \
              '<PostProcessFreezeClips Value="false"/></AudioTrack>']
  end

  it 'adds the refreeze Live 11 writes' do
    fragment = '<ClipSlot><HasStop Value="true"/></ClipSlot>'
    expect(convert_fragment(LIVE_12, fragment)).to eq ['<ClipSlot><HasStop Value="true"/><NeedRefreeze Value="true"/></ClipSlot>']
  end

  it 'adds the chooser bar Live 11 writes' do
    fragment = '<LiveSet><Annotation Value="a"/></LiveSet>'
    expect(convert_fragment(LIVE_12, fragment)).to eq ['<LiveSet><ChooserBar Value="0"/><Annotation Value="a"/></LiveSet>']
  end

  it 'empties the list of the patches of an Mx device' do
    fragment = '<MxDeviceMidiEffect><IdRefList><IdRef/></IdRefList></MxDeviceMidiEffect>'
    expect(convert_fragment(LIVE_12, fragment))
      .to eq ['<MxDeviceMidiEffect><IdRefList><IdRefList/></IdRefList></MxDeviceMidiEffect>']
  end

  it 'empties the source context of an Mx device' do
    fragment = '<MxDeviceMidiEffect><SourceContext><Value><Context/></Value></SourceContext></MxDeviceMidiEffect>'
    expect(convert_fragment(LIVE_12, fragment))
      .to eq ['<MxDeviceMidiEffect><SourceContext><Value/></SourceContext></MxDeviceMidiEffect>']
  end

  it 'moves the scale of a MIDI clip to the note editor' do
    fragment = '<MidiClip><ScaleInformation/><IsInKey/><NoteSpellingPreference/></MidiClip>'
    expect(convert_fragment(LIVE_12, fragment))
      .to eq ['<MidiClip><ScaleInformation/><IsInKey/><NoteSpellingPreference/></MidiClip>']
  end

  it 'removes the identifier of a take lane' do
    fragment = '<TakeLane Id="3"><LomId Value="0"/><Height/></TakeLane>'
    expect(convert_fragment(LIVE_12, fragment)).to eq ['<TakeLane><Height/></TakeLane>']
  end

  it 'removes the view data of a device' do
    fragment = '<Device><SourceContext/><ViewData/></Device><Track><ViewData/></Track>'
    expect(convert_fragment(LIVE_12, fragment)).to eq ['<Device><SourceContext/></Device>', '<Track><ViewData/></Track>']
  end

  it 'removes the tuning of an audio track' do
    fragment = '<AudioTrack><IsTuned Value="true"/></AudioTrack>'
    expect(convert_fragment(LIVE_12, fragment)).to eq ['<AudioTrack/>']
  end
end
