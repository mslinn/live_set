require 'colorator'
require_relative '../common/log'
require_relative 'als_file'

# Converts a Live set to the Live 11 format.
#
# The conversion rewrites the version strings, removes the constructs that Live 11 does not have,
# and rewrites the ones that Live 11 spells differently. Everything else is copied through
# unchanged.
#
# See docs/als_format.md sections 2.2 and 2.3.
class LiveSetConverter
  # The version strings are the Live 11.3.21 schema, and they are fixed rather than configurable.
  # A user can ask for "Live 11 format", but cannot ask for a particular sub-version, so every
  # set this command writes uses the same schema.
  CREATOR = 'Ableton Live 11.3.21'.freeze
  MAJOR_VERSION = '5'.freeze
  MINOR_VERSION = '11.0_11300'.freeze

  # Revision and SchemaChangeCount describe the file, not the live set. Live rewrites them every
  # time it saves a set, so two files holding the same set do not agree on them. There is nothing
  # to preserve here, so fixed values are written.
  #
  # They are excluded from any comparison of two live sets. See docs/cpfir.md, section 5.
  REVISION = '5ac24cad7c51ea0671d49e6b4885371f15b57c1e'.freeze
  SCHEMA_CHANGE_COUNT = '3'.freeze

  # These are Live 12 constructs that Live 11 does not have. Group tracks are not among them:
  # Live 11 has group tracks, so they are kept. See docs/als_format.md section 9.2.
  #
  # The conversion is a selective removal, not a rewrite. Anything else in the document — including
  # an element this list has never heard of — is copied through unchanged. See
  # docs/als_format.md section 2.2.
  LIVE_12_ONLY = ['//InstrumentMeld', '//Roar', '//ReturnTrack',
                  '//ArrangementClipsListWrapper', '//TakeLanesListWrapper',
                  '//MpePitchBendUsesTuning', '//BreakoutIsExpanded',
                  '//SelectedBreakpointValue', '//KeepRecordMonitoringLatency',
                  '//TransientEnvelopeModulationTarget', '//ComplexProFormantsModulationTarget',
                  '//ComplexProEnvelopeModulationTarget', '//SourceHint',
                  '//LocalFiltersJson', '//IsTuned', '//MpeTuningEnabled',
                  '//AudioOutputsListWrapper', '//AudioInputsListWrapper',
                  '//MidiOutputsListWrapper', '//MidiInputsListWrapper',
                  '//IsUndoable', '//MxDIntParameter', '//ControllerLayoutRemoteable',
                  '//ControllerLayoutCustomization', '//ShouldSceneTempoAndTimeSignatureBeVisible',
                  '//WaveformVerticalZoomFactor',
                  '//IsWaveformVerticalZoomActive',
                  '//AutomationEnvelopesListWrapper',
                  '//SelectedDocumentViewInMainWindow', '//DefaultGrooveId',
                  '//NoteProbabilityGroups', '//ProbabilityGroupIdGenerator',
                  '//TuningSystems', '//SamplesToAutoWarp', '//NoteAlgorithms',
                  '//ViewStateMainWindowClipDetailOpen',
                  '//ViewStateMainWindowHiddenOtherDocViewTypeClipDetailOpen',
                  '//ViewStateMainWindowHiddenOtherDocViewTypeDeviceDetailOpen',
                  '//ViewStateMainWindowDeviceDetailOpen',
                  '//ViewStateSecondWindowClipDetailOpen',
                  '//ViewStateSecondWindowDeviceDetailOpen'].freeze

  # Live 12 puts some elements inside a parent that Live 11 does not. Live 12 puts
  # <MidiControllerRange> inside <CrossFadeState>, and Live 11 puts it inside device
  # parameters. Removing such an element by name alone would also remove it from the places
  # Live 11 needs it, so these paths name the parent the element has to be removed from.
  LIVE_12_ONLY_IN_CONTEXT = ['//CrossFadeState/MidiControllerRange',
                             '//LiveSet/ViewStateArrangerMixerVolumeSectionHeight',
                             '//MidiClip/AccidentalSpellingPreference',
                             '//LiveSet/NoteSpellingPreference',
                             '//AudioClip/IsInKey',
                             '//AudioClip/ScaleInformation',
                             '//TimeSignature/MidiControllerRange',
                             '//GroovePool/GroovesListWrapper'].freeze

  # These elements are named differently in Live 11.
  #
  # The name of the ReWire target of a MIDI track changed, and so did the name of the width of a
  # mixer. The latter is spelled with a typo in Live 11, and the typo is part of the format.
  LIVE_ELEVEN_RENAMES = { 'ReWireDeviceMidiTargetId'              => 'ReWireSlaveMidiTargetId',
                          'ViewStateSessionTrackWidth'            => 'ViewStateSesstionTrackWidth',
                          'AutoColorPickerForReturnAndMainTracks' => 'AutoColorPickerForReturnAndMasterTracks',
                          'IsSongTempoLeader'                     => 'IsSongTempoMaster' }.freeze

  # These elements are named differently in Live 11, in the context they appear in. The same
  # element is named the same way in Live 12 elsewhere.
  LIVE_ELEVEN_CONTEXT_RENAMES = {
    '//ScaleInformation/Root'                            => 'RootNote',
    '//LiveSet/ViewStateSessionMixerVolumeSectionHeight' => 'ViewStateSessionMixerHeight',
    '//PatchSlot/Value/MxPatchRef'                       => 'MxDPatchRef',
  }.freeze

  # These are Live 12 attributes that Live 11 does not have. They record which panel of the
  # device chain is selected, and are not part of the sound of the set.
  LIVE_12_ONLY_ATTRIBUTES = %w[SelectedToolPanel SelectedTransformationName
                               SelectedGeneratorName].freeze

  # Live 11 writes the curve control of a note event every time, and Live 12 writes it only when
  # the curve is not the default. A note event that has no curve control in Live 12 gets the
  # default values in the conversion.
  LIVE_ELEVEN_CURVE_CONTROLS = %w[CurveControl1X CurveControl1Y CurveControl2X
                                   CurveControl2Y].freeze
  DEFAULT_CURVE_CONTROL = '0.5'.freeze

  # These elements are empty in Live 11 and have content in Live 12.
  EMPTY_IN_LIVE_ELEVEN = ['//TimeAndValueTransforms', '//SendsPre',
                          '//AudioSequencer/ClipSlotList', '//Mixer/Sends'].freeze

  # Live 11 writes a take lane without a LomId, and without an Id attribute.
  LIVE_12_ONLY_TAKE_LANE_ATTRIBUTES = ['Id'].freeze

  # @param set_name [String] the path of the set to convert
  # @param xml_doc [Nokogiri::XML::Document] the set to convert
  # @param overwrite [Boolean] whether an existing converted set may be overwritten
  def initialize(set_name, xml_doc, overwrite: false)
    @set_name = set_name
    @xml_doc = xml_doc
    @overwrite = overwrite
    @ableton = xml_doc.Ableton
  end

  # Converts the set, and writes the converted set next to the set that was converted.
  #
  # @return [void]
  def convert
    write_version_strings
    remove_live_12_elements
    remove_live_12_attributes
    translate_to_live_eleven
    write_conversion
  end

  private

  # Rewrites the version strings to those of a Live 11 set.
  def write_version_strings
    @ableton['Creator'] = CREATOR
    @ableton['MajorVersion'] = MAJOR_VERSION
    @ableton['MinorVersion'] = MINOR_VERSION
    @ableton['Revision'] = REVISION
    @ableton['SchemaChangeCount'] = SCHEMA_CHANGE_COUNT
  end

  # Removes the constructs that Live 11 does not have.
  def remove_live_12_elements
    (LIVE_12_ONLY + LIVE_12_ONLY_IN_CONTEXT).each do |element|
      count = @xml_doc.xpath(element).length
      @xml_doc.xpath(element).remove
      Log.debug "Removed #{count} element(s) matching #{element}" if count.positive?
    end
  end

  # Removes the attributes that Live 11 does not have.
  def remove_live_12_attributes
    tracks = @xml_doc.xpath('//*[@SelectedToolPanel or @SelectedTransformationName or ' \
                            '@SelectedGeneratorName]')
    tracks.each do |track|
      LIVE_12_ONLY_ATTRIBUTES.each do |attribute|
        track.remove_attribute(attribute) if track.attribute(attribute)
      end
    end
  end

  # Adds the curve control that Live 11 writes and Live 12 leaves out.
  #
  # Live 11 writes the four curve control attributes of every note event. Live 12 writes them
  # only when the curve is not the default, and so a note event without them has the default
  # curve.
  def add_note_event_curve_controls
    @xml_doc.xpath('//PerNoteEvent').each do |note|
      LIVE_ELEVEN_CURVE_CONTROLS.each do |attribute|
        next if note.attribute(attribute)

        note[attribute] = DEFAULT_CURVE_CONTROL
      end
    end
  end

  # Rewrites the elements that Live 12 and Live 11 spell differently.
  #
  # Three things changed between the versions, and all three were confirmed by opening a Live 11
  # demo set in Live 12, saving it, and comparing the two files.
  #
  # **The lane element was renamed.** A lane is an `ExpressionLane` in Live 11 and a
  # `MidiEditorLaneModel` in Live 12. Apart from the name they are the same: the same `Id`
  # attribute, and the same `Type`, `Size` and `IsMinimized` children.
  #
  # **The `Oversampling` value was respelled.** A `Saturator`'s `Oversampling` is `"1"` or `"0"`
  # in Live 11, and `"true"` or `"false"` in Live 12. A `Pedal`'s `Oversampling` uses
  # `"true"`/`"false"` in both versions, so only a `Saturator`'s is rewritten.
  #
  # **The output target was renamed.** Live 12 routes to `"AudioOut/Main"` and Live 11 routes to
  # `"AudioOut/Master"`.
  #
  # See docs/als_format.md section 2.3.
  def translate_to_live_eleven
    translate_lane_names
    translate_oversampling_values
    translate_audio_out_targets
    translate_master_track
    translate_element_names
    translate_scroll_position
    empty_time_and_value_transforms
    add_live_eleven_freeze_elements
    add_need_refreeze
    remove_midi_take_lanes
    strip_take_lane_lom_ids
    remove_device_view_data
    remove_audio_track_tuning
    empty_mx_device_source_context
    empty_mx_device_id_ref_list
    move_midi_clip_scale_information
    add_midi_note_attributes
    add_note_event_curve_controls
    add_chooser_bar
  end

  # Renames the elements that Live 11 names differently.
  def translate_element_names
    LIVE_ELEVEN_RENAMES.each do |live_twelve_name, live_eleven_name|
      rename_elements("//#{live_twelve_name}", live_eleven_name)
    end

    LIVE_ELEVEN_CONTEXT_RENAMES.each do |path, live_eleven_name|
      rename_elements(path, live_eleven_name)
    end
  end

  # Renames the elements that match the given path.
  #
  # @param path [String] the path of the elements to rename
  # @param live_eleven_name [String] the name Live 11 gives them
  # @return [void]
  def rename_elements(path, live_eleven_name)
    elements = @xml_doc.xpath(path)
    elements.each { |element| element.name = live_eleven_name }
    Log.debug "Renamed #{elements.length} element(s) matching #{path} to #{live_eleven_name}" if elements.length.positive?
  end

  # Rewrites the scroll position of the set to the form Live 11 uses.
  #
  # Live 12 keeps the scroll position of the song master in an element of its own. Live 11 keeps
  # it in the song master values, so the element is wrapped in them.
  def translate_scroll_position
    scroll = @xml_doc.at_xpath('//LiveSet/SessionScrollPos')
    return unless scroll

    values = Nokogiri::XML::Node.new('SongMasterValues', @xml_doc)
    position = Nokogiri::XML::Node.new('SessionScrollerPos', @xml_doc)
    position['X'] = scroll['X']
    position['Y'] = scroll['Y']
    values.add_child(position)
    scroll.add_next_sibling(values)
    scroll.remove
    Log.debug 'Converted the scroll position to the Live 11 form'
  end

  # Removes the view data of a device.
  #
  # Live 11 keeps the view data of a track, but not the view data of a device.
  def remove_device_view_data
    @xml_doc.xpath('//ViewData').each do |view_data|
      next unless view_data.parent.at_xpath('./SourceContext')

      view_data.remove
      Log.debug 'Removed the view data of a device'
    end
  end

  # Removes the tuning of an audio track.
  #
  # Live 11 tunes MIDI tracks, and does not tune audio tracks.
  def remove_audio_track_tuning
    @xml_doc.xpath('//AudioTrack/IsTuned').remove
  end

  # Adds the elements that Live 11 writes and Live 12 does not.
  #
  # Live 11 describes a track's freeze state with three elements, and Live 12 with only the last
  # of them. The two that Live 12 dropped are written with the values that Live 11 gives a track
  # that is not frozen.
  def add_live_eleven_freeze_elements
    @xml_doc.xpath('//*[PostProcessFreezeClips]').each do |track|
      freeze = track.xpath('./PostProcessFreezeClips').first
      freeze.add_previous_sibling(live_eleven_element('VelocityDetail', '0'))
      freeze.add_previous_sibling(live_eleven_element('NeedArrangerRefreeze', 'true'))
    end
  end

  # Removes the take lanes of a MIDI track.
  #
  # Live 11 has take lanes on audio tracks only, and the MIDI track of a Live 11 set has an empty
  # one. A MIDI track in Live 12 can have take lanes, and they are dropped by the conversion.
  def remove_midi_take_lanes
    @xml_doc.xpath('//MidiTrack/TakeLanes/TakeLanes').each do |lanes|
      count = lanes.element_children.length
      lanes.element_children.remove
      Log.debug "Removed #{count} take lane(s) from a MIDI track" if count.positive?
    end
  end

  # Removes the LomId element of a take lane.
  #
  # Live 12 gives every take lane a LomId. Live 11 does not.
  def strip_take_lane_lom_ids
    @xml_doc.xpath('//TakeLane/LomId').remove
    @xml_doc.xpath('//TakeLane').each do |lane|
      LIVE_12_ONLY_TAKE_LANE_ATTRIBUTES.each do |attribute|
        lane.remove_attribute(attribute) if lane.attribute(attribute)
      end
    end
  end

  # Builds an element of the Live 11 format.
  #
  # @param name [String] the name of the element
  # @param value [String] the value of the element
  # @return [Nokogiri::XML::Node] the element
  def live_eleven_element(name, value)
    element = Nokogiri::XML::Node.new(name, @xml_doc)
    element['Value'] = value
    element
  end

  # Adds the element that Live 11 writes to a clip slot and Live 12 does not.
  #
  # Live 11 says that a clip slot needs a refreeze, and Live 12 leaves the question out.
  def add_need_refreeze
    @xml_doc.xpath('//ClipSlot[HasStop]').each do |slot|
      next if slot.at_xpath('./NeedRefreeze')

      stop = slot.at_xpath('./HasStop')
      stop.add_next_sibling(live_eleven_element('NeedRefreeze', 'true'))
    end
  end

  # Empties the source context of an Mx device.
  #
  # Live 11 does not record where an Mx device came from, and Live 12 does.
  def empty_mx_device_source_context
    @xml_doc.xpath('//MxDeviceMidiEffect/SourceContext/Value | //MxDeviceAudioEffect/SourceContext/Value')
            .each { |value| value.element_children.remove }
  end

  # Empties the list of IDs of an Mx device.
  #
  # Live 11 keeps an empty list there, where Live 12 keeps the IDs of the patches of the device.
  def empty_mx_device_id_ref_list
    @xml_doc.xpath('//MxDeviceMidiEffect/IdRefList | //MxDeviceAudioEffect/IdRefList').each do |list|
      list.children.remove
      list.add_child(Nokogiri::XML::Node.new('IdRefList', @xml_doc))
    end
  end

  # Moves the scale of a MIDI clip to where Live 11 keeps it.
  #
  # Live 12 keeps the scale of a MIDI clip with the clip itself, and Live 11 keeps it with the
  # settings of the note editor, at the end of the clip.
  def move_midi_clip_scale_information
    %w[ScaleInformation IsInKey].each do |name|
      @xml_doc.xpath("//MidiClip/#{name}").each do |element|
        clip = element.parent
        target = clip.at_xpath('./NoteSpellingPreference') || clip.at_xpath('./ExpressionGrid')
        next unless target

        element.remove
        target.add_previous_sibling(element)
      end
    end
  end

  # Adds the attributes that Live 11 writes on a MIDI note and Live 12 does not.
  #
  # Live 12 keeps the probability of a note in the probability groups of the clip, and Live 11
  # keeps it on the note itself. A note that Live 12 does not put in a group always plays.
  def add_midi_note_attributes
    defaults = { 'VelocityDeviation' => '0', 'Probability' => '1', 'IsEnabled' => 'true' }
    @xml_doc.xpath('//MidiNoteEvent').each do |note|
      defaults.each do |name, value|
        note[name] = value unless note.attribute(name)
      end
    end
  end

  # Adds the element that Live 11 writes to the set and Live 12 does not.
  #
  # Live 11 writes the state of the chooser bar, and Live 12 does not.
  def add_chooser_bar
    live_set = @xml_doc.at_xpath('//LiveSet')
    return unless live_set
    return if live_set.at_xpath('./ChooserBar')

    chooser_bar = live_eleven_element('ChooserBar', '0')
    annotation = live_set.at_xpath('./Annotation')
    if annotation
      annotation.add_previous_sibling(chooser_bar)
    else
      live_set.add_child(chooser_bar)
    end
  end

  # Renames the master track element to the name Live 11 uses.
  def translate_master_track
    @xml_doc.xpath('//MainTrack').each do |track|
      track.name = 'MasterTrack'
      Log.debug 'Renamed a MainTrack to MasterTrack'
    end
  end

  # Empties the elements that Live 11 has empty.
  def empty_time_and_value_transforms
    EMPTY_IN_LIVE_ELEVEN.each do |element|
      @xml_doc.xpath(element).each { |node| node.children.remove }
    end
  end

  # Renames the lane elements to the name Live 11 uses.
  def translate_lane_names
    lanes = @xml_doc.xpath('//ContentLanes/MidiEditorLaneModel | //ExpressionLanes/MidiEditorLaneModel')
    lanes.each do |lane|
      lane.name = 'ExpressionLane'
      Log.debug 'Renamed a MidiEditorLaneModel to ExpressionLane'
    end
  end

  # Rewrites a `Saturator`'s `Oversampling` value to the form Live 11 uses.
  def translate_oversampling_values
    @xml_doc.xpath('//Saturator/Oversampling').each do |oversampling|
      value = oversampling['Value']
      case value
      when 'true' then oversampling['Value'] = '1'
      when 'false' then oversampling['Value'] = '0'
      else
        Log.warn "Leaving an unrecognized Oversampling value #{value.inspect} as it is"
      end
    end
  end

  # Rewrites the output target to the name Live 11 uses.
  def translate_audio_out_targets
    @xml_doc.xpath('//Target[@Value="AudioOut/Main"]').each do |target|
      target['Value'] = 'AudioOut/Master'
      Log.debug 'Renamed an AudioOut/Main target to AudioOut/Master'
    end
  end

  # Writes the converted set next to the set that was converted.
  #
  # An existing set is not overwritten unless the user asks for it. The gzip writer truncates the
  # file it opens, so without this check a conversion would silently destroy the previous result.
  #
  # The set is written the way Live writes it, so that the converted set is a Live 11 set and not
  # merely XML that happens to mean the same thing.
  #
  # @return [void]
  def write_conversion
    set_path = File.dirname @set_name
    new_set_name = File.basename @set_name, '.als'
    new_set_path = File.join set_path, "#{new_set_name}_11.als"

    if File.exist? new_set_path
      abort "Error: #{new_set_path} already exists. Use -f to overwrite it." unless @overwrite

      puts "Overwriting existing #{new_set_path}".green
    else
      puts "Writing #{new_set_path}".green
    end

    AlsFile.write(new_set_path, @xml_doc, File.mtime(@set_name))
    puts 'Conversion complete'.green
  end
end
