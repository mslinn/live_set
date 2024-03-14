require 'nokogiri'
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
    @set_name = set_name
    @contents = Zlib::GzipReader.open(set_name, &:readlines)
    @xml_doc = Nokogiri::Slop @contents.join("\n")

    @ableton = @xml_doc.Ableton
    @minor_version = @ableton['MinorVersion']
  end

  def show
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

    @xml_doc.xpath('//ContentLanes').remove
    @xml_doc.xpath('//ExpressionLanes').remove

    new_contents = @xml_doc.to_xml.to_s
    new_contents.gsub! 'AudioOut/Main', 'AudioOut/Master'

    set_path = File.dirname @set_name
    new_set_name = File.basename @set_name, '.als'
    new_set_path = File.join set_path, "#{new_set_name}_11", '.als'
    puts "Writing #{new_set_path}"
    Zlib::GzipWriter.open(new_set_path) { |gz| gz.write new_contents }
  end

  private

  def all_tracks_frozen(tracks)
    tracks.all? { |track| track_is_frozen track }
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
