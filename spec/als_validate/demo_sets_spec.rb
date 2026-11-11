require 'spec_helper'
require 'live_set/demo_sets'
require 'support/schemas'

# Every demo set of a Live version has to validate against the schema generated from the demo
# sets of that version. A schema generated from a single set is stricter than Live is, and
# rejects the other sets of the same version.
#
# The largest demo set of a version is the one that is checked. It holds the most of everything
# Ableton writes, so a schema that is too strict rejects it.
#
# The schemas are checked in to the repository of the reference sets, so every developer has
# them. The versions that are checked are the ones DemoSets reports, so a version of Live that
# is installed is checked without a change to this file. See docs/als_work.md, "XSD Schemas".
RSpec.describe AlsValidate, 'the demo sets of each Live version' do # rubocop:disable RSpec/DescribeMethod
  # The schemas of the Live versions, as { live version => path of the schema }.
  #
  # A schema is named after the version of Live that wrote the sets it was generated from, so
  # "Ableton Live 11.3d1" gives live_11.3d1.xsd. The version of a demo set as DemoSets reports
  # it drops the suffix, so "11.3d1" is reported as "11.3".
  let(:schemas) do
    Dir.glob(File.join(Schemas::DIRECTORY, 'live_*.xsd')).to_h do |path|
      [File.basename(path)[/live_(.+)\.xsd/, 1], path]
    end
  end

  # The largest demo set of each version, as { live version => path of the set }.
  let(:demo_sets) do
    DemoSets.all.transform_values { |sets| sets.max_by { |path| File.size(path) } }
  end

  # The schema of a Live version.
  #
  # @param version [String] the Live version, e.g. "11.3"
  # @return [String, nil] the path of the schema
  def schema_for(version)
    schemas.find { |schema_version, _path| schema_version.start_with?(version) }&.last
  end

  it 'validates the largest demo set against the schema of its own version' do
    demo_sets.each do |version, set_path|
      schema = schema_for(version)
      require_fixture "the schema of Live #{version}", schema

      document = Nokogiri::XML(Zlib::GzipReader.open(set_path, &:read))
      xsd = Nokogiri::XML::Schema(File.read(schema))

      expect(xsd.validate(document)).to be_empty, "the demo set of Live #{version} does not validate"
    end
  end

  it 'validates a demo set the way the command does' do
    version, set_path = demo_sets.first
    schema = schema_for(version)
    require_fixture "the schema of Live #{version}", schema

    expect(silence_output { described_class.new(set_path, schema).validate }).to be_empty
  end
end
