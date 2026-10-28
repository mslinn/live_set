require 'spec_helper'
require 'tmpdir'
require 'zlib'

RSpec.describe XsdFromXml do
  # A minimal Ableton Live set. The schema this generates is described in xsd_builder_spec.rb.
  #
  # @return [String] the XML of the set
  def simple_set
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <Ableton MajorVersion="5" MinorVersion="12.0_12000" SchemaChangeCount="3" Creator="Ableton Live 12.4d1" Revision="abc123">
        <LiveSet>
          <NextPointeeId Value="260122"/>
        </LiveSet>
      </Ableton>
    XML
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

  # Runs a block with its output suppressed.
  #
  # @yield the block to run
  # @return [void]
  def silence_output
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  describe '.run' do
    after { ENV.delete('LIVE_SET_TEST_DIR') }

    it 'writes a schema file' do
      Dir.mktmpdir do |dir|
        schema_path = File.join(dir, 'schema.xsd')
        set_path = write_set(dir, 'set.als', simple_set)

        silence_output { described_class.run([schema_path, set_path]) }

        expect(File).to exist(schema_path)
      end
    end

    it 'refuses to overwrite an existing schema' do
      Dir.mktmpdir do |dir|
        schema_path = File.join(dir, 'schema.xsd')
        File.write(schema_path, 'original content')
        set_path = write_set(dir, 'set.als', simple_set)

        expect { silence_output { described_class.run([schema_path, set_path]) } }
          .to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }

        expect(File.read(schema_path)).to eq('original content')
      end
    end

    it 'overwrites an existing schema when --force is given' do
      Dir.mktmpdir do |dir|
        schema_path = File.join(dir, 'schema.xsd')
        File.write(schema_path, 'original content')
        set_path = write_set(dir, 'set.als', simple_set)

        silence_output { described_class.run(['--force', schema_path, set_path]) }

        expect(File.read(schema_path)).to include('<xs:schema')
      end
    end

    it 'exits with an error when a set file does not exist' do
      Dir.mktmpdir do |dir|
        schema_path = File.join(dir, 'schema.xsd')

        expect { silence_output { described_class.run([schema_path, File.join(dir, 'missing.als')]) } }
          .to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }

        expect(File).not_to exist(schema_path)
      end
    end

    it 'exits with an error when the sets have different root elements' do
      Dir.mktmpdir do |dir|
        schema_path = File.join(dir, 'schema.xsd')
        first = write_set(dir, 'first.als', simple_set)
        second = write_set(dir, 'second.als', simple_set.sub('<Ableton', '<Other'))

        expect { silence_output { described_class.run([schema_path, first, second]) } }
          .to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      end
    end

    it 'expands environment variables in the schema file name' do
      Dir.mktmpdir do |dir|
        schema_path = File.join(dir, 'schema.xsd')
        set_path = write_set(dir, 'set.als', simple_set)
        ENV['LIVE_SET_TEST_DIR'] = dir

        silence_output { described_class.run(['$LIVE_SET_TEST_DIR/schema.xsd', set_path]) }

        expect(File).to exist(schema_path)
      end
    end
  end
end
