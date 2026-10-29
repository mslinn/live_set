require 'spec_helper'
require 'demo_sets'

# Every demo set of a Live version has to validate against the schema generated from the demo
# sets of that version. A schema generated from a single set is stricter than Live is, and
# rejects the other sets of the same version.
#
# The largest demo set of a version is the one that is checked. It holds the most of everything
# Ableton writes, so a schema that is too strict rejects it.
#
# The schemas are checked in, so the examples run on a fresh clone. A version whose schema is
# not there has no example, and the examples are skipped. See docs/als_work.md, "XSD Schemas".
RSpec.describe ValidateAsd, 'the demo sets of each Live version' do # rubocop:disable RSpec/DescribeMethod
  # The directory the schemas are written to.
  let(:schema_dir) { File.expand_path('../../schemas', __dir__) }

  # The schemas, as { live version => path of the schema }.
  #
  # A schema is named after the version of Live that wrote the sets it was generated from, so
  # "Ableton Live 11.3d1" gives live_11.3d1.xsd. The version of a demo set as DemoSets reports
  # it drops the suffix, so "11.3d1" is reported as "11.3".
  let(:schemas) do
    Dir.glob(File.join(schema_dir, 'live_*.xsd')).to_h do |path|
      [File.basename(path)[/live_(.+)\.xsd/, 1], path]
    end
  end

  # The largest demo set of each version that has a schema, as { live version => path }.
  let(:demo_sets) do
    DemoSets.all.to_h do |version, sets|
      [version, schema_for(version) ? sets.max_by { |path| File.size(path) } : nil]
    end
  end

  # The schema of a Live version.
  #
  # @param version [String] the Live version, e.g. "11.3"
  # @return [String, nil] the path of the schema
  def schema_for(version)
    schemas.find { |schema_version, _path| schema_version.start_with?(version) }&.last
  end

  it 'validates the largest demo set against the schema of its own version' do
    checked = demo_sets.compact
    require_fixture 'a generated schema', schemas.values.first

    invalid = checked.reject do |version, set_path|
      document = Nokogiri::XML(Zlib::GzipReader.open(set_path, &:read))
      schema = Nokogiri::XML::Schema(File.read(schema_for(version)))
      schema.validate(document).empty?
    end

    expect(invalid).to be_empty
  end

  it 'validates a demo set the way the command does' do
    version, set_path = demo_sets.find { |_candidate, path| !path.nil? }
    require_fixture 'a generated schema', schemas.values.first

    expect(silence_output { described_class.new(set_path, schema_for(version)).validate }).to be_empty
  end
end
