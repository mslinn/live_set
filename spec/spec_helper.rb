require 'bytesize'
require 'fileutils'
require 'nokogiri'
require 'ostruct'
require 'tmpdir'

require 'live_set'

# A stand-in for a LiveAudioClip. Only the methods that the reporting code calls
# are needed.
FakeClip = Struct.new(:file_size)

# Builds a Slop-decorated document containing a single AudioTrack.
#
# @param clip_slots [String] the inner XML of the <ClipSlotList> element
# @param freeze [String] the value of the track's <Freeze> element
# @return [Nokogiri::XML::Element] the AudioTrack element
def audio_track_element(clip_slots: '', freeze: 'false')
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
              </MainSequencer>
            </DeviceChain>
          </AudioTrack>
        </Tracks>
      </LiveSet>
    </Ableton>
  XML

  Nokogiri::Slop(xml).xpath('//AudioTrack').first
end

# Builds a <ClipSlot> element in the Live 8 (nested) or Live 12 (flat) layout.
#
# @param nested [Boolean] true for the Live 8 layout, false for Live 12
# @param id [String] the ClipSlot's Id attribute
# @param relative_path [String] the sample's path relative to the set directory
# @return [String] the XML of a <ClipSlot> element
def clip_slot_xml(nested:, id: '14', relative_path: 'Samples/Imported/song1.mp3')
  payload = <<~XML
    <AudioClip Id="0" Time="0">
      <SampleRef>
        <FileRef>
          <RelativePath Value="#{relative_path}"/>
          <Path Value="E:/media/#{relative_path}"/>
          <Type Value="1"/>
          <OriginalFileSize Value="3626186"/>
        </FileRef>
        <LastModDate Value="1707598944"/>
      </SampleRef>
    </AudioClip>
  XML

  value = "<Value>#{payload}</Value>"
  inner = nested ? "<ClipSlot>#{value}</ClipSlot>" : value

  <<~XML
    <ClipSlot Id="#{id}">
      <LomId Value="0"/>
      #{inner}
    </ClipSlot>
  XML
end
