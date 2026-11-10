# ALS Filetype Notes

This document contains details of the Ableton Live Set (ALS) file format. This
is a WHAT document that discusses XML documents, XML fragments, and how they
morph between Live versions. See [ALS Architecture](als_architecture.md) for
information about how this project models the XML, transforms it, and serializes
it to markdown.

The workflow is described in [als_work.md](als_work.md).

The terms these documents use are defined in [glossary.md](glossary.md).

## ALS Files Are XML, Probably GZipped

An `.als` file is an XML document. Most are gzip-compressed, but uncompressed
`.als` files are sometimes used for testing purposes.                                 |


## ALS XML

The top-level element (or root tag) in an `.als` file is `<Ableton>`.

If you uncompress an `.als` file and examine the XML it contains, the outermost
elmentss of the XML document look something like this:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Ableton MajorVersion="5"
         MinorVersion="12.0_12048"
         SchemaChangeCount="3"
         Creator="Ableton Live 12.0.5">
  <LiveSet>
    <!-- Tracks, clips, automation, mixer settings, and device chains go here -->
  </LiveSet>
</Ableton>
```

There is only `<Ableton/>` element in an `.als` file, and it is the root XML
element. It has 4 attributes, which we discuss later in detail. Within the
`<Ableton/>` element there is only one `<LiveSet/>` element. Both of these
elements only occur once in the XML, so they can be represented by a Ruby model
class.

Other XML elements can occur many times in the XML. For example, tracks, devices
and clips are wrapped within collection elements. These XML elements are
represented in Ruby by collections of model classes.

In the following example, `<Events>` is an XML element holding a collection of
clips for the arrangment view timeline. Notice that the `<AudioClip/>` elements
within a collection have attributes that provide their positions on the timeline
(`Time`) and lengths (`Duration`).

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Ableton MajorVersion="5" MinorVersion="12.0_12048" SchemaChangeCount="3" Creator="Ableton Live 12.0.5">
  <LiveSet>
    <Tracks>

      <!-- AUDIO TRACK 1: Contains 1 Clip -->
      <AudioTrack Id="0">
        <Name><EffectiveName Value="Audio 1" /></Name>
        <DeviceChain>
          <MainSequencer>
            <SampleSequencer>
              <ArrangerAutomation>
                <Events>
                  <!-- The collection wrapper for arrangement clips on this track -->
                  <AudioClip Id="10" Time="0.0" Duration="4.0">
                    <Name Value="Snare_Loop" />
                    <CurrentStart Value="0.0" />
                    <CurrentEnd Value="4.0" />
                  </AudioClip>
                </Events>
              </ArrangerAutomation>
            </SampleSequencer>
          </MainSequencer>
        </DeviceChain>
      </AudioTrack>

      <!-- AUDIO TRACK 2: Contains 2 Clips -->
      <AudioTrack Id="1">
        <Name><EffectiveName Value="Audio 2" /></Name>
        <DeviceChain>
          <MainSequencer>
            <SampleSequencer>
              <ArrangerAutomation>
                <Events>
                  <!-- First arrangement clip -->
                  <AudioClip Id="20" Time="0.0" Duration="8.0">
                    <Name Value="Synth_Pad" />
                    <CurrentStart Value="0.0" />
                    <CurrentEnd Value="8.0" />
                  </AudioClip>
                  <!-- Second arrangement clip, sequential on the timeline -->
                  <AudioClip Id="21" Time="8.0" Duration="4.0">
                    <Name Value="Synth_Pad_Fill" />
                    <CurrentStart Value="0.0" />
                    <CurrentEnd Value="4.0" />
                  </AudioClip>
                </Events>
              </ArrangerAutomation>
            </SampleSequencer>
          </MainSequencer>
        </DeviceChain>
      </AudioTrack>
    </Tracks>
  </LiveSet>
</Ableton>
```


## ALS Schemas

TODO We have found that standard XML schemas (`.xsd` filetype) have limited use
in this project. Ableton Live is shipped with proprietary and undocumented
schemas that we should reverse engineer. See `C:\ProgramData\Ableton\Live 12 Suite\Resources\Schema`.

### Ableton Schemas

The Ableton Schemas are about 200KB, so they are not listed in their entirety
here.

#### `LiveSet` Element

This is the top-level element since the Ableton schema does not contain the
`<Ableton/>` element. I sorted its child elements for easier reading.

