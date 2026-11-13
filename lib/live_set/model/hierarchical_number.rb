# The number a thing has in the report.
#
# The prefix says what kind of thing it is, and the dots say how deep it is: "G1.2" is the
# second thing of the first group.
#
# The children of a thing are numbered in one sequence among themselves: the devices of a
# track and the clips of the track are numbered apart from each other.
#
# A number is mutable: `indent`, `outdent` and `increment` change it in place. A thing that
# hands a number to a child therefore hands it a copy — a `dup` — so that the child cannot
# change the number of the thing that holds it. The copy is shallow, and it is safe: the
# methods that change a number replace its components with a new array instead of changing
# the one they are in.
class HierarchicalNumber
  attr_reader :prefix

  # @param prefix [String] the letter that says what kind of thing it is: "G", "T", …
  def initialize(prefix)
    @prefix = prefix
    @components = ['1']
  end

  # A level deeper: "1" becomes "1.1".
  #
  # @return [HierarchicalNumber] this number
  def indent
    @components += ['1']
    self
  end

  # A level up: "1.1" becomes "1".
  #
  # @return [HierarchicalNumber] this number
  def outdent
    @components = @components[0..-2] if @components.length > 1
    self
  end

  # The next thing at this level: "1" becomes "2".
  #
  # @param count [Integer] how many things to skip
  # @return [HierarchicalNumber] this number
  def increment(count = 1)
    @components = @components[0..-2] + [(@components.last.to_i + count).to_s]
    self
  end

  # The first thing at this level.
  #
  # @return [HierarchicalNumber] this number
  def reset
    @components = ['1']
    self
  end

  # The number, as it is written.
  #
  # @return [String] the number
  def to_s
    "#{@prefix}#{@components.join('.')}"
  end

  # The number of levels the thing is at.
  #
  # A number with two dots is at the third level of the hierarchy.
  #
  # @return [Integer] the level of the thing
  def level
    @components.length
  end

  # The indentation of the thing with this number.
  #
  # The number knows how deep the thing is. How wide a level is belongs to the writer, so
  # the caller says how wide a level is.
  #
  # @param indent [String] the indentation of one level
  # @return [String] the indentation
  def indent_for(indent)
    indent * (level - 1)
  end
end
