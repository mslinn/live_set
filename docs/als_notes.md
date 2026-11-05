# ALS Filetype Notes

This document contains details of the Ableton Live Set (ALS) file format. This
is a WHAT document that discusses XML fragments and how they morph between Live
versions. The HOW-TO document (discussing how the work is performed) is
[als_work.md](als_work.md). The differences between two Live versions are in a
version_diff document; the one for Live 11 and Live 12 is
[live_11_12_diff.md](live_11_12_diff.md). The terms these documents use are
defined in [glossary.md](glossary.md).

The ALS format changes with every Ableton Live release. The `live_set` project
is designed to handle structural differences in ALS files, such as an element
name that was renamed, or elements that exist in one version but not in another.

The headings are what the code cites. This document was written as
`docs/als_format.md`, which was split into this document (the format itself)
and a version_diff document (the differences between two versions); the section
numbers the old document carried are gone, and the headings are cited instead.


## The version_diff documents

Each version_diff document holds the differences between two adjacent versions
of Live. It opens with the release notes of the newer version, because every
difference is something the newer version changed, and then it holds the format
differences that follow from them.

| Document | The versions |
| --- | --- |
| [`live_8_9_diff.md`](live_8_9_diff.md) | Live 8 and Live 9 |
| [`live_9_10_diff.md`](live_9_10_diff.md) | Live 9 and Live 10 |
| [`live_10_11_diff.md`](live_10_11_diff.md) | Live 10 and Live 11 |
| [`live_11_12_diff.md`](live_11_12_diff.md) | Live 11 and Live 12 |

A difference belongs to the version that introduced it, so a difference between
Live 11 and Live 12 is in the Live 12 document, and not in the Live 10 and
Live 11 one. A fact that both versions share is not a difference at all: it is
a fact about the format, and it belongs in this document.


## ALS Schemas

TODO: Show the schemas for each version of the Ableton Live ALS format.
Use `exe/als_to_xsd` to generate the schemas and store them in `schemas/`.

The schema of a version is an *inference* from the XML stored in the sets of
that version, not a specification of it. A name the schema does not declare is
a name no set in the corpus uses, which is not the same as a name the version
does not have. See
[als_work.md](als_work.md), "Generate Each Schema From Every Set of That
Version".


## ALS Outlines

TODO: what version was the following taken from?

```xml
$ zcat '/mnt/e/media/Ableton/Projects/fu Project/fu.als' | less -N
      3   <LiveSet>
      8     <Tracks>
      9       <AudioTrack Id="8">
     44         <DeviceChain>
    247           <MainSequencer>
    278             <ClipSlotList>
    279               <ClipSlot Id="14">
    280                 <LomId Value="0" />
    281                 <ClipSlot>
    282                   <Value>
    283                     <AudioClip Id="0" Time="0">
    353                       <SampleRef>
    354                         <FileRef>
    355                           <RelativePathType Value="3" />
    356                           <RelativePath Value="Samples/Imported/song1.mp3" />
    357                           <Path Value="E:/media/Ableton/Projects/fu Project/Samples/Imported/song1.mp3" />
    358                           <Type Value="1" />
    359                           <LivePackName Value="" />
    360                           <LivePackId Value="" />
    361                           <OriginalFileSize Value="3626186" />  # Bytes
    362                           <OriginalCrc Value="47766" />
    363                         </FileRef>
    364                         <LastModDate Value="1707598944" />  # Epoch timestamp -> Sat Feb 10 16:02:24 EST 2024
    365                       </SourceContext>
    366                       <SampleUsageHint Value="0" />
    367                       <DefaultDuration Value="10809120" />
    368                       <DefaultSampleRate Value="48000" />
    369                     </SampleRef>
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


## Every value is stored in a `Value` attribute

Every value in an `.als` file is stored in a `Value` attribute:

```xml
<RelativePath Value="Samples/Imported/song1.mp3" />
```

This holds for every Live version from 8.2 to 12.4. It was verified against a
corpus of 460 sets.

An element that has no `Value` attribute, or an empty one, holds no value. An
empty attribute is not the same as an absent one:
`<RelativePath Value="" />` means the sample is not in the project folder, while
an absent `<RelativePath>` means the field is not in this version of the file.
`Xml#xml_value` yields `nil` for both, because every caller treats them alike.

