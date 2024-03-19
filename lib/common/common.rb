# require 'colorator'

# def common(command)
#   @options = parse_options command
#   help_live_set 'The path for the Ableton Set must be provided.' if ARGV.empty?
# end

# def show
#   common :show
#   help_live_set "Too many parameters specified.\n#{ARGV}" if ARGV.length > 2

#   set_name = ARGV.join ' '
#   help "#{set_name} does not exist" unless File.exist? set_name
#   help "#{set_name} is a directory" if File.directory? set_name

#   LiveSet.new(set_name, **@options).show
# end
