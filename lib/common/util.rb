# Monkey patch Array to add one new method
class Array
  # Convert an Array of Array into a String, formatted as a table.
  def columnize(separator = '  ')
    each { |row| row.is_a? Array or raise NoMethodError, 'Must be called on an Array of Array.' }
    l = []
    each { |row| row.each_with_index { |f, i| l[i] = [l[i] || 0, f.to_s.length].max } }
    map do |row|
      row.each_with_index.map { |f, i| "#{f.to_s.ljust l[i]}#{separator}" }.join + "\n" # rubocop:disable Style/StringConcatenation
    end.join
  end
end

# Monkey patch String to add two new methods
class String # rubocop:disable Style/OneClassPerFile
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

# Format a number so it is human-friendly with one decimal place
def human_file_size(number, decimal_places = 1)
  ByteSize.new(number).to_s(decimal_places)
end

# Require all Ruby source files in a directory
def require_directory(dir)
  path = File.join(dir, '*.rb')
  # puts "Requiring directory #{path}"
  Dir[path].each do |file|
    # puts "  Requiring #{file}"
    require file
  end
end