A missing element means false. For example, an `AudioTrack` with no `<Freeze>`
element is not frozen. `Xml#xml_bool?` follows that convention for every
boolean it reads, and warns about a value that is neither `"true"` nor
`"false"` so that malformed data does not pass unnoticed.

See `lib/common/xml.rb`.


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

See `lib/live_set/model/live_track.rb`.


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
palette is in `lib/live_set/live_palette.rb`, in the order of the menu.

The tooltip of a name in a report carries the number, so that the colour of a
thing can be looked up in the palette the reader has.


## The sample references of a clip

A clip that plays a file refers to it through `SampleRef/FileRef`:

| Element | What it holds |
| --- | --- |
| `RelativePath` | The path of the file relative to the set's directory |
| `Path` | The absolute path of the file |
| `Type` | How the file is referenced |
| `OriginalFileSize` | The size of the file, in bytes. Live 8 wrote `FileSize` instead. |
| `LastModDate` | When the file was last modified, as a Unix timestamp |

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


## The set file is a gzip file

A set is a gzipped XML document, and the gzip header holds the time the file
was compressed. Two files with the same content can therefore have different
bytes: a set that was recompressed has the same content and a different file.

So a hash of the file and a hash of the content are different things, and a
report that is evidence carries both. The hash of the file says that nothing in
the file has changed. The hash of the content says that the material of the
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

| `WarpMode` | Warp mode | What it is for |
| --- | --- | --- |
| 0 | Beats | Slicing rhythmic material at its transients, such as drums and loops |
| 1 | Tones | Granular processing for clear, sustained monophonic pitch, such as vocals and basslines |
| 2 | Texture | Granular processing for polyphonic, ambient or noisy textures, such as pads and soundscapes |
| 3 | Re-Pitch | Speed changes alter both the pitch and the tempo at once, as a turntable or a tape stretch does |
| 4 | Complex | A composite algorithm, for whole mixed tracks, dense layers or polyphonic samples |
| 5 | Complex Pro | The advanced composite algorithm, with the formant and envelope controls |

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

See `lib/live_set/live_set_report.rb`, which reports the mode of a clip by
its name and its number.

See `lib/live_set/model/live_audio_clip.rb`.


## The devices of a chain, and the plug-ins among them

The devices in a chain are the children of `DeviceChain/DeviceChain/Devices`.
Each device is its own element: `Eq8`, `GlueCompressor`, `Limiter`, `Saturator`,
and so on. A plug-in is a `PluginDevice`.

A native Ableton device is never a `PluginDevice` — it is its own element, and
the Push 3 Standalone has all of them. Every plug-in in the corpus is
third-party, though the file does not say so: there is no `Manufacturer` element
anywhere.

A plug-in's name is in a different place depending on the plug-in format:

| Format | Where the name is |
| --- | --- |
| VST2 | `PluginDesc/VstPluginInfo/PlugName` |
| VST3 | `PluginDesc/Vst3PluginInfo/Name` |

Both shapes are in real sets, and the VST3 shape has no `PlugName` at all.

A Max for Live device is an `MxDeviceAudioEffect` for an audio effect and an
`MxDeviceMidiEffect` for a MIDI effect. Max for Live is supported on the Push 3
Standalone, but with less headroom, so it is treated separately from a
third-party plug-in.

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


## The kinds of track

The `<Tracks>` element of a set holds four kinds of track element, and it holds them in the
order Live wrote them:

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

The master track is a child of the set and not of the tracks of the set, and Live 12 writes
it as `<MainTrack>`.

The members of a group are not inside the group: they are siblings of it, and each of them
names its group in its `<TrackGroupId>`. The order of the elements of `<Tracks>` is the
order Live shows the tracks in, and the members of a group are among them.

A MIDI track holds MIDI clips and plays no file. An audio track plays files, and it can
hold MIDI clips as well. A return track receives the sends of the set and holds no clips.

The model has a class for each of these elements, and no class for "a track", because there
is no element for one. See [report_design.md](report_design.md), "The classes".

## The group tracks

A group track is a summing container, not a track that plays clips.

### A group track holds no clips

A group track has no `AudioClip` and no `MidiClip` anywhere inside it, and its
`Slots` are empty. It is therefore not reported alongside the tracks, and it
contributes no clips to any total.

