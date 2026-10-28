require 'spec_helper'
require 'stringio'
require 'live_set/live_set_audio_clip'

RSpec.describe LiveAudioClip, '#show_clip' do
  around do |example|
    original_stdout = $stdout
    $stdout = StringIO.new
    example.run
  ensure
    $stdout = original_stdout
  end

  # Builds an <AudioClip> element, with or without a LastModDate.
  def clip_with(last_mod_date: '1707598944')
    lmd = last_mod_date ? "<LastModDate Value=\"#{last_mod_date}\"/>" : ''
    xml = <<~XML
      <AudioClip Id="0" Time="0">
        <SampleRef>
          <FileRef>
            <RelativePath Value="Samples/Imported/song.mp3"/>
            <OriginalFileSize Value="3626186"/>
          </FileRef>
          #{lmd}
        </SampleRef>
      </AudioClip>
    XML

    Nokogiri::Slop(xml).xpath('//AudioClip').first
  end

  context 'when the clip has a LastModDate' do
    it 'reports the time' do
      clip = described_class.new '/tmp', clip_with

      expect(clip.last_modified.strftime('%Y-%m-%d %H:%M:%S')).to eq('2024-02-10 21:02:24')
    end
  end

  context 'when the LastModDate is zero' do
    it 'has no time rather than the epoch' do
      clip = described_class.new '/tmp', clip_with(last_mod_date: '0')

      expect(clip.last_modified).to be_nil
    end

    it 'still shows the clip' do
      clip = described_class.new '/tmp', clip_with(last_mod_date: '0')

      expect(clip.show_clip.first).to include('song.mp3')
    end
  end

  context 'when the clip has no LastModDate' do
    it 'has no time rather than the epoch' do
      clip = described_class.new '/tmp', clip_with(last_mod_date: nil)

      expect(clip.last_modified).to be_nil
    end

    it 'still shows the clip' do
      clip = described_class.new '/tmp', clip_with(last_mod_date: nil)

      expect(clip.show_clip.first).to include('song.mp3')
    end
  end
end
