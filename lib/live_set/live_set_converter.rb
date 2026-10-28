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
  LIVE_12_ONLY = ['//InstrumentMeld', '//Roar', '//MxPatchRef', '//ReturnTrack',
                   '//ArrangementClipsListWrapper', '//TakeLanesListWrapper',
                   '//SessionScrollPos'].freeze

  # These are Live 12 attributes that Live 11 does not have. They record which panel of the
  # device chain is selected, and are not part of the sound of the set.
  LIVE_12_ONLY_ATTRIBUTES = ['SelectedToolPanel', 'SelectedTransformationName',
                              'SelectedGeneratorName'].freeze

  # Live 11 has no curve control on a FloatEvent. It has it on a PerNoteEvent instead, and a
  # FloatEvent that has it in Live 12 loses it in the conversion.
  LIVE_12_ONLY_FLOAT_ATTRIBUTES = ['CurveControl1X', 'CurveControl1Y', 'CurveControl2X',
                                    'CurveControl2Y'].freeze

  # These elements are empty in Live 11 and have content in Live 12.
  EMPTY_IN_LIVE_ELEVEN = ['//TimeAndValueTransforms', '//SendsPre'].freeze

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
    LIVE_12_ONLY.each do |element|
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

    floats = @xml_doc.xpath('//FloatEvent[@CurveControl1X or @CurveControl1Y or ' \
                             '@CurveControl2X or @CurveControl2Y]')
    floats.each do |float|
      LIVE_12_ONLY_FLOAT_ATTRIBUTES.each do |attribute|
        float.remove_attribute(attribute) if float.attribute(attribute)
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
    empty_time_and_value_transforms
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
