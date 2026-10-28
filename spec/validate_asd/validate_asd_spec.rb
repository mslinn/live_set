require 'spec_helper'
require 'stringio'
require 'tmpdir'
require 'zlib'

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

  # Runs the command, capturing what it prints and the status it exits with.
  #
  # @param args [Array<String>] the command line arguments
  # @return [Array(String, Integer)] the text the command printed, and the exit status
  def run_command(args)
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    status = 0
    begin
      described_class.run(args)
    rescue SystemExit => e
      status = e.status
    ensure
      output = $stdout.string + $stderr.string
      $stdout = original_stdout
      $stderr = original_stderr
    end
    [output, status]
  end

  describe '.run' do
    context 'when no arguments are given' do
      it 'explains that two file names are needed' do
        output, status = run_command([])

        expect(output).to include('An ALS file name and an XSD file name must be provided.')
        expect(status).to eq(1)
      end
    end

    context 'when only one argument is given' do
      it 'explains that two file names are needed' do
        Dir.mktmpdir do |dir|
          output, status = run_command([write_set(dir, 'set.als', simple_set)])

          expect(output).to include('An ALS file name and an XSD file name must be provided.')
          expect(status).to eq(1)
        end
      end
    end

    context 'when a third argument is given' do
      it 'rejects the extra argument' do
        Dir.mktmpdir do |dir|
          set_path = write_set(dir, 'set.als', simple_set)
          schema_path = File.join(dir, 'schema.xsd')
          File.write(schema_path, simple_schema)

          output, status = run_command([set_path, schema_path, set_path])

          expect(output).to include('Too many arguments.')
          expect(status).to eq(1)
        end
      end

      it 'does not validate the set' do
        Dir.mktmpdir do |dir|
          set_path = write_set(dir, 'set.als', simple_set)
          schema_path = File.join(dir, 'schema.xsd')
          File.write(schema_path, simple_schema)

          output, = run_command([set_path, schema_path, set_path])

          expect(output).not_to include('is valid')
        end
      end
    end

    context 'when a file does not exist' do
      it 'reports the missing Live set' do
        Dir.mktmpdir do |dir|
          schema_path = File.join(dir, 'schema.xsd')
          File.write(schema_path, simple_schema)

          output, status = run_command([File.join(dir, 'missing.als'), schema_path])

          expect(output).to include('missing.als')
          expect(output).to include('does not exist')
          expect(status).to eq(1)
        end
      end

      it 'reports the missing schema' do
        Dir.mktmpdir do |dir|
          set_path = write_set(dir, 'set.als', simple_set)

          output, status = run_command([set_path, File.join(dir, 'missing.xsd')])

          expect(output).to include('missing.xsd')
          expect(output).to include('does not exist')
          expect(status).to eq(1)
        end
      end
    end

    context 'when the schema is not an XSD file' do
      it 'says so' do
        Dir.mktmpdir do |dir|
          set_path = write_set(dir, 'set.als', simple_set)
          not_a_schema = File.join(dir, 'not_a_schema.xsd')
          File.write(not_a_schema, 'this is not a schema')

          output, status = run_command([set_path, not_a_schema])

          expect(output).to include('is not an XSD file.')
          expect(status).to eq(1)
        end
      end
    end

    context 'when the two file names are swapped' do
      it 'says the Live set is not an XSD file' do
        Dir.mktmpdir do |dir|
          set_path = write_set(dir, 'set.als', simple_set)
          schema_path = File.join(dir, 'schema.xsd')
          File.write(schema_path, simple_schema)

          output, status = run_command([schema_path, set_path])

          expect(output).to include('is not an XSD file.')
          expect(status).to eq(1)
        end
      end
    end

    context 'when the Live set is not gzip compressed' do
      it 'says so' do
        Dir.mktmpdir do |dir|
          set_path = File.join(dir, 'set.als')
          File.write(set_path, simple_set)
          schema_path = File.join(dir, 'schema.xsd')
          File.write(schema_path, simple_schema)

          output, status = run_command([set_path, schema_path])

          expect(output).to include('is not an ALS file.')
          expect(status).to eq(1)
        end
      end
    end

    context 'when the Live set is not valid XML' do
      it 'says so' do
        Dir.mktmpdir do |dir|
          set_path = write_set(dir, 'set.als', '<Ableton><LiveSet></Ableton>')
          schema_path = File.join(dir, 'schema.xsd')
          File.write(schema_path, simple_schema)

          output, status = run_command([set_path, schema_path])

          expect(output).to include('is not an ALS file.')
          expect(status).to eq(1)
        end
      end
    end

    context 'when the Live set has the wrong root element' do
      it 'says so' do
        Dir.mktmpdir do |dir|
          set_path = write_set(dir, 'set.als', '<NotAbleton/>')
          schema_path = File.join(dir, 'schema.xsd')
          File.write(schema_path, simple_schema)

          output, status = run_command([set_path, schema_path])

          expect(output).to include('is not an ALS file.')
          expect(output).to include('NotAbleton')
          expect(status).to eq(1)
        end
      end
    end

    context 'when the Live set conforms to the schema' do
      it 'reports that the set is valid' do
        Dir.mktmpdir do |dir|
          set_path = write_set(dir, 'set.als', simple_set)
          schema_path = File.join(dir, 'schema.xsd')
          File.write(schema_path, simple_schema)

          output, status = run_command([set_path, schema_path])

          expect(output).to include('is valid')
          expect(status).to eq(0)
        end
      end
    end

    context 'when the Live set does not conform to the schema' do
      it 'reports the errors' do
        Dir.mktmpdir do |dir|
          set_path = write_set(dir, 'set.als', simple_set.sub('<LiveSet/>', '<Unexpected/>'))
          schema_path = File.join(dir, 'schema.xsd')
          File.write(schema_path, simple_schema)

          output, status = run_command([set_path, schema_path])

          expect(output).to include('fails to validate')
          expect(status).to eq(1)
        end
      end
    end
  end
end
