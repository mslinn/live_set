# Decides whether the children of an element can be described by an xs:sequence.
#
# An xs:sequence lists the kinds of child element an element may have, in order. It can describe
# the children only if the sample agrees on their order. Two things can go wrong.
#
# The sample files can order the same children differently. One file can also bring a child
# element back after a different child element has already appeared, and no sequence can describe
# that. Ableton Live does the latter: a MIDI track can come between two audio tracks, and a
# device parameter can come between two parameters of another type.
class ChildOrder
  # @param sequences [Array<Array<String>>] the child names of each instance of the element
  def initialize(sequences)
    @sequences = sequences
  end

  # @return [Boolean] true if a sequence cannot describe the children
  def conflict?
    different_orders? || repeated?
  end

  private

  # @return [Boolean] true if the sample files order the children differently
  def different_orders?
    order = @sequences.flatten.uniq
    @sequences.any? { |sequence| !consistent_order?(order, sequence) }
  end

  # @return [Boolean] true if a child element comes back after a different child element
  def repeated?
    @sequences.any? { |sequence| !contiguous_runs?(sequence) }
  end

  # Determine whether a sequence of child names follows the given order.
  #
  # Only the names that both sequences have in common are compared, because one file may not
  # contain every child that another file contains.
  #
  # @param order [Array<String>] the expected order of the child names
  # @param sequence [Array<String>] the child names of one instance
  # @return [Boolean] true if the common names appear in the same relative order
  def consistent_order?(order, sequence)
    shared = order & sequence
    return true if shared.size < 2

    positions = shared.map { |child_name| sequence.index(child_name) }
    positions.each_cons(2).all? { |first, second| first < second }
  end

  # Determine whether each child name appears in one run.
  #
  # @param sequence [Array<String>] the child names of one instance
  # @return [Boolean] true if each child name appears in one run
  def contiguous_runs?(sequence)
    runs = sequence.chunk_while { |first, second| first == second }.map(&:first)
    runs.uniq.size == runs.size
  end
end
