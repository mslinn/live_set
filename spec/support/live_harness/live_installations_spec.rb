require 'spec_helper'
require 'live_installations'

RSpec.describe LiveInstallations do
  # A temporary directory to hold a fake installation.
  let(:root) { Dir.mktmpdir }

  after { FileUtils.remove_entry root }

  # Builds a fake installation in the temporary directory.
  def make_installation(name, executable: true, demo_songs: true)
    path = File.join root, name
    FileUtils.mkdir_p path
    if executable
      FileUtils.mkdir_p File.join(path, 'Program')
      File.write File.join(path, 'Program', "Ableton #{name}.exe"), ''
    end
    if demo_songs
      songs = File.join(path, 'Resources', 'Core Library', 'Lessons', 'Demo Songs')
      FileUtils.mkdir_p songs
      File.write File.join(songs, 'demo.als'), ''
    end
    path
  end

  describe '.installation_at' do
    it 'reads the version from the directory name' do
      path = make_installation 'Live 11 Suite'

      expect(described_class.installation_at(path).version).to eq('11')
    end

    it 'reads the edition from the directory name' do
      path = make_installation 'Live 11 Suite'

      expect(described_class.installation_at(path).edition).to eq('Suite')
    end

    it 'reads a version with more than one part' do
      path = make_installation 'Live 12.4 Suite'

      installation = described_class.installation_at path

      expect(installation.version).to eq('12.4')
    end

    it 'is nil for a directory that is not an installation' do
      path = make_installation 'Something Else'

      expect(described_class.installation_at(path)).to be_nil
    end

    it 'finds the executable' do
      path = make_installation 'Live 11 Suite'

      installation = described_class.installation_at path

      expect(installation.executable).to eq(File.join(path, 'Program', 'Ableton Live 11 Suite.exe'))
    end

    it 'finds the demo songs' do
      path = make_installation 'Live 11 Suite'

      installation = described_class.installation_at path

      expect(installation.demo_songs).to end_with('Demo Songs')
    end

    it 'has no executable when there is none' do
      path = make_installation 'Live 11 Suite', executable: false

      installation = described_class.installation_at path

      expect(installation.executable).to be_nil
    end
  end

  describe '.installations_under' do
    it 'finds the installations in a directory' do
      make_installation 'Live 11 Suite'
      make_installation 'Live 12 Suite'

      versions = described_class.installations_under(root).map(&:version)

      expect(versions).to contain_exactly('11', '12')
    end

    it 'finds nothing in an empty directory' do
      expect(described_class.installations_under(root)).to be_empty
    end
  end

  describe '.version' do
    it 'finds the installation of a version' do
      make_installation 'Live 11 Suite'
      make_installation 'Live 12 Suite'

      installation = described_class.version('11', [root])

      expect(installation.version).to eq('11')
    end

    it 'is nil for a version that is not installed' do
      expect(described_class.version('9', [root])).to be_nil
    end
  end

  describe '.demo_sets' do
    it 'lists the demo sets of an installation' do
      make_installation 'Live 11 Suite'
      installation = described_class.version('11', [root])

      sets = described_class.demo_sets installation

      expect(sets.length).to eq(1)
      expect(sets.first).to end_with 'demo.als'
    end

    it 'is empty for an installation with no demo songs' do
      make_installation 'Live 11 Suite', demo_songs: false
      installation = described_class.version('11', [root])

      expect(described_class.demo_sets(installation)).to be_empty
    end
  end

  describe '.preferences' do
    it 'finds the preferences folder for a version under a custom root' do
      path = File.join(root, 'Ableton', 'Live 11.3.43', 'Preferences')
      FileUtils.mkdir_p path

      expect(described_class.preferences('11', [root])).to eq(path)
    end

    it 'is nil when there is no matching preferences folder' do
      expect(described_class.preferences('99', [root])).to be_nil
    end
  end
end
