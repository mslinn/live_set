# Serializes an AlsModel as a markdown report.
class AlsModelSerializer
  # Creates a serializer for the given ALS model.
  #
  # @param als_model [AlsModel] the model to serialize
  def initialize(als_model)
    @als_model = als_model
  end

  # Returns the complete ALS model as markdown.
  #
  # @return [String] the serialized markdown for the entire ALS model
  def to_markdown
    header_block_section      = LiveHeaderSerializer.new(@als_model.live_set).to_markdown
    p3s_compatibility_section = P3SCompatibility
                                .new(@als_model.live_set)
                                .to_markdown
    hierarchical_entities     = LiveGroupTrack.new(@als_model).to_markdown
    missing_samples =   '' # TODO: generate markdown for missing samples
    device_track_xref = '' # TODO: generate markdown for Device/Track Cross-Reference
    track_clip_xref =   '' # TODO: generate markdown for Track / Clip Cross Reference

    <<~REPORT_END
      #{header_block_section}
      #{p3s_compatibility_section}
      #{hierarchical_entities}
      #{missing_samples}
      #{device_track_xref}
      #{track_clip_xref}
    REPORT_END
  end
end