```xml
 <LiveSet InternalName="LiveDocument">
  <Annotation Class="RemoteableString" Type="0" />
  <AutoQuantisation Class="RemoteableEnum" Type="0" />
  <ChooserBar Class="RemoteableInt" Type="0" />
  <ContentSplitterProperties Class="RemoteableSizeManager" Type="0" />
  <CrossfadeCurve Class="RemoteableEnum" Type="0" />
  <DetailClipKeyMidis Class="DetailClipKeyMidis" Type="0" />
  <GlobalQuantisation Class="RemoteableEnum" Type="0" />
  <GlobalQuantisationKeyMidi Class="RemoteableKeyMidi" Type="0" />
  <Grid Class="BeatGrid" Type="0" />
  <GroovePool Class="GroovePool" Type="0" />
  <HighlightedTrackIndex Class="RemoteableInt" Type="0" />
  <LatencyCompensation Class="RemoteableEnum" Type="0" />
  <Locators Class="CuePointManager" Type="0" InternalName="CuePointManager" />
  <MasterTrack Class="MasterTrack" Type="0" />
  <NextPointeeId Class="Int" Type="-4" />
  <Overdub Class="RemoteableBool" Type="0" />
  <OverwriteProtectionNumber Class="Int" Type="-4" />
  <PreHearTrack Class="PreHearTrack" Type="0" />
  <SceneNames Class="RemoteableList" Type="-1" />
  <SendsPre Class="RemoteableList" Type="-1" />
  <SequencerNavigator Class="SequencerNavigator" Type="0" />
  <ShowVideoWindow Class="Bool" Type="-4" />
  <SmpteFormat Class="RemoteableEnum" Type="0" />
  <SoloInPlace Class="RemoteableBool" Type="0" />
  <SoloOrPflSavedValue Class="Bool" Type="-4" />
  <SongMasterValues Class="SongMasterValues" Type="0" />
  <TimeSelection Class="SongTimeSelection" Type="0" />
  <TrackHeaderWidth Class="RemoteableInt" Type="0" />
  <Tracks Class="RemoteableList" Type="-1" />
  <Transport Class="Transport" Type="0" />
  <UseWarperLegacyHiQMode Class="RemoteableBool" Type="0" />
  <VideoWindowRect Class="Rect" Type="-4" />
  <ViewStateArrangerHasDetail Class="RemoteableBool" Type="0" />
  <ViewStateDetailIsSample Class="RemoteableBool" Type="0" />
  <ViewStateEnvelopePanel Class="RemoteableBool" Type="0" />
  <ViewStateFxSlotCount Class="RemoteableInt" Type="0" />
  <ViewStateLaunchPanel Class="RemoteableBool" Type="0" />
  <ViewStateSamplePanel Class="RemoteableBool" Type="0" />
  <ViewStateSessionHasDetail Class="RemoteableBool" Type="0" />
  <ViewStateSessionMixerHeight Class="RemoteableInt" Type="0" />
 </LiveSet>
```

Puzzling:

- The `<Tracks/>` element is not defined in the Ableton schema.

- The Ableton schema defines the `<AudioClip/>` element but does not reference it.


#### `AudioClip` Element

I sorted the child elements of the `<AudioClip/>` element in the Ableton schema
for easier reading. It does not contain a `<DeviceChain/>` element. This is most
puzzling.

```xml
 <AudioClip>
  <Annotation Class="RemoteableString" Type="0" />
  <AutoWarpTolerance Class="RemoteableEnum" Type="0" />
  <ColorIndex Class="RemoteableInt" Type="0" />
  <ComplexProEnvelope Class="UserFloat" Type="0" />
  <ComplexProFormants Class="UserFloat" Type="0" />
  <CurrentEnd Class="RemoteableDouble" Type="0" />
  <CurrentStart Class="RemoteableDouble" Type="0" />
  <Disabled Class="RemoteableBool" Type="0" />
  <Fade Class="RemoteableBool" Type="0" />
  <Fades Class="ClipFades" Type="0" />
  <FluctuationTexture Class="UserFloat" Type="0" />
  <FollowActionA Class="RemoteableEnum" Type="0" />
  <FollowActionB Class="RemoteableEnum" Type="0" />
  <FollowChanceA Class="UserFloat" Type="0" />
  <FollowChanceB Class="UserFloat" Type="0" />
  <FollowTime Class="RemoteableDouble" Type="0" />
  <FreezeEnd Class="RemoteableDouble" Type="0" />
  <FreezeStart Class="RemoteableDouble" Type="0" />
  <GranularityTexture Class="UserFloat" Type="0" />
  <GranularityTones Class="UserFloat" Type="0" />
  <Grid Class="BeatGrid" Type="0" />
  <GrooveSettings Class="ClipGrooveSettings" Type="0" />
  <HiQ Class="RemoteableBool" Type="0" />
  <IsSongTempoMaster Class="RemoteableBool" Type="0" />
  <IsWarped Class="RemoteableBool" Type="0" />
  <LaunchMode Class="RemoteableEnum" Type="0" />
  <LaunchQuantisation Class="RemoteableEnum" Type="0" />
  <Legato Class="RemoteableBool" Type="0" />
  <Loop Class="Loop" Type="0" />
  <MarkerDensity Class="RemoteableEnum" Type="0" />
  <MarkersGenerated Class="RemoteableBool" Type="0" />
  <ModulationList Class="ModulationList" Type="0" />
  <Name Class="RemoteableString" Type="0" />
  <Onsets Class="OnsetArray" Type="0" />
  <PitchCoarse Class="UserFloat" Type="0" />
  <PitchFine Class="UserFloat" Type="0" />
  <Ram Class="RemoteableBool" Type="0" />
  <SampleRef Class="SampleRef" Type="0" />
  <SampleVolume Class="UserFloat" Type="0" />
  <SavedWarpMarkersForStretched Class="RemoteableList" Type="-1" />
  <ScrollerTimePreserver Class="ScrollerTimePreserver" Type="0" />
  <StartWithSongTempo Class="RemoteableBool" Type="0" />
  <Straightening Class="UserFloat" Type="0" />
  <Sync Class="RemoteableBool" Type="0" />
  <Time Class="Double" Type="-4" />
  <TimeSelection Class="ClipTimeSelection" Type="0" />
  <TimeSignature Class="SingleTimeSignatureManager" Type="0" />
  <TransientEnvelope Class="UserFloat" Type="0" />
  <TransientLoopMode Class="RemoteableEnum" Type="0" />
  <TransientResolution Class="RemoteableEnum" Type="0" />
  <VelocityAmount Class="UserFloat" Type="0" />
  <WarpMarkers Class="RemoteableList" Type="-1" />
  <WarpMode Class="RemoteableEnum" Type="0" />
 </AudioClip>
```

