require 'nokogiri'

# The machinery of a conversion between two versions of the Live format.
#
# A conversion is made of tables — the elements to remove, the elements to rename, the attributes
# to give a default value — and of a few transformations that a table cannot express, which a
# subclass adds by overriding #special_transformations.
#
# The tables do not say which way the conversion is going. A rename matches either spelling and
# emits the other, so the same table serves both directions. The direction is a property of the
# document: the version the document carries decides it.
#
# A transformation that cannot be expressed symmetrically is conditioned on the direction. A
# table that applies in one direction only is written as a hash with a key for each direction,
# and the base class takes the one that applies.
#
# A conversion is a pure function from one document to another: the result depends only on the
# document, and nothing outside it is touched. See docs/cpfir.md, section 4.
#
# The transformations are written by hand. Nothing produces them automatically; the comparison
# of the two versions is information for the person writing them. See docs/conversion.md,
# section 3.3.
#
# The terms used here are defined in docs/glossary.md.
#
# The schema of a version is an index of the format: it lists every element and every attribute
# of that version, so the differences between two versions are found by diffing one schema
# against the other. See docs/als_work.md, "Mapping XSD to Ruby Classes", and docs/conversion.md,
# sections 3.4 and 5.3.
#
# The transformations of a version_diff live in the subclass, and the differences between the
# two versions are summarized in docs/live_11_12_diff.md.
class LiveVersionConverter
  # The version strings of each direction.
  #
  # The :down key holds the strings of the older version, which are written when a set is going
  # down; the :up key holds the strings of the newer version. The version of the document decides
  # which way the conversion goes: a document that already carries the newer strings is going
  # down, and one that carries the older strings is going up.
  VERSION = { down: {}, up: {} }.freeze

  # The elements the older version does not have, wherever they appear.
  REMOVE = [].freeze

  # The elements the older version does not have, under a named parent.
  #
  # An element that is removed by its name alone would also be removed from the places the older
  # version needs it, so these entries name the parent the element has to be removed from.
  REMOVE_UNDER = [].freeze

  # The elements the two versions spell differently.
  #
  # The base class reads this table in both directions, so the name of the element is enough: the
  # rename turns the element into the other spelling.
  RENAME = {}.freeze

  # The elements the two versions spell differently, under a named parent.
  #
  # The path is not the same in both directions — the parent holds the element under a different
  # name in each version — so this table holds both directions, and the subclass writes them out.
  RENAME_UNDER = {}.freeze

  # The elements that are empty in the older version.
  EMPTY = [].freeze

  # The attributes the older version does not have.
  REMOVE_ATTRIBUTE = [].freeze

  # The attributes the older version always writes, and the value it writes.
  DEFAULT_ATTRIBUTE = {}.freeze

  # The elements the newer version adds to a set that came from the older one.
  #
  # Each entry names the parent the element goes in, the element itself, the attributes it has,
  # and the elements it holds. The element is added at the end of its parent, and the order of
  # CHILD_ORDER moves it to where the version writes it.
  ADD = { down: [], up: [] }.freeze

  # The attributes the newer version writes on an element.
  #
  # The older version does not write them at all, so a set that came from the older version does
  # not have them either. The attributes go on the elements that are already in the set.
  ADD_ATTRIBUTE = { down: {}, up: {} }.freeze

  # The order the version writes the children of an element in.
  #
  # The order says where the elements the conversion adds go, and where the elements that moved
  # between the versions go. The elements that the order does not name keep the place they have.
  CHILD_ORDER = { down: {}, up: {} }.freeze

  # The versions the bridge converts.
  #
  # @return [Array<String>] the minor versions of the two versions of the format
  def self.versions
    versions = const_get(:VERSION)
    [versions[:down]['MinorVersion'], versions[:up]['MinorVersion']]
  end

  # @param document [Nokogiri::XML::Document] the set to convert
  def initialize(document)
    @document = document
    @direction = detect_direction
  end

  # @return [Symbol] :down or :up
  attr_reader :direction

  # @return [Nokogiri::XML::Document] the set being converted
  attr_reader :document

  # Converts the set.
  #
  # @return [Nokogiri::XML::Document] the converted set
  def convert
    version_strings
    remove_elements
    rename_elements
    empty_elements
    default_attributes
    add_attributes
    special_transformations
    additions
    reorder_children
    document
  end

  # @return [Boolean] whether the set is going to the older version
  def down?
    @direction == :down
  end

  # @return [Boolean] whether the set is going to the newer version
  def up?
    @direction == :up
  end

  private

  # The version the document carries decides the direction of the conversion.
  #
  # @return [Symbol] :down or :up
  def detect_direction
    version = document.at_xpath('/Ableton')&.[]('MinorVersion').to_s
    return :down if version == self.class::VERSION[:up]['MinorVersion']
    return :up if version == self.class::VERSION[:down]['MinorVersion']

    raise ArgumentError, "cannot tell which version the set is: #{version.inspect}"
  end

  # The constant for the direction the set is going.
  #
  # A list that applies in both directions is written as it is. A list that applies in one
  # direction only is written as a hash with a key for each direction.
  #
  # @param name [Symbol] the name of the constant
  # @return [Object] the list
  def constant(name)
    value = self.class.const_get(name)
    return value.fetch(@direction) if value.is_a?(Hash) && value.key?(:down) && value.key?(:up)

    value
  end

  # Writes the version strings of the version the set is going to.
  def version_strings
    root = document.at_xpath('/Ableton')
    strings = constant(:VERSION)
    root.attribute_nodes.each { |attribute| attribute.remove unless strings.key?(attribute.name) }
    strings.each { |name, value| root[name] = value }
  end

  # Removes the elements the older version does not have.
  def remove_elements
    constant(:REMOVE).each { |name| document.xpath("//#{name}").each(&:remove) }
    constant(:REMOVE_UNDER).each { |path| document.xpath("//#{path}").each(&:remove) }
    constant(:REMOVE_ATTRIBUTE).each do |name|
      document.xpath("//*[@#{name}]").each { |element| element.remove_attribute(name) }
    end
  end

  # Renames the elements the two versions spell differently.
  def rename_elements
    renames = constant(:RENAME)
    # A rename turns the element into the other spelling, so the table is read in both directions.
    renames = renames.merge(renames.invert)
    # The elements are collected before any of them is renamed, so that an element renamed into
    # the name of another entry is not renamed a second time.
    elements = renames.keys.flat_map { |name| document.xpath("//#{name}") }
    elements.each { |element| element.name = renames[element.name] if renames.key?(element.name) }

    rename_elements_under_parent
  end

  # Renames the elements the two versions spell differently, under a named parent.
  #
  # The parent holds the element under a different name in each version, so the path of a rename
  # is the path of the element in the version the set is coming from. The elements are collected
  # before any of them is renamed, so that an element renamed into the path of another rename is
  # not renamed a second time.
  def rename_elements_under_parent
    under = constant(:RENAME_UNDER)
    matches = under.keys.flat_map { |path| document.xpath("//#{path}").map { |element| [element, under[path]] } }
    matches.each { |element, name| element.name = name }
  end

  # Empties the elements that are empty in the older version.
  def empty_elements
    constant(:EMPTY).each { |path| document.xpath("//#{path}").each { |element| element.children.remove } }
  end

  # Gives the attributes the older version always writes the value it writes.
  def default_attributes
    constant(:DEFAULT_ATTRIBUTE).each do |name, attributes|
      document.xpath("//#{name}").each do |element|
        attributes.each { |attribute, value| element[attribute] = value unless element.attribute(attribute) }
      end
    end
  end

  # Gives the elements the attributes the newer version writes on them.
  #
  # An attribute that is already there is left alone.
  def add_attributes
    constant(:ADD_ATTRIBUTE).each do |name, attributes|
      document.xpath("//#{name}").each do |element|
        attributes.each { |attribute, value| element[attribute] = value unless element.attribute(attribute) }
      end
    end
  end

  # The transformations that a table cannot express.
  #
  # A subclass overrides this and calls super.
  #
  # @return [void]
  def special_transformations; end

  # Adds the elements the newer version has and the older one does not.
  def additions
    constant(:ADD).each do |addition|
      document.xpath("//#{addition[:parent]}").each do |parent|
        next if parent.at_xpath("./#{addition[:name]}")

        append_element(parent, build_element(addition))
      end
    end
  end

  # Builds an element of the document, and the elements it holds.
  #
  # @param addition [Hash] the description of the element
  # @return [Nokogiri::XML::Node] the element
  def build_element(addition)
    element = build(addition[:name], addition[:attributes])
    addition.fetch(:children, []).each { |child| element.add_child(build_element(child)) }
    element
  end

  # Puts the children of each element in the order the version writes them in.
  #
  # The elements the order does not name keep the place they have, at the end of their parent.
  def reorder_children
    constant(:CHILD_ORDER).each do |name, order|
      document.xpath("//#{name}").each { |parent| reorder_children_of(parent, order) }
    end
  end

  # Puts the children of one element in the order the version writes them in.
  #
  # The whitespace Live writes in front of an element goes with the element, so that the set is
  # written with the indentation Live writes it with.
  #
  # @param parent [Nokogiri::XML::Node] the parent
  # @param order [Array<String>] the names of the children, in the order the version writes them
  # @return [void]
  def reorder_children_of(parent, order)
    children = parent.element_children.to_a
    known = children.select { |child| order.include?(child.name) }
    rest = children - known
    sorted = known.sort_by.with_index { |child, index| [order.index(child.name), index] }

    spaces = spaces_before(parent)
    (sorted + rest).each do |child|
      space = spaces[child]
      child.unlink
      space&.unlink
      insert_child(parent, child, space)
    end
  end

  # The whitespace in front of each child of an element.
  #
  # @param parent [Nokogiri::XML::Node] the parent
  # @return [Hash] the whitespace node in front of each child, as { child => whitespace }
  def spaces_before(parent)
    spaces = {}
    space = nil
    parent.children.each do |child|
      if child.text?
        space = child.content.strip.empty? ? child : nil
      elsif child.element?
        spaces[child] = space unless space.nil?
        space = nil
      end
    end
    spaces
  end

  # Puts an element at the end of a parent, in front of the whitespace that closes the parent.
  #
  # @param parent [Nokogiri::XML::Node] the parent
  # @param element [Nokogiri::XML::Node] the element to add
  # @param space [Nokogiri::XML::Node, nil] the whitespace in front of the element
  # @return [void]
  def insert_child(parent, element, space)
    closing = parent.children.last
    if closing.nil? || closing.type != Nokogiri::XML::Node::TEXT_NODE
      parent.add_child(element)
      return
    end

    closing.add_previous_sibling(space) unless space.nil?
    closing.add_previous_sibling(element)
  end

  # Builds an element of the document.
  #
  # @param name [String] the name of the element
  # @param attributes [Hash] the attributes of the element
  # @return [Nokogiri::XML::Node] the element
  def build(name, attributes = {})
    element = Nokogiri::XML::Node.new(name, document)
    attributes.each { |key, value| element[key] = value }
    element
  end

  # Puts an element at the end of a parent.
  #
  # Live writes the whitespace between the elements of a set as text nodes, so an element that
  # is added needs the whitespace in front of it, or the set is written without indentation.
  #
  # @param parent [Nokogiri::XML::Node] the parent
  # @param element [Nokogiri::XML::Node] the element to add
  # @return [void]
  def append_element(parent, element)
    whitespace = whitespace_of(parent)
    closing = parent.children.last
    if whitespace.nil? || closing.nil? || closing.type != Nokogiri::XML::Node::TEXT_NODE
      parent.add_child(element)
      return
    end

    closing.add_previous_sibling(text(whitespace))
    closing.add_previous_sibling(element)
  end

  # The whitespace Live writes in front of the children of an element.
  #
  # @param parent [Nokogiri::XML::Node] the parent
  # @return [String, nil] the whitespace, or nil when the parent has none
  def whitespace_of(parent)
    node = parent.children.find { |child| child.type == Nokogiri::XML::Node::TEXT_NODE }
    node&.content
  end

  # Builds a text node of the document.
  #
  # @param content [String] the text
  # @return [Nokogiri::XML::Node] the text node
  def text(content)
    Nokogiri::XML::Text.new(content, document)
  end
end