### A member track names its group

A member track's `TrackGroupId` holds the `Id` of the group it belongs to, and
`-1` means the track is at the top level.

### Linked tracks

A track's `LinkedTrackGroupId` holds the `Id` of the group of tracks it is
linked to, and `-1` means it is linked to none. Linking is done with the Link
Tracks command, in the context menu of the head of a track in the arrangement
view: the editing of the tracks of a group is locked together, so that moving
and resizing the clips, selecting, editing the time, splitting and
consolidating, the fades, arming and the take lanes of one of them happen to all
of them at once.

The groups are not the groups of the session view, which are the `TrackGroupId`
above: a group of linked tracks is a set of tracks whose editing is locked
together, wherever they are.

See "Linked-Track Editing" in the manual of Live 12, section 6.14:
https://www.ableton.com/en/live-manual/12/arrangement-view/#linked-track-editing

Every track of every set of the corpus has `-1`, so nothing in the corpus
exercises a linked group.

### The device chain of a group

A group has a mixer and a device chain, and its members' audio is routed through
that chain: a member track's output is routed to `AudioOut/GroupTrack`. A
third-party plug-in in a group's chain therefore blocks a transfer to the Push 3
Standalone just as much as one on a track.

A group track cannot be frozen, because only tracks that hold clips can be
frozen, and a group track holds no clips. The device cannot be rendered away by
freezing the group, and freezing a member does not help either: a frozen
member stays routed into its group, so the group's device is still in the signal
path. The remedy is to remove the device from the group's chain, or to bounce
the group to another track and then disable it.

### Freezing a group track

A group track is frozen only when Live is configured to allow it. See "The
`Options.txt` hidden option", below.

### The `Options.txt` hidden option

Ableton Live can be configured to enable experimental and unsupported features
through an `Options.txt` file in its Preferences folder. For example,
`-_GroupTrackFreeze` allows a group track to be bounced as though it were a
track.

`live_set` does not search for a file called `Options.txt`, so it always reads a
group track as unfrozen.

See `lib/live_set/model/live_group.rb`.


## The take lanes of a track

A take lane holds the takes of a recording. The track holds the clips that are
heard — the composite that the takes were comped into — and the lanes hold the
takes themselves, so the lanes are subordinate to the track.

The lanes of a track are in a `TakeLanes` element of the track, and the
element is a container of `TakeLane` elements:

```text
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

| Element | What it holds |
| --- | --- |
| `TakeLane` | A take. Its `Id` numbers it, `Name` names it, and `Audition` says whether it is the take being auditioned. |
| `ClipAutomation` | The clips of the take. They play into the chain of the track. |
| `AreTakeLanesFolded` | Whether the lanes are shown expanded in the arrangement. |

A lane of Live 12 also has an `ArrangementClipsListWrapper` element, which is
empty in the sets of the corpus.

**The clip of a lane and the clip of the track are different clips.** When a
section of a take is comped into the track, Live writes a new clip element into
the track, with its own boundaries, and the clip in the lane stays as it was:

```text
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

See `lib/live_set/live_set_report.rb`, which reports the lanes of a track under
the track.


## The two sequencers of a track, and the frozen track that keeps both

A track that is frozen keeps both sequencers:

| Sequencer | What it holds |
| --- | --- |
| `MainSequencer` | The editable material |
| `FreezeSequencer` | The rendered audio cache that replaces it during playback |

A frozen track's clips can be in either sequencer, and some are only in the
`FreezeSequencer`, so a reader that looks only at the `MainSequencer` finds
nothing. Both have to be searched.

The freeze state of a track is its `<Freeze Value="true"/>` element.

See `lib/live_set/model/live_track.rb`.


## The lane types

Every set of a given Live version has the same lane types, but Live 11 and Live
12 do not have the same ones. A converted set therefore has to be given the lane
types of the version it is converted to. See
[live_11_12_diff.md](live_11_12_diff.md), "The lane types".


## The schema a converted set is written to

A converted set is written to a fixed schema of the target version, not to a
schema inferred from the XML stored in the sets of that version. The two are not
the same thing. See [live_11_12_diff.md](live_11_12_diff.md), "Converting a set
to Live 11 uses a fixed schema".
