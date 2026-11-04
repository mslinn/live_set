# TODO: finish this
#

# The complete model of the contents of an ALS file
class AlsModel
  # TODO: what other parameters should go here?
  attr_reader :path, :xml, :file_created, :file_last_modified

  def initialize(path, xml, file_created, file_last_modified)
    @path = path
    @xml = xml
    @file_created = file_created
    @file_last_modified = file_last_modified
  end
end