### Standard XML Schemas

The `exe/als_to_xsd` command generates the XML schema from one or more ALS files
and store it in the `xsd/` directory of the repository of the reference sets
(stored locally at `$live_reference_sets` with Git repository
`https://github.com/mslinn/live_reference_sets`).

The schema of a version is an inference from the XML stored in the sets of that
version, not a complete specification. If no set in a corpus uses a Live
feature, then XML elements relating to that feature will not appear in the
corpus. See [als_work.md](als_work.md), "Generate Each Schema From Every Set of
That Version".


## Sample ALS XML Fragment

The first 25 lines of an XML within an ALS file were be displayed as follows:

```xml
$ zcat -S .als '/mnt/e/media/songs/jamdance/daw/live/fu Project/fu.als' | less -N -x2
      1 <?xml version="1.0" encoding="UTF-8"?>
      2 <Ableton MajorVersion="5" MinorVersion="12.0_12120" SchemaChangeCount="4"
      2  Creator="Ableton Live 12.1.11" Revision="ce4b7c22b06532409b78ca241e5bb73735e7ca10">
      3   <LiveSet>
      4     <NextPointeeId Value="93191" />
      5     <OverwriteProtectionNumber Value="3073" />
      6     <LomId Value="3" />
      7     <LomIdView Value="0" />
      8     <Tracks>
      9       <AudioTrack Id="8" SelectedToolPanel="7" SelectedTransformationName="" SelectedGeneratorName="">
     10         <LomId Value="0" />
     11         <LomIdView Value="0" />
     12         <IsContentSelectedInDocument Value="false" />
     13         <PreferredContentViewMode Value="0" />
     14         <TrackDelay>
     15           <Value Value="0" />
     16           <IsValueSampleBased Value="false" />
     17         </TrackDelay>
     18         <Name>
     19           <EffectiveName Value="Drums / complete" />
     20           <UserName Value="Drums / complete" />
     21           <Annotation Value="" />
     22           <MemorizedFirstClipName Value="Bruno_Mars_Uptown_Funk_percussion" />
     23         </Name>
     24         <Color Value="14" />
     25         <AutomationEnvelopes>
     26           <Envelopes />
     27         </AutomationEnvelopes>
     28         <TrackGroupId Value="-1" />
     29         <TrackUnfolded Value="true" />
     30         <DevicesListWrapper LomId="0" />
     31         <ClipSlotsListWrapper LomId="0" />
     32         <ArrangementClipsListWrapper LomId="0" />
     33         <ViewData Value='{"alternative_mode_locked": false, "push-instrument-selected-notes": [36], "push-note-
     33 repeat-rate": 0.5, "push-note-repeat-enabled": false}' />
     34         <TakeLanes>
     35           <TakeLanes />
```


```text
@audiotrack = LiveSet.Tracks.AudioTrack.
  DeviceChain.MainSequencer.ClipSlotList.ClipSlot.children.
    ClipSlot.Value.children. # Passed to LiveAudioClip
      SampleRef.FileRef
        Path['Value']  # Absolute path
        RelativePath['Value']
        OriginalFileSize['Value'] # Bytes
```


Clip paths can look like this:

```text
    # @audio_track.DeviceChain.FreezeSequencer.ClipSlotList.ClipSlot
    # @audio_track.DeviceChain.Mixer.ClipSlotList.ClipSlot
    # @audio_track.xpath('//Path').map{|x| x['Value']}.uniq # Gives results like:
    #   "E:/media/Ableton/Projects/fu Project/Samples/Processed/Freeze/Freeze Guitar [2024-03-12 133812].wav"
    #   "E:/media/Ableton/Projects/fu Project/Samples/Imported/smooth_operator_horns.mp3"
    #   "/Reverb Default.adv"
    #   "/Users/nsh/Library/Application Support/Ableton/Live 11 Core Library/Devices/Audio Effects/Simple Delay/Dotted Eighth Note.adv"
    #   "E:/media/Ableton/Projects/fu Project/Audio Effects/Color Limiter/Ableton Folder Info/Color Limiter.amxd"
```


