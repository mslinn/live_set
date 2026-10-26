require 'bytesize'
require 'fileutils'
require 'nokogiri'
require 'ostruct'
require 'stringio'
require 'tmpdir'

# Require the code in this repository, not an installed gem of the same name.
#
# The repository's version and the installed gem's version can be the same, so a plain
# `require 'live_set'` may pick up the installed one. `rake install` installs this repository's
# code, so the two are the same; but the spec should test this repository either way.
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'live_set'

# The fixture sets reference sample files that are intentionally not present. Keep their
# diagnostic output out of the specs that only inspect clip metadata.
def silence_stdout
  original_stdout = $stdout
  $stdout = StringIO.new
  yield
ensure
  $stdout = original_stdout
end

# A stand-in for a LiveAudioClip. Only the methods that the reporting code calls are needed.
FakeClip = Struct.new(:file_size, :absolute_path) do
  def collected?
    true
  end

  def show_clip
    ['    sample.wav', human_file_size(file_size).rjust(8, ' '), '2024-01-01 00:00:00']
  end
end

# A stand-in for a LiveTrack, for testing LiveTracks.
FakeTrack = Struct.new(:name, :distinct_clips, :blocking_devices, :device_summary) do
  def frozen?
    false
  end
end

# A stand-in for a LiveAudioClip, for testing LiveTracks.
FakeTrackClip = Struct.new(:absolute_path, :collected?)

# A stand-in for a LiveDevice, for testing LiveTracks.
FakeDevice = Struct.new(:label)

# A stand-in for a LiveGroup, for testing LiveTracks.
#
# TODO Rename FakeGroup to FakeTrackGroup, to match LiveTrackGroup. The name is
# currently FakeGroup because the spec_helper.rb file is loaded by
# spec/live_track_spec.rb, which tests LiveTracks, not LiveGroups.
#
# The FakGroup mentioned in docs/als_work.md is unrelated to this FakeGroup. The docs/als_work.md FakeGroup is a stand-in for a LiveGroupTrack, for testing the als_work.rb code.
#
# The field is called member_tracks rather than members, because Struct#members already exists.
FakeGroup = Struct.new(:name, :blocking_devices, :member_tracks) do
  def device_summary
    ''
  end

  # The tracks in the group.
  def members
    member_tracks || []
  end

  # The name of a track.
  def track_name(track)
    track.at('Name/EffectiveName')&.[]('Value') || track.at('Name/UserName')&.[]('Value')
  end
end

# Builds a Slop-decorated document containing a single AudioTrack.
#
# @param clip_slots [String] the inner XML of the <ClipSlotList> element
# @param freeze [String] the value of the track's <Freeze> element
# @param arrangement_clips [String] the inner XML of the arrangement's <Events> element
# @param take_lane_clips [String] the inner XML of the take lane's <Events> element
# @return [Nokogiri::XML::Element] the AudioTrack element
def audio_track_element(clip_slots: '', freeze: 'false', arrangement_clips: '', take_lane_clips: '')
  xml = <<~XML
    <Ableton>
      <LiveSet>
        <Tracks>
          <AudioTrack Id="3">
            <Name><EffectiveName Value="Test Track"/></Name>
            <Freeze Value="#{freeze}"/>
            <DeviceChain>
              <MainSequencer>
                <ClipSlotList>
    #{clip_slots}
                </ClipSlotList>
                <Sample>
                  <ArrangerAutomation>
                    <Events>
    #{arrangement_clips}
                    </Events>
                  </ArrangerAutomation>
                </Sample>
              </MainSequencer>
            </DeviceChain>
            <TakeLanes>
              <TakeLanes>
                <TakeLane Id="1">
                  <ClipAutomation>
                    <Events>
    #{take_lane_clips}
                    </Events>
                  </ClipAutomation>
                </TakeLane>
              </TakeLanes>
            </TakeLanes>
          </AudioTrack>
        </Tracks>
      </LiveSet>
    </Ableton>
  XML

  Nokogiri::Slop(xml).xpath('//AudioTrack').first
