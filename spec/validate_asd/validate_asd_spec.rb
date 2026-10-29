require 'spec_helper'
require 'tmpdir'
require 'zlib'

# The validation of a Live set against an XSD schema.
#
# The examples call the library, not the command. The command is a shell around this code: it
# parses the arguments, calls the validator, and prints what the validator returned.
#
# The files the examples use are real files: a real gzipped set, and a real schema. A file that
# is not what it was said to be raises, because that is a different kind of failure from a set
# that does not conform to the schema.
RSpec.describe ValidateAsd do
  # A minimal Ableton Live set.
  #
  # @return [String] the XML of the set
  def simple_set
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <Ableton>
        <LiveSet/>
      </Ableton>
    XML
  end

  # A schema that describes the set above.
  #
  # @return [String] the XML of the schema
  def simple_schema
    <<~XSD
      <?xml version="1.0" encoding="UTF-8"?>
      <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
        <xs:element name="Ableton">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="LiveSet"/>
            </xs:sequence>
          </xs:complexType>
        </xs:element>
      </xs:schema>
    XSD
  end

  # Writes a Live set to a file, gzipped the way Ableton Live stores them.
  #
  # @param dir [String] the directory to write the file in
  # @param name [String] the name of the file
  # @param xml [String] the XML of the set
  # @return [String] the path of the file
  def write_set(dir, name, xml)
    path = File.join(dir, name)
    File.open(path, 'wb') do |file|
      Zlib::GzipWriter.wrap(file) { |gz| gz.write(xml) }
    end
    path
  end

  describe '#validate' do
    context 'when the Live set conforms to the schema' do
      it 'returns no errors' do
        Dir.mktmpdir do |dir|
          set_path = write_set(dir, 'set.als', simple_set)
          schema_path = File.join(dir, 'schema.xsd')
          File.write(schema_path, simple_schema)

          errors = described_class.new(set_path, schema_path).validate

          expect(errors).to be_empty
        end
      end
    end

    context 'when the Live set does not conform to the schema' do
      it 'returns an error for each thing that does not conform' do
        Dir.mktmpdir do |dir|
          set_path = write_set(dir, 'set.als', simple_set.sub('<LiveSet/>', '<Unexpected/>'))
          schema_path = File.join(dir, 'schema.xsd')
          File.write(schema_path, simple_schema)

          errors = described_class.new(set_path, schema_path).validate

          expect(errors.length).to eq(1)
        end
      end

      it 'names the element that does not conform' do
        Dir.mktmpdir do |dir|
          set_path = write_set(dir, 'set.als', simple_set.sub('<LiveSet/>', '<Unexpected/>'))
          schema_path = File.join(dir, 'schema.xsd')
          File.write(schema_path, simple_schema)

          errors = described_class.new(set_path, schema_path).validate

          expect(errors.first.message).to include('Unexpected')
        end
      end

      it 'gives the line the error is on' do
        Dir.mktmpdir do |dir|
          set_path = write_set(dir, 'set.als', simple_set.sub('<LiveSet/>', '<Unexpected/>'))
          schema_path = File.join(dir, 'schema.xsd')
          File.write(schema_path, simple_schema)

          errors = described_class.new(set_path, schema_path).validate

          expect(errors.first.line).to be > 0
        end
      end
    end

    context 'when the schema is not an XSD file' do
      it 'says the file is not an XSD file' do
        Dir.mktmpdir do |dir|
          set_path = write_set(dir, 'set.als', simple_set)
          not_a_schema = File.join(dir, 'not_a_schema.xsd')
          File.write(not_a_schema, 'this is not a schema')

          expect { described_class.new(set_path, not_a_schema).validate }
            .to raise_error(ValidateAsd::InvalidInput, /is not an XSD file/)
        end
      end
    end

    context 'when the Live set is not gzip compressed' do
      it 'says the file is not an ALS file' do
        Dir.mktmpdir do |dir|
          set_path = File.join(dir, 'set.als')
          File.write(set_path, simple_set)
          schema_path = File.join(dir, 'schema.xsd')
          File.write(schema_path, simple_schema)

          expect { described_class.new(set_path, schema_path).validate }
            .to raise_error(ValidateAsd::InvalidInput, /is not an ALS file/)
        end
      end
    end

    context 'when the Live set is not valid XML' do
      it 'says the file is not an ALS file' do
        Dir.mktmpdir do |dir|
          set_path = write_set(dir, 'set.als', '<Ableton><LiveSet></Ableton>')
          schema_path = File.join(dir, 'schema.xsd')
          File.write(schema_path, simple_schema)

          expect { described_class.new(set_path, schema_path).validate }
            .to raise_error(ValidateAsd::InvalidInput, /is not an ALS file/)
        end
      end
    end

    context 'when the Live set has the wrong root element' do
      it 'names the root element it found' do
        Dir.mktmpdir do |dir|
          set_path = write_set(dir, 'set.als', '<NotAbleton/>')
          schema_path = File.join(dir, 'schema.xsd')
          File.write(schema_path, simple_schema)

          expect { described_class.new(set_path, schema_path).validate }
            .to raise_error(ValidateAsd::InvalidInput, /NotAbleton/)
        end
      end
    end
  end
end