## Values are stored in `Value` Attributes

Every value in an `.als` file is stored in a `Value` attribute:

```xml
<RelativePath Value="Samples/Imported/song1.mp3" />
```

This holds for every Live version from 8.2 to 12.4. It was verified against a
corpus of 460 sets.

An element that has no `Value` attribute, or an empty one, holds no value. An
empty attribute is not the same as an absent one:
`<RelativePath Value="" />` means the sample is not in the project folder, while
an absent `<RelativePath>` means the field is not in this version of the XML.
`Xml#xml_value` yields `nil` for both, because every caller treats them alike.

There is no text-only shape in practice. Do not attempt to read values with
`element.text` because that will return `""` and silently produce empty results.

### Boolean Values

A missing element means `false`. For example, an `AudioTrack` with no `<Freeze>`
element is not frozen. `Xml#xml_bool?` follows that convention for every
boolean it reads, and warns about a value that is neither `true` nor
`false` so that malformed data does not pass unnoticed.

### XML Reader Methods

`lib/common/xml.rb` provides two readers:

```ruby
xml_value(element)   # the Value attribute, or nil
xml_bool?(element)   # true or false, never nil
```

`xml_bool?` treats a missing element as `false` — an `<AudioTrack>` with no `<Freeze>` element is
not frozen. A value that is neither `true` nor `false` is also `false`, but it is logged, so
malformed data does not pass unnoticed.


## XML Elements

### XML Root Element

The root element is `<Ableton>`, and the document is a single `<LiveSet>` under it.

#### Adding Custom Attributes

Custom attributes can be added to the root `<Ableton>` element without causing
problems with Ableton Live because its XML deserializer will ignore them.

Ableton's XML parsing engine checks for a strict whitelist of attributes
(`MajorVersion`, `MinorVersion`, `SchemaChangeCount`, `Creator`, and
`Revision`). Unrecognized attributes encountered on the root element (or most
other nodes) are treated as non-fatal noise and skipped during the
object-mapping phase.

While Live will successfully load a specially prepared `.als` file containing
custom root attributes, Live will not preserve them them in the root `<Ableton>`
element when the set is saved.

#### Custom Marker Elements

TODO Write out new attributes the root `<Ableton>` element:

`Generated by`:     `Live_set vX.Y.Z`
`Live_set author`:  `Mike Slinn mslinn@mslinn.com`
`Live_set webpage`: `https://www.mslinn.com/av_studio/ableton_live_set.html`

#### The `Creator` Attribute

The `<Ableton>` element has `MajorVersion` and `MinorVersion` attributes, but
those are Ableton's internal set-format numbers, not the Live version a user
sees. A set written by Live 12.2.1 reports `MajorVersion="5"
MinorVersion="12.0_12203"`.

The real Live version is stored in the `Creator` attribute:

```xml
<Ableton MajorVersion="5"
         MinorVersion="12.0_12203"
         SchemaChangeCount="3"
         Creator="Ableton Live 12.2.1"
         Revision="c0d59beb...">
```


##### `SchemaChangeCount`

`SchemaChangeCount` is a key XML root attribute inside Ableton Live Set (`.als`)
files. It tracks structural schema revisions within the same major/minor release
of Live.

It sits directly inside the top-level `<Ableton>` root element:

```xml
<Ableton
  MajorVersion="5"
  MinorVersion="12.0_12049"
  SchemaChangeCount="7"
  Creator="Ableton Live 12.0"
  Revision="5094b92fa547974769f44cf233f1474777d9434a"
>
```

1. **Sub-minor Data Structure Versioning:** While `MajorVersion` (e.g., `5` for
   Live 11/12 internal XML engines) and `MinorVersion` track broad releases,
   `SchemaChangeCount` tracks structural modifications made to the XML layout
   across patch updates or beta builds without incrementing the primary engine
   schema version.
2. **Internal Serialization Handshaking:** When Live attempts to parse a `.als`
   file, it checks `SchemaChangeCount` against its internal deserializer
   expectations. If the file's `SchemaChangeCount` is higher than what that
   specific build of Live knows how to deserialize (e.g., a project saved in
   Live `12.0.5` being opened in `12.0.1`), Live flags the file as created by a
   newer version and halts parsing.
3. **Backward-Compatibility Mapping:** When modifying XML manually or
   programmatically, changing `MinorVersion` alone often isn't enough. If a
   newer patch introduced or modified XML nodes (such as changes to device chain
   parameters, audio routing nodes, or rack structures), `SchemaChangeCount`
   tells Live's parser which migration/compatibility transformation rules to
   apply during deserialization.


##### Practical Implications for Custom Serializers

If you are constructing or modifying `.als` files via automated tools or custom
serialization libraries:

* **Strict Match Requirements:** Live's XML parser will throw a version mismatch
  error if `SchemaChangeCount` doesn't align with the expects of that build's
  parser—even if all element tags are structurally valid.

