class Array
  # Convert an Array of Array into a String, formatted as a table.
  def columnize(separator = '  ')
    each { |row| row.is_a? Array or raise NoMethodError, 'Must be called on an Array of Array.' }
    result = ''
    l = []
    each { |row| row.each_with_index { |f, i| l[i] = [l[i] || 0, f.to_s.length].max } }
    each do |row|
      row.each_with_index { |f, i| result << "#{f.to_s.ljust l[i]}#{separator}" }
      result << "\n"
    end
    result
  end
end

class String
  def to_bool
    return true if casecmp('true').zero?
    return false if casecmp('false').zero?

    nil
  end

  def expand_env
    gsub(/\$([a-zA-Z_][a-zA-Z0-9_]*)|\${\g<1>}|%\g<1>%/) do
      ENV.fetch(Regexp.last_match(1), nil)
    end
  end
end

def human_file_size(number, decimal_places = 1)
  ByteSize.new(number).to_s(decimal_places)
end

def require_directory(dir)
  Dir[File.join(dir, '*.rb')].sort.each do |file|
    require file
  end
end
