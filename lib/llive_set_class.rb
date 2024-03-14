require 'nokogiri'
require 'pathname'
require 'zlib'

class String
  def to_bool
    return true if casecmp('true').zero?
    return false if casecmp('false').zero?

    nil
  end
end

class LiveSet
  def initialize(set_name, **options)
    @loglevel  = "-loglevel #{options[:loglevel]}"
    @loglevel += ' -stats' unless options[:loglevel] == 'quiet'
    @overwrite = options[:force]
    @set_name = set_name
    @contents = Zlib::GzipReader.open(set_name, &:readlines)
    @xml_doc = Nokogiri::Slop @contents.join("\n")

    @ableton = @xml_doc.Ableton
    @minor_version = @ableton['MinorVersion']
  end

  def show
    check_ableteon_project_info
    puts <<~END_SHOW
      #{@set_name}
        Created by #{@ableton['Creator']}
        Major version #{@ableton['MajorVersion']}
        Minor version v#{@minor_version}
        SchemaChangeCount #{@ableton['SchemaChangeCount']}
        Revision #{@ableton['Revision']}
    END_SHOW

    tracks = @ableton.LiveSet.Tracks.AudioTrack
    track_msg = if tracks.empty?
                  'No tracks'
                else
                  all_frozen = all_tracks_frozen(tracks)
                  track_summary(tracks) +
                    tracks.map { |x| show_track x, all_frozen }.join("\n  ")
                end
    puts track_msg
  end

  def modify_als
    if @minor_version.start_with? '11.'
      puts 'The Live set is already compatible with Live 11.'
      exit
    end

    @ableton['Creator'] = 'Ableton Live 11.3.21'
    @ableton['MajorVersion'] = '5'
    @ableton['MinorVersion'] = '11.0_11300'
    @ableton['Revision'] = '5ac24cad7c51ea0671d49e6b4885371f15b57c1e'
    @ableton['SchemaChangeCount'] = '3'

    ['//ContentLanes', '//ExpressionLanes', '//InstrumentMeld', '//Roar', '//MxPatchRef'].each do |element|
      @xml_doc.xpath(element).remove
    end
    new_contents = @xml_doc.to_xml.to_s
    new_contents.gsub! 'AudioOut/Main', 'AudioOut/Master'

    set_path = File.dirname @set_name
    new_set_name = File.basename @set_name, '.als'
    new_set_path = File.join set_path, "#{new_set_name}_11.als"
    if @overwrite
      puts "Overwriting existing #{new_set_path}"
      File.delete new_set_path
    else
      puts "Writing #{new_set_path}"
    end
    Zlib::GzipWriter.open(new_set_path) { |gz| gz.write new_contents }
  end

  private

  def all_tracks_frozen(tracks)
    tracks.all? { |track| track_is_frozen track }
  end

  def check_ableteon_project_info
    set_directory = File.realpath(File.dirname(@set_name))
    api_path = File.join(set_directory, 'Ableton Project Info')
    puts "Warning: '#{api_path}' is not present".red unless File.exist? api_path
    puts "Warning: '#{api_path}' is not a directory".red unless Dir.exist? api_path

    cur_dir = Pathname.new(api_directory).parent
    while cur_dir
      if File.exist? File.join(cur_dir, 'Ableton Project Info')
        puts "Warning: 'Ableton Project Info' exists in parent directory '#{cur_dir.to_path}'".red
      end
      break if cur_dir.to_path == '/'

      cur_dir = cur_dir.parent
    end
  end

  def track_is_frozen(track)
    track.Freeze['Value'].to_bool
  end

  def track_summary(tracks)
    all_frozen_msg = all_tracks_frozen(tracks) ? ' (All are frozen)' : ''
    "#{tracks.count} tracks#{all_frozen_msg}:\n  "
  end

  def show_track(audio_track, all_frozen)
    name = audio_track.Name.EffectiveName['Value']
    frozen = !all_frozen && track_is_frozen(audio_track) ? ' **frozen**' : ''
    "#{name}#{frozen}"
  end
end
