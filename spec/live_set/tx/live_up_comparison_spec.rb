require 'spec_helper'
require 'live_set/als_file'
require 'live_set/tx/live_11_and_12'
require 'demo_sets'

# The elements that hold the devices of a chain.
#
# Live writes the devices of a chain out again when it saves a set, so the conversion does not
# reproduce them and the comparison does not look inside them.
DEVICE_CHAINS = %w[Devices DeviceChain].freeze

# The differences that are known, and why they are there.
#
# The reason is the reason Live writes the difference, and not something the conversion can
# do anything about.
KNOWN_DIFFERENCES = {
  'Live gives the objects of the set new identifiers when it writes the devices out again' =>
    %r{^Ableton/LiveSet/NextPointeeId/@Value},
  'Live counts the times it has written the set' =>
    %r{^Ableton/LiveSet/OverwriteProtectionNumber/@Value},
  'Live writes the size of its window, and the zoom of the drum view' =>
    %r{^Ableton/LiveSet/SequencerNavigator/},
  'Live writes the lanes of the MIDI editor as they were in its session view' =>
    %r{^Ableton/LiveSet/(ExpressionLanes|ContentLanes)},
  'Live found the sample again, on the machine it was saved on' =>
    %r{/SampleRef/},
}.freeze

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
# What is left are the differences that come from the state of the machine Live ran on, and from
# the state of the session view: Live writes the size of its window, the counters of the
# objects it made, and the lanes of the MIDI editor as they were when it saved. A conversion
# cannot reproduce those, so they are known differences, and this spec says which ones they are.
#
# The ground truth of what Live does is in spec/live_set/tx/live_up_ground_truth_spec.rb.
RSpec.describe Live11And12, 'the up conversion of the Live 11 Suite demo set' do
  let(:live11_path) { DemoSets.require_edition!('11', 'Suite') }
  let(:live12_path) { DemoSets.require_converted!('11', 'Suite') }

  let(:live_11_set) { AlsFile.read(live11_path) }
  let(:live_12_set) { AlsFile.read(live12_path) }
  let(:converted) do
    document = AlsFile.read(live11_path)
    described_class.new(document).convert
    document
  end

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
    found.concat attribute_differences(ours, theirs, path)

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

  # The attributes of two elements that are not the same.
  #
  # An attribute that one of the elements has and the other does not is a difference, and so is
  # an attribute whose value is not the same.
  #
  # @param ours [Nokogiri::XML::Node] the element of the converted set
  # @param theirs [Nokogiri::XML::Node] the element of the set Live wrote
  # @param path [String] the path of the element
  # @return [Array<String>] the paths of the attributes that differ
  def attribute_differences(ours, theirs, path)
    names = (ours.attribute_nodes.map(&:name) + theirs.attribute_nodes.map(&:name)).uniq
    names.filter_map do |name|
      next if ours[name] == theirs[name]

      "#{path}/@#{name} ours=#{ours[name].inspect} theirs=#{theirs[name].inspect}"
    end
  end

  it 'produces the set Live produced' do
    found = differences(converted.root, live_12_set.root, 'Ableton')

    # Every difference has to be one that is known, and every known difference has to be one
    # that occurs, so that this spec keeps saying what it says today.
    aggregate_failures do
      found.each do |difference|
        expect(reason_for(difference)).not_to be_nil, "#{difference} is not a known difference"
      end
      KNOWN_DIFFERENCES.each do |reason, pattern|
        expect(found.any? { |difference| difference.match?(pattern) }).to be(true), "#{reason} did not happen"
      end
    end
  end

  # The reason of a difference, when it is a known one.
  #
  # @param difference [String] the difference
  # @return [String, nil] the reason, or nil when the difference is not known
  def reason_for(difference)
    KNOWN_DIFFERENCES.each { |reason, pattern| return reason if difference.match?(pattern) }

    nil
  end
end