end

# Builds a Slop-decorated document containing a single AudioTrack whose audio is in the
# FreezeSequencer rather than the MainSequencer.
#
# A frozen track keeps both sequencers. The MainSequencer holds the editable material, and the
# FreezeSequencer holds the rendered audio cache. Some frozen tracks hold their clips only in the
# FreezeSequencer, so a reader that looks only at the MainSequencer finds nothing.
#
# See docs/als_format.md section 11.
#
# @param clip_slots [String] the inner XML of the FreezeSequencer's <ClipSlotList> element
# @param arrangement_clips [String] the inner XML of the arrangement's <Events> element
# @return [Nokogiri::XML::Element] the AudioTrack element
def frozen_track_element(clip_slots: '', arrangement_clips: '')
  xml = <<~XML
    <Ableton>
      <LiveSet>
        <Tracks>
          <AudioTrack Id="4">
            <Name><EffectiveName Value="Frozen Track"/></Name>
            <Freeze Value="true"/>
            <DeviceChain>
              <MainSequencer>
                <ClipSlotList>
                </ClipSlotList>
              </MainSequencer>
              <FreezeSequencer>
                <ClipSlotList>
    #{clip_slots}
                </ClipSlotList>
                <Sample>
                  <ArrangerAutomation>
                    <Events>
    #{arrangement_clips}
                    </Events>
                  </ArrangerAutomation>
                </Sample>
              </FreezeSequencer>
            </DeviceChain>
          </AudioTrack>
        </Tracks>
      </LiveSet>
    </Ableton>
  XML

  Nokogiri::Slop(xml).xpath('//AudioTrack').first
end

# Builds a Slop-decorated document containing a single GroupTrack.
#
# A group track is a summing container. It has no clips, and its Slots are empty. Its DeviceChain
# has no MainSequencer, only a FreezeSequencer. See docs/als_format.md section 9.
#
# @param id [String] the group's Id attribute
# @param name [String] the group's name
# @param devices [String] the inner XML of the group's <Devices> element
# @return [Nokogiri::XML::Element] the GroupTrack element
def group_track_element(id: '34', name: 'Test Group', devices: '')
  xml = <<~XML
    <Ableton>
      <LiveSet>
        <Tracks>
          <GroupTrack Id="#{id}">
            <Name><EffectiveName Value="#{name}"/></Name>
            <TrackGroupId Value="-1"/>
            <Freeze Value="false"/>
            <Slots>
              <GroupTrackSlot><LomId Value="0"/></GroupTrackSlot>
            </Slots>
            <DeviceChain>
              <Mixer>
                <Sends/>
                <Pan Value="0"/>
                <Volume Value="0"/>
              </Mixer>
              <DeviceChain>
                <Devices>
    #{devices}
                </Devices>
              </DeviceChain>
              <FreezeSequencer>
                <ClipSlotList>
                  <ClipSlot><LomId Value="0"/><ClipSlot><HasStop Value="true"/></ClipSlot></ClipSlot>
                </ClipSlotList>
              </FreezeSequencer>
            </DeviceChain>
          </GroupTrack>
        </Tracks>
      </LiveSet>
    </Ableton>
  XML

  Nokogiri::Slop(xml).xpath('//GroupTrack').first
end

# Builds a track element that belongs to the given group.
#
# @param group_id [String] the Id of the group the track belongs to
# @return [Nokogiri::XML::Element] the AudioTrack element
def track_with_group(group_id)
  xml = "<AudioTrack Id=\"1\"><TrackGroupId Value=\"#{group_id}\"/></AudioTrack>"
  Nokogiri::Slop(xml).xpath('//AudioTrack').first
end

