# Writes a collection of nodes.
#
# The collection is never written by itself: each node is written by the serializer of a
# node, and the outputs are mapped together.
#
# The nodes of the collection have the numbers they have in the report, and the serializer
# of a node is made from the number and the node. The collection writes the nodes in
# markdown or in HTML, and the serializer of a node writes the node itself.
class LiveCollectionSerializer
  # Returns the collection as markdown.
  #
  # @return [String] the serialized markdown
  def to_markdown
    written :to_markdown
  end

  # Returns the collection as HTML.
  #
  # @return [String] the serialized HTML
  def to_html
    written :to_html
  end

  private

  # The nodes of the collection, each of them written by its serializer.
  #
  # @param method [Symbol] the method to call on the serializer of each node
  # @return [String] the nodes, one after another
  def written(method)
    items.map { |number, node| write_item(number, node, method) }.join("\n")
  end

  # Writes one node of the collection.
  #
  # A collection of nodes that the model does not hold — the copies of a clip, for
  # instance — writes its nodes itself.
  #
  # @param number [HierarchicalNumber] the number of the node
  # @param node [Object] the node
  # @param method [Symbol] the method to call on the serializer of the node
  # @return [String] the node, written
  def write_item(number, node, method)
    serializer_for(number, node).public_send(method)
  end

  # The nodes of the collection, with the numbers they have in the report.
  #
  # @return [Array<Array>] the number and the node
  def items
    raise NotImplementedError, "#{self.class} must implement #items"
  end

  # The serializer of a node of the collection.
  #
  # @param number [HierarchicalNumber] the number of the node
  # @param node [Object] the node
  # @return [Object] the serializer of the node
  def serializer_for(number, node)
    raise NotImplementedError, "#{self.class} must implement #serializer_for"
  end
end
