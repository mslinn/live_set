require 'nokogiri'

# The machinery of a conversion between two versions of the Live format.
#
# A bridge is the class that converts a set between two adjacent versions of the Live format.
# A bridge never inherits from another bridge: a conversion across several versions is the
# composition of the bridges between them, one after the other, and each of those bridges stands
# on its own. The base class refuses to be the parent of a bridge of a bridge. See docs/cpfir.md,
# "Dynamically Slicing the Pipeline Intervals".
#
# The base class knows nothing about any particular version_diff. It applies the lists a bridge
# declares, in the order the lists are applied, and it takes the direction from the version the
# document carries.
#
# A bridge declares its lists by calling the declaration methods below, one method for each
# list:
#
#   version           the version strings of each direction
#   remove            the elements the older version does not have
#   remove_under      the elements the older version does not have, under a named parent
#   rename            the elements the two versions spell differently
#   rename_under      the elements the two versions spell differently, under a named parent
#   empty             the elements the older version keeps empty
#   remove_attribute  the attributes the older version does not have
#   default_attribute the attributes the older version always writes
#   add               the elements the newer version adds
#   add_attribute     the attributes the newer version writes
#   child_order       the order the version writes the children of an element in
#
# A declaration adds to what the list already holds, so a list can be declared in more than one
# place without any of the declarations losing content.
#
# A bridge has to declare every list, even the ones it has nothing to say about. A list that is
# not declared is an error, and it is named. A list that is declared under a name the base class
# does not have is an error too, and it is raised when the bridge is loaded.
#
# The lists do not say which way the conversion is going. A rename matches either spelling and
# emits the other, so the same list serves both directions. The direction is a property of the
# document: the version the document carries decides it.
#
# A transformation that cannot be expressed symmetrically is conditioned on the direction. A
# list that applies in one direction only is declared with a value for each direction, and the
# base class takes the one that applies.
#
# The transformations that a list cannot express are written by hand in the bridge, by
# overriding #special_transformations. Nothing produces them automatically; the comparison of
# the two versions is information for the person writing them. See docs/conversion.md, "The
# differences must be sorted by kind, and the non-obvious ones hand-written".
#
# A conversion is a pure function from one document to another: the result depends only on the
# document, and nothing outside it is touched. See docs/cpfir.md, "The Lifecycle of a Conversion".
#
# The schema of a version is an index of the format: it lists every element and every attribute
# of that version, so the differences between two versions are found by diffing one schema
# against the other. See docs/als_work.md, "Mapping XSD to Ruby Classes", and docs/conversion.md,
# "Attributes have to be part of the difference list" and "Why the baselines are what to compare".
#
# The terms used here are defined in docs/glossary.md.
#
# The transformations of a version_diff live in the bridge, and the differences between the two
# versions are summarized in docs/live_11_12_diff.md.
class LiveVersionConverter
  # The lists a bridge declares.
  LISTS = %i[
    version remove remove_under rename rename_under empty remove_attribute
    default_attribute add add_attribute child_order
  ].freeze

  # The lists whose content differs in the two directions.
  #
  # A list of these is declared with a value for each direction, and the base class takes the
  # one that applies to the direction the set is going.
  DIRECTIONAL = %i[
    version remove remove_under rename_under empty add add_attribute child_order
  ].freeze

  # The lists whose content is the same in the two directions.
  #
  # A list of these is declared once, and the base class reads it in both directions.
  SYMMETRIC = (LISTS - DIRECTIONAL).freeze

  class << self
    # The lists the bridge declares.
    #
    # @return [Hash] the lists, keyed by the name of the list
    # @raise [ArgumentError] when the bridge does not declare every list
    def lists
      declared = @lists ||= {}
      missing = LISTS - declared.keys
      raise ArgumentError, "#{name} does not declare: #{missing.join(', ')}" unless missing.empty?

      declared
    end

    # The versions the bridge converts.
    #
    # @return [Array<String>] the minor versions of the two versions of the format
    def versions
      strings = lists[:version]
      [strings[:down]['MinorVersion'], strings[:up]['MinorVersion']]
    end

    # Converts a document.
    #
    # The class is a function of a document: it takes a document and returns the converted
    # document. The registry of the bridges holds them as such functions, and composes them with
    # `>>`. See docs/cpfir.md, "Defining a Single Source of Truth: The Target End-State" and
    # "Dynamically Slicing the Pipeline Intervals".
    #
    # @param document [Nokogiri::XML::Document] the set to convert
    # @return [Nokogiri::XML::Document] the converted set
    def call(document)
      new(document).convert
    end

    # Declares the version strings of each direction.
    #
    # @param down [Hash] the version strings of the older version
    # @param up [Hash] the version strings of the newer version
    # @return [void]
    def version(down:, up:)
      declare(:version, down: down, up: up)
    end

    # Declares the elements the older version does not have, wherever they appear.
    #
    # @param down [Array<String>] the elements to remove going down
    # @param up [Array<String>] the elements to remove going up
    # @return [void]
    def remove(down:, up:)
      declare(:remove, down: down, up: up)
    end

    # Declares the elements the older version does not have, under a named parent.
    #
    # @param down [Array<String>] the paths to remove going down
    # @param up [Array<String>] the paths to remove going up
    # @return [void]
    def remove_under(down:, up:)
      declare(:remove_under, down: down, up: up)
    end

    # Declares the elements the two versions spell differently.
    #
    # The list is read in both directions, so a rename turns the element into the other
    # spelling whichever spelling it has.
    #
    # @param names [Hash] the new spelling of each element, keyed by the old spelling
    # @return [void]
    def rename(names)
      declare(:rename, names)
    end

    # Declares the elements the two versions spell differently, under a named parent.
    #
    # The parent holds the element under a different name in each version, so the path of a
    # rename is the path of the element in the version the set is coming from, and the list
    # holds one path for each direction.
    #
    # @param down [Hash] the paths to rename going down, and the names they get
    # @param up [Hash] the paths to rename going up, and the names they get
    # @return [void]
    def rename_under(down:, up:)
      declare(:rename_under, down: down, up: up)
    end

    # Declares the elements that are empty in the older version.
    #
    # @param down [Array<String>] the paths to empty going down
    # @param up [Array<String>] the paths to empty going up
    # @return [void]
    def empty(down:, up:)
      declare(:empty, down: down, up: up)
    end

    # Declares the attributes the older version does not have.
    #
    # @param names [Array<String>] the attributes to remove
    # @return [void]
    def remove_attribute(names)
      declare(:remove_attribute, names)
    end

    # Declares the attributes the older version always writes, and the value it writes.
    #
    # @param names [Hash] the attributes of each element, keyed by the element
    # @return [void]
    def default_attribute(names)
      declare(:default_attribute, names)
    end

    # Declares the elements the newer version adds to a set that came from the older one.
    #
    # Each entry names the parent the element goes in, the element itself, the attributes it
    # has, and the elements it holds.
    #
    # @param down [Array<Hash>] the elements to add going down
    # @param up [Array<Hash>] the elements to add going up
    # @return [void]
    def add(down:, up:)
      declare(:add, down: down, up: up)
    end

    # Declares the attributes the newer version writes on an element.
    #
    # @param down [Hash] the attributes of each element, keyed by the element
    # @param up [Hash] the attributes of each element, keyed by the element
    # @return [void]
    def add_attribute(down:, up:)
      declare(:add_attribute, down: down, up: up)
    end

    # Declares the order the version writes the children of an element in.
    #
    # @param down [Hash] the order of the children of each element, keyed by the element
    # @param up [Hash] the order of the children of each element, keyed by the element
    # @return [void]
    def child_order(down:, up:)
      declare(:child_order, down: down, up: up)
    end

    # A bridge is never the parent of another bridge.
    #
    # @param subclass [Class] the class being defined
    # @raise [ArgumentError] when the parent is a bridge rather than the base class
    # @return [void]
    def inherited(subclass)
      super
      return if base?

      raise ArgumentError, "a bridge does not inherit from another bridge: #{subclass} < #{self}"
    end

    # @return [Boolean] whether this class is the base class rather than a bridge
    def base?
      equal?(LiveVersionConverter)
    end

    private

    # Adds a declaration to the list it belongs to.
    #
    # @param name [Symbol] the name of the list
    # @param value [Object] the content of the declaration
    # @return [void]
    def declare(name, value)
      @lists ||= {}
      @lists[name] = merge_lists(@lists[name], value)
    end

    # Adds the content of a declaration to what a list already holds.
    #
    # @param existing [Object, nil] what the list holds
    # @param value [Object] the content of the declaration
    # @return [Object] what the list holds afterwards
    def merge_lists(existing, value)
      return value if existing.nil?
      return (existing + value).uniq if existing.is_a?(Array) && value.is_a?(Array)
      return existing.merge(value) { |_key, old, new| merge_lists(old, new) } if existing.is_a?(Hash) && value.is_a?(Hash)

      value
    end
  end

  # @param document [Nokogiri::XML::Document] the set to convert
  def initialize(document)
    @document = document
    @lists = self.class.lists
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

  # The content of a list, in the direction the set is going.
  #
  # @param name [Symbol] the name of the list
  # @return [Object] the content of the list
  def list(name)
    value = @lists.fetch(name)
    return value if SYMMETRIC.include?(name)

    value.fetch(@direction)
  end

  # The version the document carries decides the direction of the conversion.
  #
  # @return [Symbol] :down or :up
  def detect_direction
    strings = @lists[:version]
    version = document.at_xpath('/Ableton')&.[]('MinorVersion').to_s
    return :down if version == strings[:up]['MinorVersion']
    return :up if version == strings[:down]['MinorVersion']

    raise ArgumentError, "cannot tell which version the set is: #{version.inspect}"
  end

  # Writes the version strings of the version the set is going to.
  def version_strings
    root = document.at_xpath('/Ableton')
    strings = list(:version)
    root.attribute_nodes.each { |attribute| attribute.remove unless strings.key?(attribute.name) }
    strings.each { |name, value| root[name] = value }
  end

  # Removes the elements the older version does not have.
  def remove_elements
    list(:remove).each { |name| document.xpath("//#{name}").each(&:remove) }
    list(:remove_under).each { |path| document.xpath("//#{path}").each(&:remove) }
    list(:remove_attribute).each do |name|
      document.xpath("//*[@#{name}]").each { |element| element.remove_attribute(name) }
    end
  end

  # Renames the elements the two versions spell differently.
  def rename_elements
    renames = list(:rename)
    # A rename turns the element into the other spelling, so the list is read in both directions.
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
    under = list(:rename_under)
    matches = under.keys.flat_map { |path| document.xpath("//#{path}").map { |element| [element, under[path]] } }
    matches.each { |element, name| element.name = name }
  end

  # Empties the elements that are empty in the older version.
  def empty_elements
    list(:empty).each { |path| document.xpath("//#{path}").each { |element| element.children.remove } }
  end

  # Gives the attributes the older version always writes the value it writes.
  def default_attributes
    list(:default_attribute).each do |name, attributes|
      document.xpath("//#{name}").each do |element|
        attributes.each { |attribute, value| element[attribute] = value unless element.attribute(attribute) }
      end
    end
  end

  # Gives the elements the attributes the newer version writes on them.
  #
  # An attribute that is already there is left alone.
  def add_attributes
    list(:add_attribute).each do |name, attributes|
      document.xpath("//#{name}").each do |element|
        attributes.each { |attribute, value| element[attribute] = value unless element.attribute(attribute) }
      end
    end
  end

  # The transformations that a list cannot express.
  #
  # A bridge overrides this and calls super.
  #
  # @return [void]
  def special_transformations; end

  # Adds the elements the newer version has and the older one does not.
  def additions
    list(:add).each do |addition|
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
    list(:child_order).each do |name, order|
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
