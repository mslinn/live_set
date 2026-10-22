require 'colorator'
require_relative 'common/util'
require_directory "#{__dir__}/common"

require_directory "#{__dir__}/als_delta"
require_directory "#{__dir__}/generate_xsd"
require_directory "#{__dir__}/live_set"
require_directory "#{__dir__}/validate_asd"

# Each command is a class method on the class that implements it:
#
#   live_set       LiveSet.run
#   als_delta      AlsDelta.run
#   generate_xsd   XsdFromXml.run
#   validate_asd   ValidateAsd.run
#
# The executables in exe/ call these. Each class also parses its own options, in its
# *_options.rb file, and displays its own help.
