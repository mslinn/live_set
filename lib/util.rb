class String
  def to_bool
    return true if casecmp('true').zero?
    return false if casecmp('false').zero?

    nil
  end
end

def self.expand_env(str)
  str.gsub(/\$([a-zA-Z_][a-zA-Z0-9_]*)|\${\g<1>}|%\g<1>%/) do
    ENV.fetch(Regexp.last_match(1), nil)
  end
end

def self.human_file_size(filename)
  ByteSize.new(File.size(filename)).to_s
end
