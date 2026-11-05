require 'colorator'
require_relative 'common/util'
require_directory "#{__dir__}/common"

require_directory "#{__dir__}/als_delta"
require_directory "#{__dir__}/als_diff"
require_directory "#{__dir__}/als_nodes"
require_directory "#{__dir__}/als_release_notes"
require_directory "#{__dir__}/als_report"
require_directory "#{__dir__}/als_to_version"
require_directory "#{__dir__}/als_to_xsd"
require_directory "#{__dir__}/als_validate"
require_directory "#{__dir__}/live_set"
require_directory "#{__dir__}/live_set/model"
require_directory "#{__dir__}/live_set/serializer"
require_directory "#{__dir__}/live_set/tx"

# Each command is implemented as a class method called `run` on the class that
# implements it, and the class is named after the command:
#
#   als_report         AlsReport.run
#   als_delta          AlsDelta.run
#   als_to_version     AlsToVersion.run
#   als_to_xsd         AlsToXsd.run
#   als_validate       AlsValidate.run
#   als_nodes          AlsNodes.run
#   als_diff           AlsDiff.run
#   als_xsd_order      AlsXsdOrder.run
#   als_release_notes  AlsReleaseNotes.run
#
# The executables in `exe/` call the class methods. Each class also parses its
# own options, in its `*_options.rb` file, and displays its own help.
