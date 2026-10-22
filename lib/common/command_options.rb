require_relative 'log'

# Shared behavior for the commands that parse command line options.
#
# Each command's options live in the class that implements the command. This module holds the
# parts that are the same everywhere, so that each command only has to describe what makes it
# different.
module CommandOptions
  # Normalizes the loglevel and reports whether it is one of the valid levels.
  #
  # @param options [Hash] the parsed options, which are updated in place
  # @return [String, nil] an error message, or nil if the loglevel is valid
  def self.loglevel_error(options)
    options[:loglevel] = options[:loglevel].to_s.upcase if options[:loglevel]

    loglevel = options[:loglevel]
    return nil if loglevel.nil? || LOG_LEVELS.include?(loglevel.upcase.to_sym)

    "Invalid verbosity value (#{loglevel}), must be one of one of: #{LOG_LEVELS.join ', '}."
  end
end
