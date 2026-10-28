require 'spec_helper'
require 'tmpdir'
require 'live_set/als_file'
require 'live_set/tx/live_11_and_12'
require 'demo_sets'

# The up direction, checked against the conversion Live itself made.
#
# The Live 11 Suite demo set was opened in Live 12 and saved, and the file Live wrote is the
# reference. The conversion of the Live 11 set has to produce the same set.
#
# Live 12 writes the device chain of a set out again when it saves it: every device is written
# with the parameters of the Live 12 version of that device, and Live 12 gives the automation
# of the devices new identifiers. The conversion does not do that, so the devices are not
# compared. Everything else has to be the same, element for element.
#
# The ground truth of what Live does is in spec/live_set/tx/live_up_ground_truth_spec.rb.
RSpec.describe 'the up conversion of the Live 11 Suite demo set' do
  let(:live11_path) { DemoSets.require_edition!('11', 'Suite') }
  let(:live12_path) { DemoSets.require_converted!('11', 'Suite') }

  let(:live11) { AlsFile.read(live11_path) }
  let(:live12) { AlsFile.read(live12_path) }
  let(:converted) do
    document = AlsFile.read(live11_path)
    Live11And12.new(document).convert
    document
  end

  # The elements that hold the devices of a chain.
  #
  # Live writes the devices of a chain out again when it saves a set, so the conversion does not
  # reproduce them and the comparison does not look inside them.
  DEVICE_CHAINS = %w[Devices DeviceChain].freeze

  # The paths of the elements that differ between two documents.
  #
  # Two documents are compared element by element. The children of two elements are matched by
  # their names, in order. When the children do not match, the element that holds them is
  # reported as different, and the comparison does not go further into it.
  #
  # @param ours [Nokogiri::XML::Node] the element of the converted set
  # @param theirs [Nokogiri::XML::Node] the element of the set Live wrote
  # @param path [String] the path of the element
  # @return [Array<String>] the paths of the elements that differ
  def differences(ours, theirs, path)
    return [] if ours.name != theirs.name

    found = []
    ours.attribute_nodes.each do |attribute|
      next if theirs[attribute.name] == attribute.value

      found << "#{path}/@#{attribute.name} ours=#{attribute.value.inspect} theirs=#{theirs[attribute.name].inspect}"
    end

    ours_children = ours.element_children
    theirs_children = theirs.element_children
    unless ours_children.map(&:name) == theirs_children.map(&:name)
      found << "#{path} children #{ours_children.map(&:name).inspect} != #{theirs_children.map(&:name).inspect}"
      return found
    end

    ours_children.each_with_index do |child, index|
      next if DEVICE_CHAINS.include?(child.name)

      found.concat differences(child, theirs_children[index], "#{path}/#{child.name}")
    end
    found
  end

  it 'produces the set Live produced' do
    found = differences(converted.root, live12.root, 'Ableton')

    # The differences are written down, so that they can be looked at without running the
    # spec again, and so that they are not lost in the scrollback of the terminal.
    report = File.join(Dir.tmpdir, 'live_set', 'up_comparison_differences.txt')
    Dir.mkdir(File.dirname(report)) unless Dir.exist?(File.dirname(report))
    File.write(report, found.join("\n"))

    expect(found).to be_empty
  end
end