* **Downgrading Hacks:** When manually modifying an `.als` file to open in a
  slightly older point release of the same major version, both `MinorVersion`
  and `SchemaChangeCount` generally need to be spoofed to match a valid `.als`
  generated by the target build.


## Where a track's audio is

A track's audio is in three places:

| Where | Path to the clips |
| --- | --- |
| The session view | `DeviceChain/MainSequencer/ClipSlotList/ClipSlot/ClipSlot/Value/AudioClip` |
| The arrangement | `DeviceChain/MainSequencer/Sample/ArrangerAutomation/Events/AudioClip` |
| The take lanes | `TakeLanes/TakeLane/ClipAutomation/Events/AudioClip` |

The same file can be referenced from more than one of them, so the number of
clips is not the number of files.

An `<AudioClip>` is not always inside a `<ClipSlot>`. Live 12 moved most of
them into the arrangement and the take lanes.

See `lib/live_set/model/live_audio_track.rb`.


## Every place holds its own clip

A place a clip is in holds the whole clip, not a reference to a clip that is
held somewhere else. There is no pool of clips in a set, and nothing points
into one.

The Session View and the Arrangement View each hold their own clips: the manual
says they "each hold individual collections of clips" ([Live
Concepts](https://www.ableton.com/en/manual/live-concepts/)), and a Session clip
copied into the Arrangement is an independent Arrangement clip.

The set that is checked in shows it. The clip `3-Kontakt 7 1` is written out as
nine complete `MidiClip` elements, eight of them with the same forty-seven
`MidiNoteEvent` elements and one with nineteen. The audio clip
`Pink Noise - EDMtips.com` is written out as eleven complete `AudioClip` elements,
each with its own `Id` and its own `SampleRef`. The set has 22 `AudioClip`
elements in all.

What is referenced rather than copied is the sample. The audio of a set is in
files beside the set, and each clip points at the file in its `SampleRef`.
Several clips can point at the same file, and each can play it differently —
reversed, warped differently, trimmed — without touching the file. The notes of
a MIDI clip are in the element, so they are copied along with it.

`LomId` is the identifier the Live Object Model uses while Live is running. It
is `0` in the elements of a saved set, and it is not a key that ties the copies
of a clip together.

So a report that says how many places a clip is in is counting the clips in
the file that are alike — the same name, the same file, the same colour and the
same state. That grouping is the report's own; the format does not make it.
The legend the report writes still describes references; see **N57** in
`TODO.md`.


## The colour of a track or a clip

Live writes the colour of a track or a clip as a number, in a `Color` element,
and the number is an index into the colour menu of Live:

```text
<Color Value="1" />
```

The palette is the user's: it can be changed in the Preferences of Live, and
the number means whatever the user's palette says it means. The default
palette is in `lib/live_set/model/live_palette.rb`, in the order of the menu.

The tooltip of a name in a report carries the number, so that the colour of a
thing can be looked up in the palette the reader has.


## The sample references of a clip

A clip that plays a file refers to it through `SampleRef/FileRef`:

| Element            | What it holds                                                    |
| ------------------ | ---------------------------------------------------------------- |
| `RelativePath`     | The path of the file relative to the set's directory             |
| `Path`             | The absolute path of the file                                    |
| `Type`             | How the file is referenced                                       |
| `OriginalFileSize` | The size of the file, in bytes. Live 8 wrote `FileSize` instead. |
| `LastModDate`      | When the file was last modified, as a Unix timestamp             |

Either path may be empty, meaning the file is not in the project folder. The
relative path is the one to use: the absolute path is a fallback for a clip
that has no relative path.

The reference is to the file on disk, not to a clip. See "Every place holds
its own clip".

The size Live records is the size of the source file as Live saw it, and it
is sometimes zero even though the file exists and is not empty. The size on
disk is used in that case.

Several clips can refer to the same file, and each can play it differently —
reversed, warped differently, trimmed — without touching the file. So the size
of a set counts each file once, and it is not the sum of the sizes of the
clips.

See `lib/live_set/model/live_audio_clip.rb`.


## Where a file comes from

Two paths name a file of a set, and they say different things.

The **relative path** says where the file is in the project. A relative path
that does not begin with `..` resolves within the set, and every other path
points outside it.

The **absolute path** says where the file was when the set was saved, and it
says which pack the file came from. The content of a pack is under a folder of
its own — `Samples`, `Sounds`, `IRs`, `Devices`, `Racks`, `Presets` — and the
pack is the folder above it:

| The absolute path                      | What it is                          |
| -------------------------------------- | ----------------------------------- |
| `.../Drive and Glow/Samples/Loops/...` | a file of the pack `Drive and Glow` |
| `.../User Library/Samples/...`         | a file of the user library of Live  |
| `.../Core Library/Samples/...`         | a file of the Core Library of Live  |

The libraries of Live are not packs: they come with Live, and they are there
for every set. A pack is sold separately, and it has to be installed for the
files of it to be found.

The absolute path can be stale. A set made by Ableton holds the paths of the
machine it was built on — `/Volumes/data/tmp/trunk/Core Library/...` — and the
relative path is the one that says where the file is now.

See `lib/live_set/model/live_origin.rb`.


## The set file is a gzip file

A set is a gzipped XML document, and the gzip header holds the time the file
was compressed. Two files with the same content can therefore have different
bytes: a set that was recompressed has the same content and a different file.

So a hash of the file and a hash of the content are different things, and a
report that is evidence carries both. File hash says that nothing in
the file has changed. XML hash says that the material of the
set has not changed, however it was compressed.


## Whether a sample has been collected

A clip is collected when its audio file was copied into the project's
`Samples/Imported/` folder — that is, when its relative path starts with
`Samples/Imported/`. A clip with no relative path is by definition not
collected: it is a MIDI clip, or it is linked by an absolute path.

The size in the XML is the size of the source file as Live saw it, and it is
sometimes zero even though the file exists and is not empty. The size on disk
is used in that case.

## The warp mode of a sample

A clip that plays a file has a `WarpMode` element, and the number in it says
which algorithm Live applies to the clip. The numbers are the numbers of the
modes in the manual of Live, section 9.3, "Warp Modes":

| `WarpMode` | Warp mode   | What it is for                                                                                  |
| ---------- | ----------- | ----------------------------------------------------------------------------------------------- |
| 0          | Beats       | Slicing rhythmic material at its transients, such as drums and loops                            |
| 1          | Tones       | Granular processing for clear, sustained monophonic pitch, such as vocals and basslines         |
| 2          | Texture     | Granular processing for polyphonic, ambient or noisy textures, such as pads and soundscapes     |
| 3          | Re-Pitch    | Speed changes alter both the pitch and the tempo at once, as a turntable or a tape stretch does |
| 4          | Complex     | A composite algorithm, for whole mixed tracks, dense layers or polyphonic samples               |
| 5          | Complex Pro | The advanced composite algorithm, with the formant and envelope controls                        |

The manual is at
https://www.ableton.com/en/live-manual/12/audio-clips-tempo-and-warping/#warp-modes

The mode is written on every clip that plays a file, and it is the mode the
clip was saved with, whether the clip was warped or not: a clip that is not
warped is in Beats mode.

The granularity of a clip is written next to the mode, and it is what the
mode uses: `GranularityTones` is the grain of the Tones mode, and
`GranularityTexture` and `FluctuationTexture` are the grain and the
fluctuation of the Texture mode. A clip in any other mode carries the
default values of all three.

See `lib/live_set/serializer/live_audio_clip_serializer.rb`, which reports the mode of
a clip by its name and its number.

See `lib/live_set/model/live_audio_clip.rb`.


## The devices of a chain, and the plug-ins among them

The devices in a chain are the children of `DeviceChain/DeviceChain/Devices`.
Each device is its own element: `Eq8`, `GlueCompressor`, `Limiter`, `Saturator`,
and so on. A plug-in is a `PluginDevice`.

A native Ableton device is never a `PluginDevice` — it is its own element, and
the P3S has all of them. Every plug-in in the corpus is
third-party, though the file does not say so: there is no `Manufacturer` element
anywhere.

A plug-in's name is in a different place depending on the plug-in format:

| Format | Where the name is                   |
| ------ | ----------------------------------- |
| VST2   | `PluginDesc/VstPluginInfo/PlugName` |
| VST3   | `PluginDesc/Vst3PluginInfo/Name`    |

Both shapes are in real sets, and the VST3 shape has no `PlugName` at all.

A Max for Live device is a child of a `Devices` element of its own kind, and
the name of the element says what it is:

| Element               | What it is                       |
| --------------------- | -------------------------------- |
| `MxDeviceAudioEffect` | a Max for Live audio effect      |
| `MxDeviceMidiEffect`  | a Max for Live MIDI effect       |
| `MxDeviceInstrument`  | a Max for Live instrument        |

These are the class names of the Live Object Model. The name of the device is
inside the element, and says nothing about what the device is: there are
hundreds of Max for Live devices, and the element is what they all have in
common. No device of the corpus has a `Manufacturer` element.

Max for Live is supported on the Push 3 Standalone, but with less headroom, so
a Max for Live device is advice and not an error: the set can be transferred,
and a device that overloads the P3S has to be frozen away.

See `lib/live_set/model/live_device.rb`.


## The device chain, and the chains nested inside it

The path to the top-level `Devices` element is doubled: the track's
`DeviceChain` contains a `DeviceChain`, which contains `Devices`.

A chain can be nested. An `AudioEffectGroupDevice` holds a group's device chain
in its branches, and a `DrumGroupDevice` holds a drum rack, so a track's real
devices can be several levels down. Every device in the chain is found, at any
depth.

The container devices themselves are not devices that process audio — they hold
devices that do — so they are not reported. But the devices they hold are,
because those are the devices that actually run.

See `lib/common/xml.rb`, `Xml#xml_chain_devices`.


## The 'Ableton Project Info' folder

Live writes a folder of that name in the folder of the project, and the folder of a set is
usually the folder of the project. Live gets confused when it finds one in a parent folder of
the folder of the project: it may load the project from the wrong place.

The folders are a fact about the machine the report is made on, and not about the set, so the
report says what it found and what it means, and the warnings are logged as well. The report
has a section, `## The Ableton Project Info Folder`, that lists the warnings.

This matters in a test environment, where a project is run from wherever it was unpacked: a
project that was downloaded into a working directory tree can have an 'Ableton Project Info'
folder above it, and Live may not operate as expected when it loads the project from there.
It does not change the content of the report.

See `lib/live_set/model/live_project_info.rb`, and the section of the report with the same
name.


## Master/Main Track

The master track is a child of the set and not of the tracks of the set. Live 12+ writes
it as the `<MainTrack>` element.

There is only one master track per set; it is not a collection. The children of
a `<MasterTrack/>` are found this way:

```shell
$ pinkblanket="$songs/pink_blanket/daw/live/pink_blanket Project/pink_blanket.als"
$ als_nodes "$pinkblanket" //MainTrack --children | \
  jq -r '.[]' | \
  sort -u
ArrangementClipsListWrapper
AutomationEnvelopes
ClipSlotsListWrapper
Color
DeviceChain
DevicesListWrapper
IsContentSelectedInDocument
LinkedTrackGroupId
LomId
LomIdView
Name
PreferredContentViewMode
TakeLanes
TakeLanesListWrapper
TrackDelay
TrackGroupId
TrackUnfolded
ViewData
```

## Track Kinds

The `<Tracks>` element can hold four kinds of track elements, and it holds them
in the order Live they were created.

```shell
$ als_nodes "$pinkblanket" //Tracks --children | \
  jq -r '.[]' | \
  sort -u
AudioTrack
GroupTrack
MidiTrack
ReturnTrack
```


```xml
<LiveSet>
  <Tracks>
    <AudioTrack Id="8"> ... </AudioTrack>
    <MidiTrack Id="9"> ... </MidiTrack>
    <GroupTrack Id="76"> ... </GroupTrack>
    <ReturnTrack Id="80"> ... </ReturnTrack>
  </Tracks>
  <MasterTrack Id="81"> ... </MasterTrack>
</LiveSet>
```

A MIDI track holds MIDI clips and plays no file. An audio track plays files, and it can
hold MIDI clips as well. A return track receives the sends of the set and holds no clips.

The `<Tracks/>` element is a flat structure that does not employ nested
elements. Thus `GroupTrack`s are siblings of `AudioTrack`s and `MidiTrack`s.

The model has a class for each of these elements. See
[report_design.md](report_design.md), "The classes".


## Group Tracks

A group track is a summing container (a dedicated sub-mix bus), not a track that
plays clips.

A better English name would have been "Track Group". Ableton is based in Berlin,
Germany. The German Ableton documentation calls a Group Track a Gruppenspur.
Gruppe translates to "group", and spur translates to "track". Because standard
German compound nouns place the head word at the end, Gruppenspur literally
translates as "Group-Track," retaining "Track" as the primary noun while
denoting its grouping role.

Group tracks have their own device chain (`<DeviceChain/>`), `<Mixer/>`,
inserts, and routing, but they do not contain clip slots (`<ClipSlotList/>`).
Group tracks do not play audio/MIDI clips directly; instead, they reference
other tracks that play audio and MIDI clips.

Membership in a group track is logical, not physical. A member track's
`TrackGroupId` holds the `Id` of the group it belongs to, and `-1` means the
track is at the top level.

Another way to say this is: group tracks do not nest their children, instead,
all tracks are siblings and the group hierarchy is expressed by matching the
`GroupTrack` `Id` with a track's `TrackGroupId` child element, which looks like
this: `<TrackGroupId Value="15" />`.

Live 10 introduced nested groups. If a group is nested inside another group, the
child group tracks reference their parent group's `Id` via their `TrackGroupId`
element in the same manner.

The name of a group track is stored in the same elements as for regular tracks:
inside its <Name> element under <UserName Value="..."/> and <EffectiveName
Value="..."/>.

Group tracks use the same XML structure as audio and MIDI tracks, so a model
could use a base class for all track types.

```shell
$ als_nodes "$pinkblanket" //Tracks/GroupTrack --children | \
  jq -r '.[]' | \
  sort -u
ArrangementClipsListWrapper
AutomationEnvelopes
ClipSlotsListWrapper
Color
DeviceChain
DevicesListWrapper
Freeze
IsContentSelectedInDocument
LinkedTrackGroupId
LomId
LomIdView
Name
PreferredContentViewMode
Slots
TakeLanes
TakeLanesListWrapper
TrackDelay
TrackGroupId
TrackUnfolded
ViewData
```


### Linked Tracks

Tracks can be linked together so they can be operated on in unison in
arrangement view. This feature is unrelated to group tracks. The following
aspects of linked tracks can be modified all together in arrangment view: moving
and resizing clips, selecting, editing the time, splitting and consolidating,
the fades, arming and the take lanes.

Linking is done with the Link Tracks menu item, in the context menu of the head
of a track in the arrangement view. A track's `LinkedTrackGroupId` holds the
`Id` of the group of tracks it is linked to, and `-1` means it is not linked.

Linked track groups are not the same as session view groups, which are the
`TrackGroupId` in the previous section. A linked track group is a set of
tracks whose editing is locked together, wherever they are.

See "Linked-Track Editing" in the manual of Live 12, section 6.14:
https://www.ableton.com/en/live-manual/12/arrangement-view/#linked-track-editing

Every track of every set of the Ableton Live demo sets has `-1`, so of them
exercise a linked group.


### Group Device Chain

A group has a mixer and a device chain, and its members' audio is routed through
that chain: a member track's output is routed to `AudioOut/GroupTrack`.

A third-party plug-in in a group's chain therefore blocks a transfer to the P3S
just the same as a third-party plug-in on a MIDI or audio track.

Normally, a group track cannot be frozen, because only tracks that hold clips
can be frozen, and a group track normally holds no clips. `Options.txt` can
remove this restriction, as described in the next section.

Unless `Options.txt` allows frozen group tracks, third-party devices cannot be
rendered away by freezing the group. The remedy is to remove the device from the
group's chain, or to bounce the group to another track and then disable it.


## `Options.txt`

Ableton Live can be configured to enable experimental and unsupported features
through an `Options.txt` file in its Preferences folder. For example,
`-_GroupTrackFreeze` allows a group track to be bounced as though it were a
track.

TODO This might not be implemented properly:

`live_set` does not search for a file called `Options.txt`, and it just passes
unknown entities and attributes through when converting between ALS versions.

See `lib/live_set/model/live_group.rb`.


## Track TakeLlanes

Take lanes are subordinate to the track they belong to. Takes lane are in
`TakeLanes` elements, which hold the clips for each take of a track. The track
holds the composite clips which are the normal output of the track.

`TakeLane` elements are wrapped in
`<TakeLanes><TakeLanes></TakeLanes></TakeLanes>` elements:

```xml
<TakeLanes>
  <TakeLanes>
    <TakeLane Id="0">
      <LomId Value="0"/>
      <Height Value="51"/>
      <IsContentSelectedInDocument Value="false"/>
      <ClipAutomation>
        <Events>
          <MidiClip Id="0" Time="140.77"> ... </MidiClip>
        </Events>
      </ClipAutomation>
      <Name Value="Drift"/>
      <Annotation Value=""/>
      <Audition Value="false"/>
    </TakeLane>
  </TakeLanes>
  <AreTakeLanesFolded Value="true"/>
</TakeLanes>
```

- `TakeLane`: A take. Its `Id` numbers it, `Name` names it, and `Audition` says
  whether it is the take being auditioned.

- `ClipAutomation`: The clips of the take. They play into the chain of the track.

- `AreTakeLanesFolded`: Whether the lanes are shown expanded in the arrangement.

Live 12 take lanes also have an `ArrangementClipsListWrapper` element, which is
empty in the sets of the corpus.

**A take lane clip and the track clip are different.** When a section of a take
is comped into the track, Live writes a new clip element into the track, with
its own boundaries, and the clip in the lane stays as it was:

```xml
<MidiClip Id="0" Time="140.77">
  <CurrentStart Value="140.77"/>   <!-- where the section sits on the timeline -->
  <CurrentEnd Value="162.42"/>
  <Loop>
    <LoopStart Value="0.77"/>      <!-- where the section starts in the source -->
    <LoopEnd Value="22.42"/>
    <StartRelative Value="0"/>
    <LoopOn Value="false"/>
  </Loop>
  ...
</MidiClip>
```

The `CurrentStart` and `CurrentEnd` say where the clip sits on the timeline, and
the `LoopStart` and `LoopEnd` say which part of the source it plays. The source
is the file on disk for an audio clip, and the note data in the clip itself for
a MIDI clip.

Live 11 and Live 12 hold the take lanes the same way. The difference between
them is elsewhere: the clips of both carry `ScaleInformation`, which is what
Live 12 uses for the scale of the clip. The Live 11 demo set has 74 of them.

See `lib/live_set/serializer/live_take_lane_serializer.rb`, which reports the lanes of a
track under the track.


## Two Track Sequencers

A track that is frozen keeps two sequencers:

- `MainSequencer`: The editable material
- `FreezeSequencer`: The rendered audio cache that replaces it during playback

A frozen track's clips can be in either sequencer, and some are only in the
`FreezeSequencer`, so a reader that looks only at the `MainSequencer` finds
nothing. Both sequencers must be searched.

The freeze state of a track is its `<Freeze Value="true"/>` subelement.

See `lib/live_set/model/live_track_facts.rb`.


## Lane Types

Every set of a given Live version has the same lane types, but Live 11 and Live
12 do not have the same values.

TODO We have not figured this out yet. See
[live_11_12_diff.md](live_11_12_diff.md), "The lane types".
