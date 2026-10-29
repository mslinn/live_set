require 'spec_helper'
require 'live_set/als_file'
require 'live_set/live_set_transformer'
require 'demo_sets'
require 'support/schemas'

# Converts a demo set of one Live version to the other, and validates the result against the
# schema of the version it was converted to.
#
# The schema of a version is generated from the XML stored in the sets of that version — the demo
# sets Ableton ships, and the sets Live wrote by converting a set of an older version — so it
# accepts every set of that version. A converted set that does not validate is not a set of that
# version.
#
# The schemas are not in the repository — .gitignore excludes *.xsd — so they are generated when
# they are missing. See spec/support/schemas.rb.
RSpec.describe LiveSetTransformer, 'converting a demo set' do
  # The demo set of a Live version.
  let(:live_12_set) { DemoSets.require!('12') }
  let(:live_11_set) { DemoSets.require_edition!('11', 'Suite') }

  # Converts a set, and returns the document of the converted set.
  #
  # @param path [String] the path of the set to convert
  # @return [Nokogiri::XML::Document] the converted set
  def convert(path)
    document = AlsFile.read(path)
    described_class.new(document).transform
    document
  end

  # The errors a document has against a schema.
  #
  # @param document [Nokogiri::XML::Document] the document
  # @param version [String] the Live version, e.g. "11"
  # @return [Array<String>] the messages of the errors
  def errors_against(document, version)
    schema = Nokogiri::XML::Schema(File.read(Schemas.path(version)))
    schema.validate(document).map(&:message)
  end

  # The distinct messages of the errors, each with the number of times it occurs.
  #
  # @param errors [Array<String>] the messages of the errors
  # @return [Array<String>] the distinct messages
  def distinct(errors)
    errors.tally.map { |message, count| "#{count} x #{message}" }
  end

  it 'converts a Live 12 set to Live 11, and the result is a Live 11 set' do
    converted = convert(live_12_set)

    expect(converted.root['MinorVersion']).to start_with '11.'
    errors = errors_against(converted, '11')
    expect(errors).to be_empty, -> { "the converted set does not validate:\n#{distinct(errors).join("\n")}" }
  end

  # The schema of a version is generated from the XML stored in the sets of that version, and a
  # schema inferred from too few sets is stricter than Live is: Live writes sets that the schema
  # of their own version rejects. The file Live 12 wrote is one of the sets the schema of Live 12
  # is inferred from, so the schema accepts it.
  it 'tells what Live itself wrote, when the schema of Live 12 rejects it' do
    live_12_written = AlsFile.read(DemoSets.require_converted!('11', 'Suite'))

    errors = errors_against(live_12_written, '12')
    expect(errors).to be_empty, -> { "the set Live 12 wrote does not validate:\n#{distinct(errors).join("\n")}" }
  end
end
