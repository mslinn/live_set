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

def human_file_size(number)
  ByteSize.new(number).to_s
end

def require_directory(dir)
  Dir[File.join(dir, '*.rb')].sort.each do |file|
    # puts "Requiring #{file}"
    require file
  end
end
