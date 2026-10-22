require 'bytesize'
require 'fileutils'
require 'nokogiri'
require 'ostruct'
require 'tmpdir'

require 'live_set'

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
