require 'live_set/model/hierarchical_number'

# The numbers the report gives the things of a set.
#
# The numbers of a set are made by the serializers. The examples build the numbers they
# pass to the serializers.
module ReportNumbers
  class << self
    # A number in the report.
    #
    # @param prefix [String] the letter that says what kind of thing it is: "G", "T", …
    # @param components [Array<Integer>] the levels of the number: the first is the number
    #   of the thing at the top of the set, and the others are the numbers of the things
    #   under it
    # @return [HierarchicalNumber] the number
    def number(prefix, *components)
      first, *rest = components
      number = HierarchicalNumber.new(prefix).increment(first - 1)
      rest.each { |component| number.indent.increment(component - 1) }
      number
    end
  end
end
