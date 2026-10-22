require 'colorator'

# Display help message for validate_asd
def help_validate_asd(msg = nil)
  printf "Error: #{msg}\n\n".yellow unless msg.nil?
  msg = <<~END_HELP
    Validate_asd checks that an Ableton Live set conforms to an XSD schema.

    Syntax: validate_asd PATH_TO_ALS_FILE SCHEMA.xsd

    Environment variables used in PATH_TO_ALS_FILE are expanded.

    Example:
      validate_asd $path/to/my_v12_set.als schema.xsd
  END_HELP
  printf msg.cyan
  exit 1
end
