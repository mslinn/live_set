require 'spec_helper'
require 'live_set/model/als_model'
require 'support/live_sets'

# The model of the contents of an ALS file.
#
# The model holds the file and what the file holds: the path of the file, the XML of it, the
# times of it, and the Live contents of it, which the model holds as `live_set`.
#
# The model is written in step 3 of docs/serializer_plan.md; this spec is written before it,
# so that the model is written to it.
RSpec.describe AlsModel do
  subject(:model) { described_class.new path, xml, created, modified }

  let(:path) { LiveSets.fascination }
  let(:xml) { LiveSets.document path }
  let(:created) { Time.new 2026, 11, 1, 9, 21, 59 }
  let(:modified) { Time.new 2026, 10, 28, 23, 23, 2 }

  it 'holds the path of the file' do
    expect(model.path).to eq path
  end

  it 'holds the XML of the file' do
    expect(model.xml).to be xml
  end

  it 'holds the times of the file' do
    expect(model.file_created).to eq created
    expect(model.file_last_modified).to eq modified
  end
end
