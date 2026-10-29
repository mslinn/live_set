require 'nokogiri'

# Compares two XML documents element by element.
#
# The documents are walked in parallel: the children of two elements are matched by their names.
# The children that have the same name are compared with each other, in the order they come, and
# the children that one of the elements has and the other does not are reported as differences.
#
# A Live set is XML, usually gzip-compressed, so the two documents can be Live sets or any XML
# files.
class XmlDiff
  # @param ours [Nokogiri::XML::Node] the element of the first document
  # @param theirs [Nokogiri::XML::Node] the element of the second document
  # @param skip [Array<String>] the names of the elements that are not compared at all
  def initialize(ours, theirs, skip: [])
    @ours = ours
    @theirs = theirs
    @skip = skip
  end

  # The differences between the two documents.
  #
  # @return [Array<String>] the differences, one per line
  def differences
    found = []
    compare(@ours, @theirs, @ours.name, found)
    found
  end

  private

  # Compares two elements, and the elements below them.
  #
  # @param ours [Nokogiri::XML::Node] the element of the first document
  # @param theirs [Nokogiri::XML::Node] the element of the second document
  # @param path [String] the path of the element
  # @param found [Array<String>] the differences found so far
  # @return [void]
  def compare(ours, theirs, path, found)
    return if @skip.include?(ours.name)

    found.concat attribute_differences(ours, theirs, path)

    pairs = matched_children(ours, theirs)
    pairs.each { |our_child, their_child| compare(our_child, their_child, "#{path}/#{our_child.name}", found) }

    ours.element_children.map(&:name).tally.each do |name, count|
      found << "#{path}/#{name} only in ours" if count > theirs.element_children.count { |child| child.name == name }
    end
    theirs.element_children.map(&:name).tally.each do |name, count|
      found << "#{path}/#{name} only in theirs" if count > ours.element_children.count { |child| child.name == name }
    end
  end

  # The children of two elements that have the same name, paired up.
  #
  # The children that have the same name are paired in the order they come, so that the first
  # child of one element is compared with the first child of the other.
  #
  # @param ours [Nokogiri::XML::Node] the element of the first document
  # @param theirs [Nokogiri::XML::Node] the element of the second document
  # @return [Array<Array(Nokogiri::XML::Node, Nokogiri::XML::Node)>] the pairs of children
  def matched_children(ours, theirs)
    theirs_children = theirs.element_children.group_by(&:name)
    pairs = []
    ours.element_children.each do |child|
      their_child = theirs_children.fetch(child.name, []).shift
      pairs << [child, their_child] unless their_child.nil?
    end
    pairs
  end

  # The attributes of two elements that are not the same.
  #
  # An attribute that one of the elements has and the other does not is a difference, and so is
  # an attribute whose value is not the same.
  #
  # @param ours [Nokogiri::XML::Node] the element of the first document
  # @param theirs [Nokogiri::XML::Node] the element of the second document
  # @param path [String] the path of the element
  # @return [Array<String>] the paths of the attributes that differ
  def attribute_differences(ours, theirs, path)
    names = (ours.attribute_nodes.map(&:name) + theirs.attribute_nodes.map(&:name)).uniq
    names.filter_map do |name|
      next if ours[name] == theirs[name]

      "#{path}/@#{name} ours=#{ours[name].inspect} theirs=#{theirs[name].inspect}"
    end
  end
end
