require 'socket'
require 'time'
require_relative '../../common/log'
require_relative '../../common/xml'

# The facts about a set: the version of Live that wrote it, the computer it is on, where it
# is, and when it was made and last changed.
#
# Live writes no date of its own in a set, so the dates here are the dates of the files:
# the set, and the project folder it is in.
#
# not implemented: parsing of elements Automation, and the attributes of the Ableton element
# other than Creator, MinorVersion, Revision and SchemaChangeCount
class HeaderBlock
  include Xml

  # @param set_name [String] the path of the set
  # @param xml_doc [Nokogiri::XML::Document] the set
  # @param time_zone [String, nil] the time zone the times are written in
  def initialize(set_name, xml_doc, time_zone = nil)
    @set_name = set_name
    @xml_doc = xml_doc
    @time_zone = time_zone
    @ableton = xml_doc.at('Ableton')
  end

  # The version of Live that wrote the set.
  #
  # @return [String] the creator
  def creator
    @ableton['Creator']
  end

  # The version of Live that wrote the set.
  #
  # The creator of the set names the version of Live that wrote it: `Ableton Live 11.3d1`.
  # The version is the major and the minor version of Live, and the rest of the name — the
  # build, and the letters that follow it — says nothing about which version of Live it is.
  #
  # The `MinorVersion` attribute is Ableton's internal format number, and not the version of
  # Live a user sees. See docs/als_notes.md, "The `Creator` Attribute".
  #
  # @return [Array<Integer>, nil] the major and the minor version, or nil when the creator
  #   does not name a version
  def live_version
    match = creator.to_s.match(/Live (\d+)\.(\d+)/)
    return nil unless match

    [match[1].to_i, match[2].to_i]
  end

  # The format of the set.
  #
  # @return [String] the minor version
  def format
    @ableton['MinorVersion']
  end

  # The revision of the set.
  #
  # @return [String] the revision
  def revision
    @ableton['Revision']
  end

  # The number of changes of the schema of the set.
  #
  # @return [String] the count
  def schema_change_count
    @ableton['SchemaChangeCount']
  end

  # The directory the set is in.
  #
  # @return [String] the path of the directory
  def directory
    File.dirname File.expand_path(@set_name)
  end

  # The computer the report was made on: its name, and the hardware UUID of it.
  #
  # @return [String] the name of the computer
  def computer
    uuid = self.class.hardware_uuid
    uuid.empty? ? machine_name : "#{machine_name} (#{uuid})"
  end

  # The UUID of the machine, as Windows knows it.
  #
  # The registry of Windows holds it, and `reg.exe` reads it in a moment. The answer is the
  # same for every report of a process, so it is asked once.
  #
  # @return [String] the UUID, or an empty string when it cannot be found
  def self.hardware_uuid
    @hardware_uuid ||= `reg.exe query "HKLM\\SOFTWARE\\Microsoft\\Cryptography" /v MachineGuid 2>/dev/null`.split.last.to_s
  end

  # The machine the set is on.
  #
  # @return [String] the name of the machine
  def machine_name
    Socket.gethostname
  end

  # The time zone the times of the report are written in, and the offset that was in force on
  # the day the set was last modified.
  #
  # @return [String] the zone, and the offset
  def time_zone
    name = time_zone_name
    offset = utc_offset_at File.mtime(@set_name)
    offset ? "#{name} (UTC#{offset})" : name
  end

  # The name of the time zone the times of the report are written in.
  #
  # The times are written in the time zone of the computer unless another one is asked for.
  #
  # @return [String] the name of the zone
  def time_zone_name
    return @time_zone if @time_zone

    local_zone_name || Time.now.zone
  end

  # The name of the time zone of the computer.
  #
  # @return [String, nil] the name of the zone, or nil when it cannot be found
  def local_zone_name
    target = begin
      File.readlink '/etc/localtime'
    rescue SystemCallError
      nil
    end
    return nil unless target

    target.split('zoneinfo/').last
  end

  # The offset from UTC that was in force at a time, as it is written.
  #
  # @param time [Time] the time
  # @return [String, nil] the offset, or nil when it cannot be worked out
  def utc_offset_at(time)
    local = @time_zone ? time.getlocal(@time_zone) : time
    seconds = local.utc_offset
    return nil if seconds.zero? && @time_zone.nil?

    sign = seconds.negative? ? '-' : '+'
    hours = seconds.abs / 3600
    minutes = (seconds.abs % 3600) / 60
    minutes.zero? ? "#{sign}#{hours}" : "#{sign}#{hours}:#{format('%02d', minutes)}"
  end

  # The time the set was created.
  #
  # @return [String] the time
  def set_created
    created_at @set_name
  end

  # The time the set was created, as a time.
  #
  # @return [Time] the time
  def set_created_at
    creation_time(@set_name) || File.mtime(@set_name)
  end

  # The time the set was last written, as a time.
  #
  # @return [Time] the time
  def set_last_modified_at
    File.mtime @set_name
  end

  # The time the set was last written.
  #
  # @return [String] the time
  def set_last_modified
    format_time File.mtime(@set_name)
  end

  # The time the project folder was created.
  #
  # @return [String] the time
  def project_created
    created_at directory
  end

  # The time the project was last changed.
  #
  # The time of a folder is the time an entry was added to it or taken from it, and not the
  # time the work in it last changed. The project was last changed when the file in it that
  # was changed last was changed, and the file is named, so that the time can be explained.
  #
  # @return [String] the file, and the time it was changed
  def project_last_modified
    path, time = newest_file_of directory
    return format_time(File.mtime(directory)) unless path

    relative = path.delete_prefix("#{directory}/")
    "#{path_cell relative}<br>#{format_time time}"
  end

  # The file of a folder that was changed last.
  #
  # @param root [String] the folder
  # @return [Array] the path of the file and the time it was changed
  def newest_file_of(root)
    newest = nil
    Dir.glob(File.join(root, '**', '*'), File::FNM_DOTMATCH).each do |path|
      next unless File.file?(path)

      time = File.mtime path
      newest = [path, time] if newest.nil? || time > newest[1]
    end
    newest
  end

  # When the report was made, and what made it.
  #
  # @return [String] the time and the version
  def report_generated
    "#{format_time Time.now} by live_set v#{LiveSetVersion::VERSION}"
  end

  # A path, as a cell that can be broken where it has to be.
  #
  # The path is written in monospaced type, and a break is offered after each separator, so
  # that a long path does not make the table wider than the window.
  #
  # @param path [String] the path
  # @return [String] the cell
  def path_cell(path)
    "<code>#{path.gsub('/', '/<wbr/>')}</code>"
  end

  # A time, as the report writes it.
  #
  # The times are written in the time zone of the report, and without a time zone of their
  # own, because the zone is named at the top of the report.
  #
  # @param time [Time] the time
  # @return [String] the time
  def format_time(time)
    return time.strftime('%Y-%m-%d %H:%M:%S') unless @time_zone

    previous = ENV.fetch('TZ', nil)
    ENV['TZ'] = @time_zone
    time.getlocal.strftime('%Y-%m-%d %H:%M:%S')
  ensure
    ENV['TZ'] = previous
  end

  private

  # The time a file was created, as the machine that holds it says.
  #
  # A Windows drive mounted under WSL does not say when a file was created: the mount reports
  # the time the file was last changed, which is not the same thing. Windows itself knows, so
  # Windows is asked. Where the machine cannot say, the time the file was last written is used.
  #
  # @param path [String] the path of the file
  # @return [String] the time
  def created_at(path)
    format_time creation_time(path) || File.mtime(path)
  end

  # The time a file was created, as Windows says it.
  #
  # @param path [String] the path of the file
  # @return [Time, nil] the time, or nil when the machine cannot say
  def creation_time(path)
    windows = windows_path_of path
    return nil unless windows

    output = `powershell.exe -NoProfile -Command "(Get-Item -LiteralPath '#{windows.gsub("'", "''")}').CreationTime.ToString('o')" 2>/dev/null`
    Time.parse output.strip
  rescue ArgumentError, TypeError
    nil
  end

  # The path of a file, as Windows names it.
  #
  # @param path [String] the path
  # @return [String, nil] the path, or nil when the file is not on a Windows drive
  def windows_path_of(path)
    match = path.match(%r{\A/mnt/([a-z])/(.*)\z})
    return nil unless match

    "#{match[1].upcase}:\\#{match[2].tr('/', '\\')}"
  end
end
