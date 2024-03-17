# ALS Filetype Notes

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
    365                         <SourceContext />
    366                         <SampleUsageHint Value="0" />
    367                         <DefaultDuration Value="10809120" />
    368                         <DefaultSampleRate Value="48000" />
    369                       </SampleRef>
```


```text
@audiotrack = LiveSet.Tracks.AudioTrack.
  DeviceChain.MainSequencer.ClipSlotList.ClipSlot.children.
    ClipSlot.Value.children. # Passed to LiveAudioClip
      SampleRef.FileRef
        Path['Value']  # Absolute path
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