# Builds a track element that belongs to a group and is routed to it.
#
# A member track's output is routed to its group, so the group's devices process its audio.
#
# @param name [String] the track's name
# @param group_id [String] the Id of the group the track belongs to
# @param target [String] where the track's output is routed
# @return [Nokogiri::XML::Element] the AudioTrack element
def member_track_element(name: 'Member', group_id: '34', target: 'AudioOut/GroupTrack')
  xml = <<~XML
    <AudioTrack Id="1">
      <Name><EffectiveName Value="#{name}"/></Name>
      <TrackGroupId Value="#{group_id}"/>
      <DeviceChain>
        <AudioOutputRouting><Target Value="#{target}"/></AudioOutputRouting>
      </DeviceChain>
    </AudioTrack>
  XML
  Nokogiri::Slop(xml).xpath('//AudioTrack').first
end

# Builds a <PluginDevice> element holding a VST3 plug-in.
#
# A VST3 plug-in has no PlugName. Its name is at PluginDesc/Vst3PluginInfo/Name. See
# docs/als_format.md section 8.
#
# @param name [String] the plug-in's name
# @return [String] the XML of a <PluginDevice> element
def plugin_device_xml(name: 'OTT')
  <<~XML
    <PluginDevice Id="6">
      <LomId Value="0"/>
      <Name Value=""/>
      <UserName Value=""/>
      <PluginDesc>
        <Vst3PluginInfo Id="0">
          <WinPosX Value="47"/>
          <NumAudioInputs Value="1"/>
          <NumAudioOutputs Value="1"/>
          <IsPlaceholderDevice Value="false"/>
          <Preset><Vst3Preset/></Preset>
          <Name Value="#{name}"/>
          <DeviceType Value="2"/>
        </Vst3PluginInfo>
      </PluginDesc>
    </PluginDevice>
  XML
end

# Builds a <PluginDevice> element holding a VST2 plug-in.
#
# A VST2 plug-in's name is at PluginDesc/VstPluginInfo/PlugName. See docs/als_format.md section 8.
#
# @param name [String] the plug-in's name
# @return [String] the XML of a <PluginDevice> element
def vst2_plugin_device_xml(name: 'MAutoPitch')
  <<~XML
    <PluginDevice Id="7">
      <LomId Value="0"/>
      <Name Value=""/>
      <UserName Value=""/>
      <PluginDesc>
        <VstPluginInfo Id="0">
          <Path Value="C:/Program Files/VstPlugins/#{name}.dll"/>
          <PlugName Value="#{name}"/>
          <UniqueId Value="1298232660"/>
        </VstPluginInfo>
      </PluginDesc>
    </PluginDevice>
  XML
end

# Builds an <AudioClip> element.
#
# @param id [String] the AudioClip's Id attribute
# @param relative_path [String] the sample's path relative to the set directory
# @param file_size [String] the value of the OriginalFileSize attribute
# @return [String] the XML of an <AudioClip> element
def audio_clip_xml(id: '0', relative_path: 'Samples/Imported/song1.mp3', file_size: '3626186')
  <<~XML
    <AudioClip Id="#{id}" Time="0">
      <LomId Value="0"/>
      <Name Value="Clip #{id}"/>
      <SampleRef>
        <FileRef>
          <RelativePath Value="#{relative_path}"/>
          <Path Value="E:/media/#{relative_path}"/>
          <Type Value="1"/>
          <OriginalFileSize Value="#{file_size}"/>
        </FileRef>
        <LastModDate Value="1707598944"/>
      </SampleRef>
    </AudioClip>
  XML
end

# Builds a <ClipSlot> element holding an <AudioClip>, in the nested layout that every real set uses.
#
# @param id [String] the ClipSlot's Id attribute
# @param relative_path [String] the sample's path relative to the set directory
# @return [String] the XML of a <ClipSlot> element
def clip_slot_xml(id: '14', relative_path: 'Samples/Imported/song1.mp3')
  <<~XML
    <ClipSlot Id="#{id}">
      <LomId Value="0"/>
      <ClipSlot>
        <Value>
          #{audio_clip_xml(relative_path: relative_path)}
        </Value>
      </ClipSlot>
    </ClipSlot>
  XML
end
