# Composing Pure Functions in Ruby

[Function composition in
Ruby](https://www.ghostcassette.com/function-composition-in-ruby/) can be
achieved using the native `>>` (pipeline) and `<<` (compose) operators on `Proc`
and `Method` objects. [Pure functions in
Ruby](https://engineering.gusto.com/embracing-functional-programming-in-ruby-4386129cc7e4)
are blocks of code that have no observable side effects and always produce the
same output for a given input.


## Methods for Composing Pure Functions

1. Native Proc Composition (`>>` and `<<`)

    You can define pure functions using [lambdas or
    procs](https://ruby-doc.org/learn/ruby-functional-programming/), and chain
    them directly using forward (`>>`) or backward (`<<`)
    [composition](https://www.ghostcassette.com/function-composition-in-ruby/).

    ```ruby
    # Define pure lambdas
    add_three  = ->(x) { x + 3 }
    square     = ->(x) { x * x }
    to_string  = ->(x) { "Result: #{x}" }

    # Forward composition (Left-to-Right): add_three -> square -> to_string
    pipeline = add_three >> square >> to_string
    pipeline.call(5) # => "Result: 64"

    # Backward composition (Right-to-Left): to_string(square(add_three(x)))
    compose = to_string << square << add_three
    compose.call(5) # => "Result: 64"
    ```

2. Composing Standard Class Methods

    If your pure functions are written as standard object methods, you can extract
    them into Method objects using #method and compose them the exact same way.

    ```ruby
    module MathOperations
      def self.double(x) = x * 2
      def self.increment(x) = x + 1
    end

    # Extract pure methods into callable entities
    double_fn = MathOperations.method(:double)
    increment_fn = MathOperations.method(:increment)

    # Compose them together
    double_then_increment = double_fn >> increment_fn
    double_then_increment.call(4) # => 9
    ```

3. Pure Function as an Object (PFaaO Pattern)

    For complex business operations that require multi-step internal
    transformations, idiomatic Ruby often relies on the Pure Function as an
    Object pattern. This wraps functional workflows inside a specialized class
    that acts like a single pure function from the outside. This is known as the
    [PFaaO
    Pattern](https://www.tomdalling.com/blog/pure-function-as-an-object-PFAAO-pattern/)

    ```ruby
    class TextProcessor
      # Single public API entry point
      def self.call(input)
        new(input).process
      end

      private

      def initialize(input)
        @input = input.freeze # Maintain immutability
      end

      def process
        strip_whitespace(normalize_case(@input))
      end

      def normalize_case(str) = str.downcase
      def strip_whitespace(str) = str.strip
    end

    TextProcessor.call("  Hello Ruby World!  ") # => "hello ruby world!"
    ```


## Core Design Rules for Pure Ruby Pipelines

• Enforce Immutability: Avoid mutative methods (like `map!`, `gsub!`, or `upcase!`).
Use freeze on incoming collection arguments to prevent accidental state
mutation. [1] (https://blog.devops.dev/pure-functions-in-ruby-f0431c3766d4), [2]
(https://www.sitepoint.com/functional-programming-pure-functions/), [3]
(https://ruby-doc.org/learn/ruby-functional-programming/)

• Isolate Side Effects: Ensure operations within the pipeline do not touch
global state, access system time, query database layers, or trigger console
inputs/outputs (puts). [1]
(https://patshaughnessy.net/2014/4/8/using-a-ruby-class-to-write-functional-code)


## Ordered Sets of Pure Functions

Given an ordered set of pure functions:

```ruby
[v8_to_9, v9_to11, v10_to_11, v11_to_12]
```

Show various ways to compose intervals in the set, e.g.:

```ruby
v8_to_9.v9_to11
v8_to_9.v9_to11.v10_to_11
v8_to_9.v9_to11.v10_to_11.v11_to_12
```

To compose specific intervals (or slices) from an ordered set of functions in
Ruby, the most idiomatic approach is combining array slicing with
`Enumerable#reduce` using the forward composition operator (`>>`).  Here are the
various ways to achieve this, from direct slicing to building a dynamic pipeline
helper.

### Setup

Assuming your pure functions are defined as lambdas or procs inside an ordered array:

```ruby
v8_to_9   = ->(x) { "v9(#{x})" }
v9_to_10  = ->(x) { "v10(#{x})" }
v10_to_11 = ->(x) { "v11(#{x})" }
v11_to_12 = ->(x) { "v12(#{x})" }

# The ordered set
pipeline_steps = [v8_to_9, v9_to_10, v10_to_11, v11_to_12]
```

### Possible Approaches

1. The Idiomatic Aproach: Array Slicing + reduce(`:>>`)

    You can extract any interval using Ruby's range slicing (`[start..end]`) and chain
    them together using reduce(`:>>`) to return a single composed pure function.

    ```ruby
    # Interval 1: v8_to_9 >> v9_to_10

    v8_to_10 = pipeline_steps[0..1].reduce(:>>)
    v8_to_10.call("data") # => "v10(v9(data))"

    # Interval 2: v8_to_9 >> v9_to_10 >> v10_to_11
    v8_to_11 = pipeline_steps[0..2].reduce(:>>)
    v8_to_11.call("data") # => "v11(v10(v9(data)))"

    # Interval 3: Full pipeline (v8 through v12)
    full_pipeline = pipeline_steps.reduce(:>>)
    full_pipeline.call("data") # => "v12(v11(v10(v9(data))))"

    # Interval 4: Middle slice (v9 to v12)
    v9_to_12 = pipeline_steps[1..3].reduce(:>>)
    v9_to_12.call("data") # => "v12(v11(v10(data)))"
    ```

2. The Semantic Aproach: A Dedicated Pipeline Wrapper

    If you frequently compose intervals, you can wrap the array in a small utility
    class that allows you to fetch intervals by descriptive indices or keys.

    ```ruby
    class FunctionChain def initialize(steps) @steps = steps end

    # Compose an interval using a standard Ruby Range

      def interval(range)
        @steps[range].reduce(:>>)
      end

    # Compose from the beginning up to a specific step index

      def up_to(index)
        interval(0..index)
      end
    end

    # Usage

    chain = FunctionChain.new(pipeline_steps)

    # Equivalent to v8_to_9.v9_to_10

    chain.interval(0..1).call("data")

    # Equivalent to v8_to_9.v9_to_10.v10_to_11

    chain.up_to(2).call("data")
    ```

3. The Explicit Manual Aproach

    If you prefer avoiding array iteration and want to explicitly combine them
    point-to-point as variables:

    ```ruby
    # Composite intervals saved as new independent pure functions
    step_1_to_2 = v8_to_9 >> v9_to_10
    step_1_to_3 = step_1_to_2 >> v10_to_11
    step_1_to_4 = step_1_to_3 >> v11_to_12

    step_1_to_4.call("data") # => "v12(v11(v10(v9(data))))"
    ```

### Summary Matrix of Slice Operations

| Target Interval | Array Slice Syntax      | Composition Logic                          |
| --------------- | ----------------------- | ------------------------------------------ |
| First 2 steps   | `pipeline_steps[0..1]`  | `step[0] >> step[1]`                       |
| First 3 steps   | `pipeline_steps[0..2]`  | `step[0] >> step[1] >> step[2]`            |
| All steps       | `pipeline_steps[0..-1]` | `step[0] >> step[1] >> step[2] >> step[3]` |
| Tail steps      | `pipeline_steps[1..-1]` | `step[1] >> step[2] >> step[3]`            |


## Applying An Ordered Set In Reverse Order

Calling `pipeline_steps[2..0]` will return an empty array `[]` in Ruby, so it will
not apply any functions at all.

This happens because Ruby's array slicing expects the starting index to be less
than or equal to the ending index when using positive integers. When the start
index is greater than the end index, Ruby considers the range invalid for
slicing and returns an empty collection.

Here are the correct approaches to slice and apply your functions in reverse order:

1. The Idiomatic Aproach: Slice and #reverse

    To get the first three steps and run them in reverse order, slice them
    normally first, reverse the array, and then reduce them using the forward
    pipeline operator (`>>`).

    ```ruby

    # 1. Grabs [v8_to_9, v9_to_10, v10_to_11]

    # 2. Reverses to [v10_to_11, v9_to_10, v8_to_9]

    # 3. Composes them: v10_to_11 >> v9_to_10 >> v8_to_9

    reverse_pipeline = pipeline_steps[0..2].reverse.reduce(:>>)

    reverse_pipeline.call("data")

    # => "v9(v10(v11(data)))"
    ```

1. The Right-to-Left Aproach: Slice and `#reduce` (`:<<`)

    Instead of reversing the array elements, you can keep the sliced array order
    but change the composition direction by using the backward composition
    operator (<<). This feeds the data through the array from right to left.

    ```ruby
    # Slices [v8_to_9, v9_to_10, v10_to_11]

    # Composes backward: v8_to_9 << v9_to_10 << v10_to_11

    # Execution order: v10_to_11 runs first, then v9_to_10, then v8_to_9

    reverse_pipeline = pipeline_steps[0..2].reduce(:<<)

    reverse_pipeline.call("data")

    # => "v9(v10(v11(data)))"
    ```

### Comparison of the Approaches

| Approach                     | Sliced Array Order | Composition Operator | Execution Order                               |
| ---------------------------- | ------------------ | -------------------- | --------------------------------------------- |
| `[0..2].reverse.reduce(:>>)` | `[v10, v9, v8]`    | Forward (`>>`)       | `v10 \(\rightarrow \) v9 \(\rightarrow \) v8` |
| `[0..2].reduce(:<<)`         | `[v8, v9, v10]`    | Backward (`<<`)      | `v10 \(\rightarrow \) v9 \(\rightarrow \) v8` |


## Downgrading Data Structures

TODO how much of this is relevant for bidi XSLT methods?

Downgrading an XML structure across versions via pure functions requires careful
handling, as reversing structural transformations can often result in data loss
or structural mismatches if elements or attributes do not have a 1:1 fallback.

When dealing with a structural downgrade (like an XML schema migration), using
`pipeline_steps[0..2].reduce(:<<)` or `pipeline_steps[0..2].reverse.reduce(:>>)`
works perfectly from a syntax perspective, but you must ensure your functions
are designed to handle structural compatibility.

Here are the best practices and patterns for managing XML downgrades with pure
pipelines in Ruby:

1. Handling Missing Data

    When upgrading from v8 to v11, fields are typically added or combined. When
    downgrading back to v8, your pure functions need to explicitly handle how to
    drop or translate those newer fields.

    Using a library like Nokogiri ensures your functional pipeline handles XML nodes
    cleanly without side effects, provided you parse and duplicate the document
    within each step.

    ```ruby
    require 'nokogiri'

    # Pure function: accepts an XML string, returns a downgraded XML string
    v11_to_10 = ->(xml_string) {
      doc = Nokogiri::XML(xml_string)

      # Structural modification: e.g., Rename <user_id> back to <uid>
      if user_id = doc.at_css('user_id')
        user_id.name = 'uid'
      end

      # Remove a field that v10 doesn't support
      doc.at_css('new_v11_feature')&.remove

      doc.to_xml
    }

    v10_to_9 = ->(xml_string) {
      doc = Nokogiri::XML(xml_string)
      # Downgrade logic from 10 to 9 here...
      doc.to_xml
    }
    ```

2. Dual-Direction Version Registry Pattern

    If your application needs to handle both upgrades and downgrades frequently, it
    is risky to rely purely on array indices ([0..2]). Instead, group your upgrade
    and downgrade lambdas into a single, cohesive schema registry object.

    ```ruby
    class XmlVersionSchema

    # Define pure transformation steps explicitly

      UPGRADES = {
        8  => ->(xml) { xml.gsub('<uid>', '<user_id>') },
        9  => ->(xml) { xml.gsub('<phone>', '<contact_phone>') },
        10 => ->(xml) { xml.gsub('<street>', '<address_line_1>') }
      }.freeze

      DOWNGRADES = {
        11 => ->(xml) { xml.gsub('<address_line_1>', '<street>') },
        10 => ->(xml) { xml.gsub('<contact_phone>', '<phone>') },
        9  => ->(xml) { xml.gsub('<user_id>', '<uid>') }
      }.freeze

    # Explicitly compose a downgrade path from any start version to target version

      def self.downgrade(from:, to:, xml:)
        steps = DOWNGRADES.select { |version, _| version <= from && version > to }.values

        if steps.any?
          pipeline = steps.reduce(:>>) # Ex: 11_to_10 >> 10_to_9 >> 9_to_8
          pipeline.call(xml)
        else
          xml # Already at or below target version
        end
      end
    end

    # Usage

    # Downgrades automatically through 11->10, then 10->9, then 9->8

    v8_xml = XmlVersionSchema.downgrade(from: 11, to: 8, xml: current_v11_xml)
    ```

3. Schema Validation as a Safety Valve

    Because XML structures are strictly bound to schemas (XSDs), you can turn your
    functional composition into an Either/Result pattern to ensure a downgrade
    didn't inadvertently break the target version's schema rules.

    ```ruby
    # Wrapping execution to ensure the downgraded XML is actually valid v8 XML

    ```ruby
    def safe_downgrade(xml_pipeline, xml_input, target_xsd_path)
      downgraded_xml = xml_pipeline.call(xml_input)

      doc = Nokogiri::XML(downgraded_xml)
      xsd = Nokogiri::XML::Schema(File.read(target_xsd_path))

      errors = xsd.validate(doc)

      if errors.empty?
        { success: true, xml: downgraded_xml }
      else
        { success: false, errors: errors.map(&:message) }
      end
    end
    ```


## Avoiding Redundant Deserialization

The above examples show XML strings being passed around. This requires
serialization and deserialization to/from Nokogiri objects for each pure
function. It would be more efficient to convert XML strings to Nokogiri objects
before calling pure functions, so the pure functions receive Nokogiri objects
instead.

Parsing and serializing XML to/from a string inside every single function
introduces massive CPU and memory overhead, especially in a multi-step pipeline.

To optimize this, pure functions should accept and return Nokogiri objects
directly, keeping the document entirely in-memory as an Abstract Syntax Tree
(AST) throughout the transformation process. The string serialization and
deserialization should only happen as "bookends" at the absolute start and end
of the pipeline.

However, to keep these functions truly pure, we must address a critical detail:
Nokogiri objects are highly mutable. If a function modifies a node directly, it
mutates the object in place, which violates the core definition of a pure
function.

Here is how to design a high-performance, mutation-safe Nokogiri pipeline.

1. Enforcing Purity with `#dup`

    To ensure each function is pure (has no side effects on the input object), each
    step must first clone the incoming Nokogiri document using `.dup` before making
    modifications.

    ```ruby
    require 'nokogiri'

    # Pure functions: Accept a Nokogiri Document, return a NEW Nokogiri Document

    v11_to_10 = ->(doc) {
      next_doc = doc.dup # Clone to guarantee purity

      if user_id = next_doc.at_css('user_id')
        user_id.name = 'uid'
      end
      next_doc.at_css('new_v11_feature')&.remove

      next_doc # Return the new state
    }

    v10_to_9 = ->(doc) {
      next_doc = doc.dup

    # Perform structural alterations on next_doc

      next_doc
    }
    ```

2. Composing the "In-Memory" Pipeline with String Bookends

    Now we can chain our pure Nokogiri transformations together and wrap the entire
    pipeline with a single parse phase at the entry point, and a single
    serialization phase at the exit point.

    ```ruby
    # Array of pure in-memory transformations

    downgrade_steps = [v11_to_10, v10_to_9]

    # Compose the structural transformation pipeline
    structural_pipeline = downgrade_steps.reduce(:>>)

    # Define the input/output bookends
    parse_xml     = ->(xml_string) { Nokogiri::XML(xml_string) }
    serialize_xml = ->(nokogiri_doc) { nokogiri_doc.to_xml }

    # Compose the complete end-to-end pipeline

    # String -> Nokogiri Doc -> [Transformations...] -> Nokogiri Doc -> String
    full_process = parse_xml >> structural_pipeline >> serialize_xml

    # Execution
    v11_xml_string = "<root><user_id>123</user_id><new_v11_feature/></root>"
    v9_xml_string  = full_process.call(v11_xml_string)
    ```

### Performance Comparison: Before vs. After

| Metric                  | String Passing                      | In-Memory Object Passing                   |
| ----------------------- | ----------------------------------- | ------------------------------------------ |
| Parsing Overhead        | N times ()                          | 1 time (at entry)                          |
| Serialization Overhead  | N times                             | 1 time (at exit)                           |
| Memory Allocation       | High (creates new garbage per step) | Low (allocates lightweight C-backed nodes) |
| Garbage Collection (GC) | Frequent pressure                   | Minimal                                    |

Where N is the number of steps.


### Alternative: When "Pure Mutation" is Allowed (Performance Optimization)

If you are processing massive XML documents and even `.dup` causes a noticeable
memory bottleneck, functional programming permits an optimization called
Isolated Mutation.

If the initial `parse_xml` step creates a document that no other part of your
system has a reference to, you can allow the intermediate steps to mutate the
document in-place, because the overall pipeline function remains pure to the
outside world:

```ruby
# In-place mutating function (Faster, but lacks isolation if used standalone)
v11_to_10_fast = ->(doc) {
  doc.at_css('user_id')&.name = 'uid'
  doc.at_css('new_v11_feature')&.remove
  doc # Return same object reference
}

# The overall chain 'full_process' behaves as a pure function
# Given the same XML string input, it always returns the same XML string output
# with zero side-effects leaking to the rest of the application
```

**Since each transformation function is invoked at most once during program
execution, you can safely leverage isolated mutation to achieve maximum
performance.**

Because the initial string-to-Nokogiri parsing step yields a fresh document
reference that no other part of your system can access, mutating it in-place
within the pipeline is completely safe. The wrapper function behaves perfectly
as a pure function to the outside world—accepting a string, returning a new
string, and producing zero side effects—while avoiding the CPU and memory
overhead of copying the XML tree with .dup at every step.

A flag should be embedded in each Nokogiri object that indicates it has been
mutated. Throw an exception if a second mutation is attempted.

### The Optimized In-Place Pipeline

Here is how to structure the pipeline for single-invocation efficiency.

TODO add a flag to guard against mutating more than once.

```ruby
require 'nokogiri'

# 1. Mutating Functions (Fast, in-memory modifications)
v11_to_10 = ->(doc) {
  doc.at_css('user_id')&.name = 'uid'
  doc.at_css('new_v11_feature')&.remove
  doc # Return the same doc reference
}

v10_to_9 = ->(doc) {
  # Direct, highly efficient in-place updates
  if node = doc.at_css('contact_phone')
    node.name = 'phone'
  end
  doc
}

# 2. Bookend Functions
parse_xml     = ->(str) { Nokogiri::XML(str) }
serialize_xml = ->(doc) { doc.to_xml(indent: 2) } # Or format as needed

# 3. Composing the Steps
downgrade_steps     = [v11_to_10, v10_to_9]
in_memory_pipeline  = downgrade_steps.reduce(:>>)

# 4. Final End-to-End Pure Pipeline
# String Input -> Parse -> Mutate In-Memory (Once) -> String Output
execute_downgrade = parse_xml >> in_memory_pipeline >> serialize_xml
```

### Execution Example

```ruby
v11_xml = <<~XML
  <root>
    <user_id>456</user_id>
    <contact_phone>555-1234</contact_phone>
    <new_v11_feature>Enabled</new_v11_feature>
  </root>
XML

v9_xml = execute_downgrade.call(v11_xml)
puts v9_xml

# Output
# <root>
# <uid>456</uid>
# <phone>555-1234</phone>
# </root>
```

### Key Operational Benefits

• O(1) Memory Allocations: Ruby allocates memory for exactly one Nokogiri
Document node tree regardless of whether you have 2 steps or 20 steps.

• Zero Garbage Collection Spikes: Because intermediate strings and cloned
documents are eliminated, the Ruby Garbage Collector doesn't have to clean up
dead object trees after each version step finishes.

• Maintained Unit Testability: Even though the functions mutate their inputs,
you can still test them individually by passing a fresh Nokogiri::XML("...")
block directly into them during your test assertions.

Would you like to build an automated runner that reads these version steps
dynamically based on target XSD attributes, or do you want to add logging to
capture what fields get dropped during single-pass downgrades?

## Using The Ordered Set

To dynamically extract and compose the exact transformation steps from your
ordered set without writing them out manually, you can use array indexing based
on version numbers.

By structuring your ordered set as a Hash (or an array where indices map to
versions), you can use a Ruby Range to slice out the exact interval you need and
chain them automatically.

Here is the most idiomatic way to achieve this using a Version Registry.


### The Idiomatic Way: Version-Keyed Registry

Instead of managing an anonymous array, map the functions directly to the
versions they target. This allows you to request an interval like 11..9
programmatically.

To make the key represent the desired end state (the version we are moving TO)
for both directions, we define a semantic rule:

• `:down` means: "How do I get to v10 from v11?" (`v11_to_10`)
• `:up` means: "How do I get to v10 from v9?" (`v9_to_10`)

```ruby
# 1. The Ordered Set, defined by target versions
# The key represents the version we are downgrading TO or upgrading FROM

# The Single Source of Truth
# The key strictly represents the version we are moving TO (the target destination)
# Each value is a bidirectional transformation wrapper capable of running forward or backward.
VERSION_REGISTRY = {
  8  => nil,              # Base version (nothing transforms an earlier version up TO v8)
  9  => xslt_v8_to_9,     # Moves up TO v9 forward, or down TO v8 reversed
  10 => xslt_v9_to_10,    # Moves up TO v10 forward, or down TO v9 reversed
  11 => xslt_v10_to_11,   # Moves up TO v11 forward, or down TO v10 reversed
  12 => xslt_v11_to_12    # Moves up TO v12 forward, or down TO v11 reversed
}.freeze


# 2. Idiomatic helper to slice and compose the interval
def build_downgrade_pipeline(from:, to:)
  # For 11 down to 8 -> Grabs keys 9, 10, 11
  bridges = VERSION_REGISTRY.select do |target_version, transformation|
    target_version > to && target_version <= from && transformation
  end.values

  # 1. Map each bridge to its inverse function
  # 2. Reverse the array so the highest version executes first: [v10_to_11.inverse, v9_to_10.inverse, v8_to_9.inverse]
  steps = bridges.map(&:inverse).reverse

  # Compose left-to-right
  steps.reduce(:>>)
end

def build_upgrade_pipeline(from:, to:)
  # For 9 up to 12 -> Grabs keys 10, 11, 12
  bridges = VERSION_REGISTRY.select do |target_version, transformation|
    target_version > from && target_version <= to && transformation
  end.values

  # Map each bridge to its forward function: [v9_to_10.forward, v10_to_11.forward, v11_to_12.forward]
  steps = bridges.map(&:forward)

  # Compose left-to-right
  steps.reduce(:>>)
end
```

Here is how the version intervals map to your single registry keys across
execution paths:

```plain
[v8] <=== key 9 (xslt_v8_to_9) ===> [v9] <=== key 10 (xslt_v9_to_10) ===> [v10] <=== key 11 (xslt_v10_to_11) ===> [v11]

UPWARD PATH (from: 9, to: 11)    => Uses keys: [10, 11]     => Direction: .forward
DOWNWARD PATH (from: 11, to: 8)  => Uses keys: [11, 10, 9]  => Direction: .inverse (Executed 11 -> 10 -> 9)
```

### Putting it Together with the Bookends

Whichever method you choose to extract the slice, you combine it with your
string bookends exactly the same way.

Given an ordered set of pure functions:

```ruby
[v8_to_9, v9_to11, v10_to_11, v11_to_12]
```

Show various ways to compose intervals in the set, e.g.:

```ruby
v8_to_9.v9_to11
v8_to_9.v9_to11.v10_to_11
v8_to_9.v9_to11.v10_to_11.v11_to_12
```

To compose specific intervals (or slices) from an ordered set of functions in
Ruby, the most idiomatic approach is combining array slicing with
Enumerable#reduce using the forward composition operator (>>).

Here are the various ways to achieve this, from direct slicing to building a
dynamic pipeline helper.

### Setup

Assuming your pure functions are defined as lambdas or procs inside an ordered array:

```ruby
v8_to_9   = ->(x) { "v9(#{x})" }
v9_to_10  = ->(x) { "v10(#{x})" }
v10_to_11 = ->(x) { "v11(#{x})" }
v11_to_12 = ->(x) { "v12(#{x})" }

# The ordered set
pipeline_steps = [v8_to_9, v9_to_10, v10_to_11, v11_to_12]
```

1. The Idiomatic Way: Array Slicing + reduce(:>>)

    You can extract any interval using Ruby's range slicing ([start..end]) and chain
    them together using reduce(:>>) to return a single composed pure function.

    ```ruby
    # Interval 1: v8_to_9 >> v9_to_10
    v8_to_10 = pipeline_steps[0..1].reduce(:>>)
    v8_to_10.call("data") # => "v10(v9(data))"

    # Interval 2: v8_to_9 >> v9_to_10 >> v10_to_11
    v8_to_11 = pipeline_steps[0..2].reduce(:>>)
    v8_to_11.call("data") # => "v11(v10(v9(data)))"

    # Interval 3: Full pipeline (v8 through v12)
    full_pipeline = pipeline_steps.reduce(:>>)
    full_pipeline.call("data") # => "v12(v11(v10(v9(data))))"

    # Interval 4: Middle slice (v9 to v12)
    v9_to_12 = pipeline_steps[1..3].reduce(:>>)
    v9_to_12.call("data") # => "v12(v11(v10(data)))"
    ```

2. The Semantic Way: A Dedicated Pipeline Wrapper

    If you frequently compose intervals, you can wrap the array in a small utility
    class that allows you to fetch intervals by descriptive indices or keys.

    ```ruby
    class FunctionChain
      def initialize(steps)
        @steps = steps
      end

      # Compose an interval using a standard Ruby Range
      def interval(range)
        @steps[range].reduce(:>>)
      end

      # Compose from the beginning up to a specific step index
      def up_to(index)
        interval(0..index)
      end
    end

    # Usage:
    chain = FunctionChain.new(pipeline_steps)

    # Equivalent to v8_to_9.v9_to_10
    chain.interval(0..1).call("data")

    # Equivalent to v8_to_9.v9_to_10.v10_to_11
    chain.up_to(2).call("data")
    ```

3. The Explicit Manual Way

    If you prefer avoiding array iteration and want to explicitly combine them point-to-point as variables:

    ```ruby
    # Composite intervals saved as new independent pure functions
    step_1_to_2 = v8_to_9 >> v9_to_10
    step_1_to_3 = step_1_to_2 >> v10_to_11
    step_1_to_4 = step_1_to_3 >> v11_to_12

    step_1_to_4.call("data") # => "v12(v11(v10(v9(data))))"
    ```

### Summary Matrix of Slice Operations

Target Interval	Array Slice Syntax	Composition Logic
First 2 steps	pipeline_steps[0..1]	step[0] >> step[1]
First 3 steps	pipeline_steps[0..2]	step[0] >> step[1] >> step[2]
All steps	pipeline_steps[0..-1]	step[0] >> step[1] >> step[2] >> step[3]
Tail steps	pipeline_steps[1..-1]	step[1] >> step[2] >> step[3]

Would this apply the first 3 steps in reverse order?

No, calling pipeline_steps[2..0] will return an empty array [] in Ruby, so it
will not apply any functions at all.

This happens because Ruby's array slicing expects the starting index to be less
than or equal to the ending index when using positive integers. When the start
index is greater than the end index, Ruby considers the range invalid for
slicing and returns an empty collection.

Here are the correct ways to slice and apply your functions in reverse order:

1. The Idiomatic Way: Slice and #reverse

    To get the first three steps and run them in reverse order, you slice them
    normally first, reverse the array, and then reduce them using the forward
    pipeline operator (>>).

    ```ruby
    # 1. Grabs [v8_to_9, v9_to_10, v10_to_11]
    # 2. Reverses to [v10_to_11, v9_to_10, v8_to_9]
    # 3. Composes them: v10_to_11 >> v9_to_10 >> v8_to_9
    reverse_pipeline = pipeline_steps[0..2].reverse.reduce(:>>)

    reverse_pipeline.call("data")
    # => "v9(v10(v11(data)))"
    ```

2. The Right-to-Left Way: Slice and #reduce(:<<)

    Instead of reversing the array elements, you can keep the sliced array order but
    change the composition direction by using the backward composition operator
    (<<). This feeds the data through the array from right to left.

    ```ruby
    # Slices [v8_to_9, v9_to_10, v10_to_11]
    # Composes backward: v8_to_9 << v9_to_10 << v10_to_11
    # Execution order: v10_to_11 runs first, then v9_to_10, then v8_to_9
    reverse_pipeline = pipeline_steps[0..2].reduce(:<<)

    reverse_pipeline.call("data")
    # => "v9(v10(v11(data)))"
    ```

### Comparison of the two approaches

Approach	Sliced Array Order	Composition Operator	Execution Order
[0..2].reverse.reduce(:>>)	[v10, v9, v8]	Forward (>>)	v10 \(\rightarrow \) v9 \(\rightarrow \) v8
[0..2].reduce(:<<)	[v8, v9, v10]	Backward (<<)	v10 \(\rightarrow \) v9 \(\rightarrow \) v8

Reversing means an XML structure is being downgraded to a previous version.

Downgrading an XML structure across versions via pure functions requires careful
handling, as reversing structural transformations can often result in data loss
or structural mismatches if elements or attributes do not have a 1:1 fallback.

When dealing with a structural downgrade (like an XML schema migration), using
pipeline_steps[0..2].reduce(:<<) or pipeline_steps[0..2].reverse.reduce(:>>)
works perfectly from a syntax perspective, but you must ensure your functions
are designed to handle structural compatibility.

Here are the best practices and patterns for managing XML downgrades with pure
pipelines in Ruby:

1. Handling Missing Data (The Structural Dilemma)

    When upgrading from v8 to v11, fields are typically added or combined. When
    downgrading back to v8, your pure functions need to explicitly handle how to
    drop or translate those newer fields.

    Using a library like Nokogiri ensures your functional pipeline handles XML nodes
    cleanly without side effects, provided you parse and duplicate the document
    within each step.

    ```ruby
    require 'nokogiri'

    # Pure function: accepts an XML string, returns a downgraded XML string
    v11_to_10 = ->(xml_string) {
      doc = Nokogiri::XML(xml_string)

      # Structural modification: e.g., Rename <user_id> back to <uid>
      if user_id = doc.at_css('user_id')
        user_id.name = 'uid'
      end

      # Remove a field that v10 doesn't support
      doc.at_css('new_v11_feature')&.remove

      doc.to_xml
    }

    v10_to_9 = ->(xml_string) {
      doc = Nokogiri::XML(xml_string)
      # Downgrade logic from 10 to 9...
      doc.to_xml
    }
    ```

2. Dual-Direction Version Registry Pattern

    If your application needs to handle both upgrades and downgrades frequently, it
    is risky to rely purely on array indices ([0..2]).  Instead, group your upgrade
    and downgrade lambdas into a single, cohesive schema registry object.

    ```ruby
    class XmlVersionSchema
      # Define pure transformation steps explicitly
      UPGRADES = {
        8  => ->(xml) { xml.gsub('<uid>', '<user_id>') },
        9  => ->(xml) { xml.gsub('<phone>', '<contact_phone>') },
        10 => ->(xml) { xml.gsub('<street>', '<address_line_1>') }
      }.freeze

      DOWNGRADES = {
        11 => ->(xml) { xml.gsub('<address_line_1>', '<street>') },
        10 => ->(xml) { xml.gsub('<contact_phone>', '<phone>') },
        9  => ->(xml) { xml.gsub('<user_id>', '<uid>') }
      }.freeze

      # Explicitly compose a downgrade path from any start version to target version
      def self.downgrade(from:, to:, xml:)
        steps = DOWNGRADES.select { |version, _| version <= from && version > to }.values

        if steps.any?
          pipeline = steps.reduce(:>>) # Ex: 11_to_10 >> 10_to_9 >> 9_to_8
          pipeline.call(xml)
        else
          xml # Already at or below target version
        end
      end
    end

    # Usage:
    # Downgrades automatically through 11->10, then 10->9, then 9->8
    v8_xml = XmlVersionSchema.downgrade(from: 11, to: 8, xml: current_v11_xml)
    ```

3. Schema Validation as a Safety Valve

    Because XML structures are strictly bound to schemas (XSDs), you can turn your
    functional composition into an Either/Result pattern to ensure a downgrade
    didn't inadvertently break the target version's schema rules.

    ```ruby
    # Wrapping execution to ensure the downgraded XML is actually valid v8 XML
    def safe_downgrade(xml_pipeline, xml_input, target_xsd_path)
      downgraded_xml = xml_pipeline.call(xml_input)

      doc = Nokogiri::XML(downgraded_xml)
      xsd = Nokogiri::XML::Schema(File.read(target_xsd_path))

      errors = xsd.validate(doc)

      if errors.empty?
        { success: true, xml: downgraded_xml }
      else
        { success: false, errors: errors.map(&:message) }
      end
    end
    ```

## Minimizing XML Deserialization

The above examples show XML strings being passed around. This requires
serialization and deserialization to/from Nokogiri objects for each pure
function. It would be more efficient to convert XML strings to Nokogiri objects
before calling pure functions, so the pure functions receive Nokogiri objects
instead.

You are entirely correct. Parsing and serializing XML to/from a string inside
every single function introduces massive CPU and memory overhead, especially in
a multi-step pipeline.

To optimize this, your pure functions should accept and return Nokogiri objects
directly, keeping the document entirely in-memory as an Abstract Syntax Tree
(AST) throughout the transformation process. The string serialization and
deserialization should only happen as "bookends" at the absolute start and end
of the pipeline.

However, to keep these functions truly pure, we must address a critical detail:
Nokogiri objects are highly mutable. If a function modifies a node directly, it
mutates the object in place, which violates the core definition of a pure
function.

Here is how to design a high-performance, mutation-safe Nokogiri pipeline.

1. Enforcing Purity with #dup

    To ensure each function is pure (has no side effects on the input object), each
    step must first clone the incoming Nokogiri document using .dup before making
    modifications.

    ```ruby
    require 'nokogiri'

    # Pure functions: Accept a Nokogiri Document, return a NEW Nokogiri Document
    v11_to_10 = ->(doc) {
      next_doc = doc.dup # Clone to guarantee purity

      if user_id = next_doc.at_css('user_id')
        user_id.name = 'uid'
      end
      next_doc.at_css('new_v11_feature')&.remove

      next_doc # Return the new state
    }

    v10_to_9 = ->(doc) {
      next_doc = doc.dup
      # Perform structural alterations on next_doc...
      next_doc
    }
    ```

2. Composing the "In-Memory" Pipeline with String Bookends

    Now we can chain our pure Nokogiri transformations together and wrap the entire
    pipeline with a single parse phase at the entry point, and a single
    serialization phase at the exit point.

    ```ruby
    # Array of pure in-memory transformations
    downgrade_steps = [v11_to_10, v10_to_9]

    # Compose the structural transformation pipeline
    structural_pipeline = downgrade_steps.reduce(:>>)

    # Define the input/output bookends
    parse_xml     = ->(xml_string) { Nokogiri::XML(xml_string) }
    serialize_xml = ->(nokogiri_doc) { nokogiri_doc.to_xml }

    # Compose the complete end-to-end pipeline:
    # String -> Nokogiri Doc -> [Transformations...] -> Nokogiri Doc -> String
    full_process = parse_xml >> structural_pipeline >> serialize_xml

    # Execution
    v11_xml_string = "<root><user_id>123</user_id><new_v11_feature/></root>"
    v9_xml_string  = full_process.call(v11_xml_string)
    ```

### Performance Comparison: Before vs. After

Metric	String Passing (Previous)	In-Memory Object Passing (Optimized)
Parsing Overhead	N times (where N = number of steps)	Exactly 1 time (at entry)
Serialization Overhead	N times	Exactly 1 time (at exit)
Memory Allocation	High (creates new string garbage per step)	Low (allocates lightweight C-backed nodes)
Garbage Collection (GC)	Frequent pressure	Minimal


## Alternative: When "Pure Mutation" is Allowed (Performance Optimization)

If you are processing massive XML documents and even .dup causes a noticeable
memory bottleneck, functional programming permits an optimization called
Isolated Mutation.

If the initial parse_xml step creates a document that no other part of your
system has a reference to, you can technically allow the intermediate steps to
mutate the document in-place, because the overall pipeline function remains pure
to the outside world:

```ruby
# In-place mutating function (Faster, but lacks isolation if used standalone)
v11_to_10_fast = ->(doc) {
  doc.at_css('user_id')&.name = 'uid'
  doc.at_css('new_v11_feature')&.remove
  doc # Return same object reference
}

# The overall chain 'full_process' behaves as a pure function:
# Given the same XML string input, it always returns the same XML string output,
# with zero side-effects leaking to the rest of the application.
```

**Each transformation will only be invoked once.**

Since each transformation function is invoked exactly once during the lifecycle
of the downgrade operation, you can safely leverage isolated mutation to achieve
maximum performance.

Because the initial string-to-Nokogiri parsing step yields a fresh document
reference that no other part of your system can access, mutating it in-place
within the pipeline is completely safe. The wrapper function behaves perfectly
as a pure function to the outside world—accepting a string, returning a new
string, and producing zero side effects—while avoiding the CPU and memory
overhead of copying the XML tree with .dup at every step.

### The Optimized In-Place Pipeline

Here is how to structure the pipeline for single-invocation efficiency:

```ruby
require 'nokogiri'

# 1. Mutating Functions (Fast, in-memory modifications)
v11_to_10 = ->(doc) {
  doc.at_css('user_id')&.name = 'uid'
  doc.at_css('new_v11_feature')&.remove
  doc # Return the same doc reference
}

v10_to_9 = ->(doc) {
  # Direct, highly efficient in-place updates
  if node = doc.at_css('contact_phone')
    node.name = 'phone'
  end
  doc
}

# 2. Bookend Functions
parse_xml     = ->(str) { Nokogiri::XML(str) }
serialize_xml = ->(doc) { doc.to_xml(indent: 2) } # Or format as needed

# 3. Composing the Steps
downgrade_steps     = [v11_to_10, v10_to_9]
in_memory_pipeline  = downgrade_steps.reduce(:>>)

# 4. Final End-to-End Pure Pipeline
# String Input -> Parse -> Mutate In-Memory (Once) -> String Output
execute_downgrade = parse_xml >> in_memory_pipeline >> serialize_xml
```

### Execution Example

```ruby
v11_xml = <<~XML
  <root>
    <user_id>456</user_id>
    <contact_phone>555-1234</contact_phone>
    <new_v11_feature>Enabled</new_v11_feature>
  </root>
XML

v9_xml = execute_downgrade.call(v11_xml)
puts v9_xml
# Output:
# <root>
#   <uid>456</uid>
#   <phone>555-1234</phone>
# </root>
```

### Key Operational Benefits

• O(1) Memory Allocations: Ruby allocates memory for exactly one Nokogiri
Document node tree regardless of whether you have 2 steps or 20 steps.

• Zero Garbage Collection Spikes: Because intermediate strings and cloned
documents are eliminated, the Ruby Garbage Collector doesn't have to clean up
dead object trees after each version step finishes.

• Maintained Unit Testability: Even though the functions mutate their inputs,
you can still test them individually by passing a fresh Nokogiri::XML("...")
block directly into them during your test assertions.


I want an idiomatic way of writing:

```ruby
downgrade_steps     = [v11_to_10, v10_to_9]
```

That leverages the ordered set instead of writing out each pure function

To dynamically extract and compose the exact transformation steps from your
ordered set without writing them out manually, you can use array indexing based
on version numbers.

By structuring your ordered set as a Hash (or an array where indices map to
versions), you can use a Ruby Range to slice out the exact interval you need and
chain them automatically.

Here is the most idiomatic way to achieve this using a Version Registry.

## The Idiomatic Way: Version-Keyed Registry

Instead of managing an anonymous array, map the functions directly to the
versions they target. This allows you to request an interval like 11..9
programmatically.

```ruby
# 1. The Ordered Set, defined by target versions
# The key represents the version we are downgrading FROM
DOWNGRADE_REGISTRY = {
  12 => v12_to_11,
  11 => v11_to_10,
  10 => v10_to_9,
  9  => v9_to_8
}.freeze

# 2. Idiomatic helper to slice and compose the interval
def build_downgrade_pipeline(from:, to:)
  # Select only the keys that fall within our downgrade window
  # For 11 down to 9, this grabs keys 11 and 10
  steps = DOWNGRADE_REGISTRY.select { |version, _| version <= from && version > to }.values

  # Compose them left-to-right (v11_to_10 >> v10_to_9)
  steps.reduce(:>>)
end
```

### Alternative: Using a Zero-Indexed Array

If your ordered set must remain a plain Array, you can map your versions to
array indices using a simple formula: index = max_version - current_version.

```ruby
# Array ordered from highest version down to lowest
# index 0 = v12->v11, index 1 = v11->v10, index 2 = v10->v9
ALL_DOWNGRADES = [v12_to_11, v11_to_10, v10_to_9, v9_to_8].freeze

def build_pipeline_from_array(from:, to:)
  max_version = 12

  start_index = max_version - from  # e.g., 12 - 11 = index 1
  end_index   = max_version - to - 1 # e.g., 12 - 9 - 1 = index 2

  # Slice the array dynamically and compose
  ALL_DOWNGRADES[start_index..end_index].reduce(:>>)
end
```

### Putting it Together with the Bookends

Whichever method you choose to extract the slice, you combine it with your
string bookends exactly the same way:

```ruby
parse_xml     = ->(str) { Nokogiri::XML(str) }
serialize_xml = ->(doc) { doc.to_xml }

# Dynamically build the intermediate pipeline from version 11 down to 9
in_memory_pipeline = build_downgrade_pipeline(from: 11, to: 9)

# Combine into the final pure process
execute_downgrade = parse_xml >> in_memory_pipeline >> serialize_xml

# Execution
v9_xml_string = execute_downgrade.call(v11_xml_string)
```

### Why this is idiomatic

• Self-Documenting: Passing from: 11, to: 9 clearly communicates the intent of
the code compared to zero-based array slicing like [1..2].

• Configurable: If you add a v13_to_12 step in the future, you only update the
registry hash. The pipeline builder logic remains completely untouched.


Show a method for upgrading:

```ruby
# 1. The Ordered Set, defined by target versions
# The key represents the version we are downgrading FROM
DOWNGRADE_REGISTRY = {
  12 => v12_to_11,
  11 => v11_to_10,
  10 => v10_to_9,
  9  => v9_to_8
}.freeze

# 2. Idiomatic helper to slice and compose the interval
def build_downgrade_pipeline(from:, to:)
  # Select only the keys that fall within our downgrade interval
  # For 11 down to 9, this grabs keys 11 and 10
  steps = DOWNGRADE_REGISTRY.select do |version, _|
    version <= from && version > to
  end.values

  # Compose them left-to-right (v11_to_10 >> v10_to_9)
  steps.reduce(:>>)
end
```

To build the matching upgrade pipeline using the exact same registry, you can
invert the lookup logic.

Because the DOWNGRADE_REGISTRY contains functions moving downward (e.g., 11 =>
v11_to_10), we can leverage backward composition (<<) or reverse the extracted
array to make the data flow upward instead.

However, since pure functions for XML upgrades typically require different
structural operations than downgrades, the most idiomatic design pattern is to
maintain an explicit UPGRADE_REGISTRY. This keeps the direction crystal clear
and prevents tricky reverse-mapping logic.

### Method 1: The Explicit Registry Pattern (Recommended)

This approach maps the version you are upgrading FROM directly to its upward step. It mirrors your downgrade logic identically, making it highly readable and simple to maintain.

```ruby
UPGRADE_REGISTRY = {
  8  => v8_to_9,
  9  => v9_to_10,
  10 => v10_to_11,
  11 => v11_to_12
}.freeze

def build_upgrade_pipeline(from:, to:)
  # Select keys within the upgrade window
  # For 9 up to 11, this grabs keys 9 and 10
  steps = UPGRADE_REGISTRY.select do |version, _|
    version >= from && version < to
  end.values

  # Compose left-to-right (v9_to_10 >> v10_to_11)
  steps.reduce(:>>)
end
```

### Method 2: Reusing the Downgrade Registry (Bi-directional Mapping)

If your transformation steps are perfectly invertible or you explicitly want a single source of truth for your version chain order, you can reconstruct the upgrade flow directly from your existing DOWNGRADE_REGISTRY.

To move upward from version 9 to 11, you need to grab the functions for keys 10 and 11, but execute them in reverse sequence (the v9_to_10 conceptual equivalent executed before v10_to_11).

```ruby
# Reusing your EXACT registry definition
DOWNGRADE_REGISTRY = {
  12 => v12_to_11,
  11 => v11_to_10,
  10 => v10_to_9,
  9  => v9_to_8
}.freeze

def build_upgrade_pipeline_from_downgrade(from:, to:)
  # 1. Grab keys matching the interval (For 9 to 11, we need steps targeting 10 and 11)
  #    This selects keys 11 and 10 -> [v11_to_10, v10_to_9]
  steps = DOWNGRADE_REGISTRY.select do |version, _|
    version > from && version <= to
  end.values

  # 2. To upgrade, we must run the lowest step first.
  #    We reverse the array to get: [v10_to_9, v11_to_10]
  # 3. We use backward composition (<<) so the data flows backwards through the downgrades
  #    Resulting Execution: input -> v10_to_9 (acts as 9->10) -> v11_to_10 (acts as 10->11)
  steps.reverse.reduce(:<<)
end
```

### Comparison of the two approaches


Strategy	Readability	Maintenance	Execution Concept
Method 1 (Two Registries)	Excellent. Code clearly reflects standard business upgrades.	Requires updating two hashes when versions change.	Forward execution (>>)
Method 2 (Single Registry)	Complex. Mentally reversing downgrade code to upgrade data can be error-prone.	Zero maintenance duplicate risk.	Backward execution (<<)



```text
derive UPGRADE_REGISTRY  from DOWNGRADE_REGISTRY
```

If you want to maintain a single source of truth, you can programmatically
derive UPGRADE_REGISTRY from DOWNGRADE_REGISTRY at application boot time.

However, because pure functions themselves cannot be auto-reversed by Ruby
(e.g., Ruby doesn't know how to invert the logic inside your custom lambda), you
must manually map the complementary upgrade lambda alongside your downgrade
lambda, or use a structural container for each version.

Here are the two best ways to cleanly derive the upgrade registry from your
downgrade definition.

### Method 1: The Unified Step Registry (Recommended)

The most robust approach is to define a single VERSION_REGISTRY where each
version key explicitly points to a pair of upgrade/downgrade lambdas. You can
then instantly derive the one-sided registries using Ruby's #transform_values.

```ruby
# The Single Source of Truth
VERSION_REGISTRY = {
  9  => { up: v8_to_9,   down: v10_to_9 },
  10 => { up: v9_to_10,  down: v11_to_10 },
  11 => { up: v10_to_11, down: v12_to_11 },
  12 => { up: v11_to_12, down: nil } # Highest version has no upgrade
}.freeze

# Deriving DOWNGRADE_REGISTRY programmatically
DOWNGRADE_REGISTRY = VERSION_REGISTRY
  .transform_values { |v| v[:down] }
  .compact
  .freeze

# Deriving UPGRADE_REGISTRY programmatically
UPGRADE_REGISTRY = VERSION_REGISTRY
  .transform_values { |v| v[:up] }
  .compact
  .freeze
```

### Method 2: Dual-Value Hash Mapping

If your initial map must match your exact example layout, you can structure
`DOWNGRADE_REGISTRY` to hold a tuple `[downgrade_fn, upgrade_fn]`. From this, you
can cleanly invert the keys and extract the values to generate a standalone
`UPGRADE_REGISTRY`.

```ruby
# Key = version downgrading FROM. Value = [downgrade_fn, corresponding_upgrade_fn]
DOWNGRADE_REGISTRY = {
  12 => [v12_to_11, v11_to_12],
  11 => [v11_to_10, v10_to_11],
  10 => [v10_to_9,  v9_to_10],
  9  => [v9_to_8,   v8_to_9]
}.freeze

# Programmatically derive UPGRADE_REGISTRY from the above hash
UPGRADE_REGISTRY = DOWNGRADE_REGISTRY.each_with_object({}) do |(from_version, (down_fn, up_fn)), registry|
  # When downgrading FROM 11 (11->10), the matching upgrade is moving FROM 10 (10->11)
  target_upgrade_origin = from_version - 1
  registry[target_upgrade_origin] = up_fn
end.freeze
```

### Verification

Using either method above, you can now seamlessly call your pipeline builders
using completely independent, clean registries:

```ruby
# The upgrade pipeline matches your previous helper pattern perfectly
def build_upgrade_pipeline(from:, to:)
  steps = UPGRADE_REGISTRY.select do |version, _|
    version >= from && version < to
  end.values

  steps.reduce(:>>)
end

# Usage: v9_to_10 >> v10_to_11
upgrade_pipeline = build_upgrade_pipeline(from: 9, to: 11)
```

The VERSION_REGISTRY key represents the version we are downgrading TO.

In Method 1, the key represents the target version of the downgrade (the version
we are moving to).

To make this completely explicit, self-documenting, and clear to anyone reading
the code, we can rename the variables and keys to reflect their direction. Here
is that exact pattern written with explicit naming conventions:

```ruby
# The key explicitly represents the target version we are DOWNGRADING TO
VERSION_REGISTRY = {
  8  => { up_from_here: v8_to_9,   down_to_here: v9_to_8 },
  9  => { up_from_here: v9_to_10,  down_to_here: v10_to_9 },
  10 => { up_from_here: v10_to_11, down_to_here: v11_to_10 },
  11 => { up_from_here: v11_to_12, down_to_here: v12_to_11 }
}.freeze

# 1. Derived Downgrade Registry
# Key = The version we want to end up at (the destination)
DOWNGRADE_TO_REGISTRY = VERSION_REGISTRY
  .transform_values { |fns| fns[:down_to_here] }
  .freeze

# 2. Derived Upgrade Registry
# Key = The version we are starting at (the origin)
UPGRADE_FROM_REGISTRY = VERSION_REGISTRY
  .transform_values { |fns| fns[:up_from_here] }
  .freeze
```

How the Pipeline Helpers Look Now

With the registries derived this way, your interval-slicing logic becomes
incredibly intuitive because the hash keys perfectly match your from and to
variables.

### The Downgrade Pipeline

Since the key is the version we are downgrading to, we match all target versions
that are strictly less than our starting point, down to our destination.

```ruby
def build_downgrade_pipeline(from:, to:)
  # If downgrading from 11 down to 9, we need the functions that land us at 10 and 9
  steps = DOWNGRADE_TO_REGISTRY.select do |target_version, _|
    target_version < from && target_version >= to
  end.values

  # We reverse the order because select extracts them lowest-key-first (9, then 10)
  # Reversing gives us [v11_to_10, v10_to_9]
  steps.reverse.reduce(:>>)
end
```

The Upgrade Pipeline

Since the key is the version we are upgrading from, we simply grab the keys starting at our current version up to (but not including) our destination.

```ruby
def build_upgrade_pipeline(from:, to:)
  # If upgrading from 9 up to 11, we need the functions that start at 9 and 10
  steps = UPGRADE_FROM_REGISTRY.select do |origin_version, _|
    origin_version >= from && origin_version < to
  end.values

  # Extracts lowest-first naturally: [v9_to_10, v10_to_11]
  steps.reduce(:>>)
end
```

given this code:

```ruby
# 1. The Ordered Set, defined by target versions
# The key represents the version we are downgrading TO

# The Single Source of Truth
VERSION_REGISTRY = {
  9  => { up: v8_to_9,   down: v10_to_9 },
  10 => { up: v9_to_10,  down: v11_to_10 },
  11 => { up: v10_to_11, down: v12_to_11 },
  12 => { up: v11_to_12, down: nil } # Highest version has no upgrade
}.freeze

DOWNGRADE_REGISTRY = VERSION_REGISTRY
  .transform_values { |v| v[:down] }
  .compact
  .freeze

UPGRADE_REGISTRY = VERSION_REGISTRY
  .transform_values { |v| v[:up] }
  .compact
  .freeze

# 2. Idiomatic helper to slice and compose the interval

def build_downgrade_pipeline(from:, to:)
  # Select only the keys that fall within our downgrade interval
  # For 11 down to 9, this grabs keys 11 and 10
  steps = DOWNGRADE_REGISTRY.select do |version, _|
    version <= from && version > to
  end.values

  # Compose them left-to-right (v11_to_10 >> v10_to_9)
  steps.reduce(:>>)
end

def build_upgrade_pipeline(from:, to:)
  # Select keys within the upgrade window
  # For 9 up to 11, this grabs keys 9 and 10
  steps = UPGRADE_REGISTRY.select do |version, _|
    version >= from && version < to
  end.values

  # Compose left-to-right (v9_to_10 >> v10_to_11)
  steps.reduce(:>>)
end
```

## How to downgrade to v8?

To downgrade to v8, your current code will throw `NoMethodError: undefined
method '>>' for nil:NilClass`.

This happens because version 8 does not exist as a key in your VERSION_REGISTRY,
meaning there is no way to query DOWNGRADE_REGISTRY to find the final function
(v9_to_8) that lands you at v8.

Because your comment states "The key represents the version we are downgrading
TO", you need to add key 8 to the registry, and shift your mappings down so that
the keys accurately match where each function takes you.

Here is the corrected code setup and how to call it:

1. Fix the Registry Mapping

    Update your registry so that the keys match their downgrade-to target
    destination:

    • Key 8 should contain the function that lands you at v8 (v9_to_8).

    • Key 12 (the highest version) cannot be downgraded to, so its :down is nil.

    ```ruby
    # The key strictly represents the version we are downgrading TO (or upgrading FROM)
    VERSION_REGISTRY = {
      8  => { up: v8_to_9,   down: v9_to_8 },
      9  => { up: v9_to_10,  down: v10_to_9 },
      10 => { up: v10_to_11, down: v11_to_10 },
      11 => { up: v11_to_12, down: v12_to_11 },
      12 => { up: nil,       down: nil } # Boundary version
    }.freeze

    DOWNGRADE_REGISTRY = VERSION_REGISTRY.transform_values { |v| v[:down] }.compact.freeze
    UPGRADE_REGISTRY   = VERSION_REGISTRY.transform_values { |v| v[:up] }.compact.freeze
    ```

2. Update the Downgrade Helper Logic

    Because Ruby Hashes maintain their insertion order, selecting keys from 8 up to
    11 extracts them in ascending order ([8, 9, 10]).

    For a downgrade pipeline, we want the highest version to execute first, so we
    must add .reverse before reducing:

    ```ruby
    def build_downgrade_pipeline(from:, to:)
      # For from: 11, to: 8 -> Selects keys where 8 <= version < 11
      # This grabs keys 8, 9, 10 -> [v9_to_8, v10_to_9, v11_to_10]
      steps = DOWNGRADE_REGISTRY.select do |version, _|
        version >= to && version < from
      end.values

      # Reverse them to get the right execution sequence: [v11_to_10, v10_to_9, v9_to_8]
      steps.reverse.reduce(:>>)
    end
    ```

3. How to Execute the Downgrade

    Now you can safely build and invoke the pipeline down to version 8:

    ```ruby
    # 1. Build the in-memory mutation pipeline
    v11_to_v8_pipeline = build_downgrade_pipeline(from: 11, to: 8)

    # 2. Wrap with your parsing/serialization bookends
    parse_xml     = ->(str) { Nokogiri::XML(str) }
    serialize_xml = ->(doc) { doc.to_xml }

    execute_downgrade = parse_xml >> v11_to_v8_pipeline >> serialize_xml

    # 3. Call it
    v8_xml_string = execute_downgrade.call(v11_xml_string)
    ```


This is inconsistent:

```text
# The key represents the version we are downgrading TO or upgrading FROM
# Instead it should be :
# The key represents the version we are downgrading TO or upgrading TO (the desired end state)
```

To make the key strictly represent the desired end state (the version we are
moving TO) for both directions, we can realign the registry definition.

With this semantic rule, when you look at a key like 10:

• :down means: "How do I get to v10 from v11?" (v11_to_10)

• :up means: "How do I get to v10 from v9?" (v9_to_10)

Here is the structurally consistent code layout and how both pipeline builders slice it.

1. Consistent Registry Definition (Key = Target End State)

    ```ruby
    # The key strictly represents the version we are moving TO (the target destination)
    VERSION_REGISTRY = {
      8  => { up: nil,       down: v9_to_8 },   # Cannot upgrade TO v8
      9  => { up: v8_to_9,   down: v10_to_9 },
      10 => { up: v9_to_10,  down: v11_to_10 },
      11 => { up: v10_to_11, down: v12_to_11 },
      12 => { up: v11_to_12, down: nil }        # Cannot downgrade TO v12
    }.freeze

    DOWNGRADE_REGISTRY = VERSION_REGISTRY.transform_values { |v| v[:down] }.compact.freeze
    UPGRADE_REGISTRY   = VERSION_REGISTRY.transform_values { |v| v[:up] }.compact.freeze
    ```

2. Slicing the Pipelines

    Because the keys represent the destination, the lookup intervals change cleanly
    based on your path.

    a. Downgrading to v8 (from: 11, to: 8)

    To move from 11 down to 8, the document needs to step through target versions
    10, 9, and 8. Because Ruby extracts hash keys in ascending order ([8, 9, 10]),
    we reverse them so the highest transformation executes first.

    ```ruby
    def build_downgrade_pipeline(from:, to:)
      # For 11 down to 8 -> Selects target destinations 8, 9, 10
      steps = DOWNGRADE_REGISTRY.select do |target_version, _|
        target_version >= to && target_version < from
      end.values

      # Reverses [v9_to_8, v10_to_9, v11_to_10] -> [v11_to_10, v10_to_9, v9_to_8]
      steps.reverse.reduce(:>>)
    end
    ```

    b. Upgrading to v12 (from: 9, to: 12)

    To move from 9 up to 12, the document needs to step through target versions 10, 11, and 12. These are extracted in natural ascending order, ready for forward composition.

    ```ruby
    def build_upgrade_pipeline(from:, to:)
      # For 9 up to 12 -> Selects target destinations 10, 11, 12
      steps = UPGRADE_REGISTRY.select do |target_version, _|
        target_version > from && target_version <= to
      end.values

      # Left-to-right composition: v9_to_10 >> v10_to_11 >> v11_to_12
      steps.reduce(:>>)
    end
    ```

3. Execution Verification

    ```ruby
    # Build the pipeline down to v8
    v11_to_v8_pipeline = build_downgrade_pipeline(from: 11, to: 8)

    # Combine with in-memory bookends
    parse_xml     = ->(str) { Nokogiri::XML(str) }
    serialize_xml = ->(doc) { doc.to_xml }

    execute_downgrade = parse_xml >> v11_to_v8_pipeline >> serialize_xml
    v8_xml_string     = execute_downgrade.call(v11_xml_string)
    ```

    These pure functions are bidi xslt transformations. Thus we do not define separate up and down functions.

    • `:down` means: "How do I get to v10 from v11?" (conceptually: `v10_to_11.reverse`)
    • `:up` means: "How do I get to v10 from v9?" (`v9_to_10`)

    Because the XSLT transformations are bidirectional, each individual file
    represents a standalone version bridge (e.g., the file v9_to_10 handles moving
    up, and reversing it handles moving down).

To model this with consistency using the rule ("The registry key represents the
target end state"), `VERSION_REGISTRY` only needs to store a single XSLT
transformation object per key.

• When looking at key 10: The associated asset is v9_to_10.

• Upward path to v10: Execute v9_to_10 forward.

• Downward path to v10: Execute v10_to_11 in reverse (which is stored under key
11, because 11 is the bridge between 10 and 11).

Here is the elegant, unified registry setup and the exact slicing helpers for both directions.

1. The Unified Bidirectional Registry

Each key holds the single transformation asset required to reach that version
from a previous version.

```ruby
# The key strictly represents the version we are moving TO (the target destination)
# Each value is a bidirectional transformation wrapper capable of running forward or backward.
VERSION_REGISTRY = {
  8  => nil,              # Base version (nothing transforms up TO v8)
  9  => xslt_v8_to_9,     # Moves up TO v9 forward, or down TO v8 reversed
  10 => xslt_v9_to_10,    # Moves up TO v10 forward, or down TO v9 reversed
  11 => xslt_v10_to_11,   # Moves up TO v11 forward, or down TO v10 reversed
  12 => xslt_v11_to_12    # Moves up TO v12 forward, or down TO v11 reversed
}.freeze
```

Note: For the examples below, we assume your bidirectional XSLT wrapper responds to .forward and .inverse (or .reverse), returning a pure function lambda.

2. Slicing the Bidirectional Pipelines

    a. Downgrading to v8 (from: 11, to: 8)

    To downgrade, your target end states are 10, 9, and 8. To reach those states, we
    must extract the transformation bridges for keys 11, 10, and 9 and invoke their
    inverse methods.

    ```ruby
    def build_downgrade_pipeline(from:, to:)
      # For 11 down to 8 -> Grabs keys 9, 10, 11
      bridges = VERSION_REGISTRY.select do |target_version, transformation|
        target_version > to && target_version <= from && transformation
      end.values

      # 1. Map each bridge to its inverse function
      # 2. Reverse the array so the highest version executes first: [v10_to_11.inverse, v9_to_10.inverse, v8_to_9.inverse]
      steps = bridges.map(&:inverse).reverse

      # Compose left-to-right
      steps.reduce(:>>)
    end
    ```

    b. Upgrading (from: 9, to: 12)

    To upgrade, your target end states are 10, 11, and 12. We extract keys 10,
    11, and 12 and invoke their forward methods in natural ascending order.

    ```ruby
    def build_upgrade_pipeline(from:, to:)
      # For 9 up to 12 -> Grabs keys 10, 11, 12
      bridges = VERSION_REGISTRY.select do |target_version, transformation|
        target_version > from && target_version <= to && transformation
      end.values

      # Map each bridge to its forward function: [v9_to_10.forward, v10_to_11.forward, v11_to_12.forward]
      steps = bridges.map(&:forward)

      # Compose left-to-right
      steps.reduce(:>>)
    end
    ```

3. Structural Visualization of the Mapping

    Here is how the version intervals map to your single registry keys across
    execution paths:

    ```text
    [v8] <=== key 9 (xslt_v8_to_9) ===> [v9] <=== key 10 (xslt_v9_to_10) ===> [v10] <=== key 11 (xslt_v10_to_11) ===> [v11]

    UPWARD PATH (from: 9, to: 11)      => Uses keys: [10, 11]         => Direction: .forward
    DOWNWARD PATH (from: 11, to: 8)    => Uses keys: [11, 10, 9]      => Direction: .inverse (Executed 11 -> 10 -> 9)
    ```


```ruby
require 'nokogiri'

# Assumes VERSION_REGISTRY, build_upgrade_pipeline, and build_downgrade_pipeline
# are defined and available in scope as established previously.

def migrate_xml(xml_string, from:, to:)
  # 1. Guard Clause: If the versions match, return the input unmodified
  return xml_string if from == to

  # 2. LHS Bookend: Parse input string to Nokogiri Document
  parse_xml = ->(str) { Nokogiri::XML(str) }

  # 3. Dynamic Pipeline Generation & Serialization Bridge Selection
  if from > to
    # Downgrade Path
    in_memory_pipeline = build_downgrade_pipeline(from: from, to: to)
    final_bridge       = VERSION_REGISTRY[to]
    serialize_xml      = ->(doc) { final_bridge.serialize(doc) }
  else
    # Upgrade Path
    in_memory_pipeline = build_upgrade_pipeline(from: from, to: to)
    final_bridge       = VERSION_REGISTRY[to]
    serialize_xml      = ->(doc) { final_bridge.serialize(doc) }
  end

  # 4. Compose the complete pure process end-to-end
  pipeline = parse_xml >> in_memory_pipeline >> serialize_xml

  # 5. Execute the pipeline
  pipeline.call(xml_string)
end
```

XSLT processing behaves fundamentally differently than Ruby/Nokogiri DOM manipulation.

While the structural flow (`String -> Object -> Transformations -> String`)
remains conceptually accurate, the bookends and pipeline composition need two
critical corrections to work with XSLT:

1. Nokogiri XSLT transforms return another `Document` object, not the same mutated one

    When you execute an XSLT transformation in Nokogiri, it does not mutate the
    source document in-place. Instead, xslt.transform(doc) always compiles and
    outputs a brand new Nokogiri::XML::Document object.

    Because every step returns a fresh document reference, your pipeline naturally
    stays pure, and you do not need to worry about managing isolated in-place
    mutations.

2. XSLT serialization is handled by the XSLT engine, not .to_xml

    XSLT stylesheets often define specific output rules (like indentation, doctypes,
    or encoding) via the <xsl:output> tag. If you use standard doc.to_xml at the end
    of the pipeline, you bypass those engine instructions. The correct way to
    serialize an XSLT result is calling stylesheet.serialize(result_doc).


### The Correct Way to "Put it Together" with XSLT

Here is how to update your bookends and composition execution to correctly
handle Nokogiri's XSLT behavior:

```ruby
require 'nokogiri'

# 1. Your parsing bookend remains identical
parse_xml = ->(str) { Nokogiri::XML(str) }

# 2. Extract your pure XSLT transformation pipeline
in_memory_pipeline = build_downgrade_pipeline(from: 11, to: 9)

# 3. Handle the Serialization bookend safely
# We need the final stylesheet in the chain to serialize the output correctly.
# If your pipeline has steps, we grab the last XSLT bridge in the interval.
final_bridge = VERSION_REGISTRY[9] # The bridge that lands us at v9

serialize_xml = ->(final_doc) {
  # Let the final XSLT bridge handle serialization according to its <xsl:output> rules
  final_bridge.serialize(final_doc)
}

# 4. Combine into the final pure process
execute_downgrade = parse_xml >> in_memory_pipeline >> serialize_xml

# 5. Execution
v9_xml_string = execute_downgrade.call(v11_xml_string)
```

### What a Single XSLT Bridge Lambda Looks Like Under the Hood

To ensure it pipes seamlessly into `>>`, the `.forward` and `.inverse` methods must
return callables (lambdas) that accept a `Nokogiri::XML::Document` and return a
new `Nokogiri::XML::Document`:

```ruby
# Example structure of your bidirectional XSLT wrapper
class BidirectionalXslt
  def initialize(up_path, down_path)
    @up_stylesheet   = Nokogiri::XSLT(File.read(up_path))
    @down_stylesheet = Nokogiri::XSLT(File.read(down_path))
  end

  def forward
    ->(doc) { @up_stylesheet.transform(doc) }
  end

  def inverse
    ->(doc) { @down_stylesheet.transform(doc) }
  end

  def serialize(doc)
    # The downward path stylesheet handles the serialization output rules
    @down_stylesheet.serialize(doc)
  end
end
```

Would you like to explore how to pass dynamic variables (like system user or environment parameters) into the intermediate XSLT transformation lambdas during pipeline execution?

wrap this into a method that accepts the from and to version numbers:

```ruby
require 'nokogiri'

# LHS bookend
parse_xml = ->(str) { Nokogiri::XML(str) }

# Extract pure XSLT transformation pipeline
in_memory_pipeline = build_downgrade_pipeline(from: 11, to: 9)

# We need the final stylesheet in the chain to serialize the output correctly.
# If your pipeline has steps, we grab the last XSLT bridge in the interval.
final_bridge = VERSION_REGISTRY[9] # The bridge that lands us at v9

# RHS bookend
serialize_xml = ->(final_doc) {
  # Let the final XSLT bridge handle serialization according to its <xsl:output> rules
  final_bridge.serialize(final_doc)
}

# 4. Combine into the final pure process
execute_downgrade = parse_xml >> in_memory_pipeline >> serialize_xml

# 5. Execution
v9_xml_string = execute_downgrade.call(v11_xml_string)
```

Here is the complete process wrapped into a clean, reusable method.

This implementation dynamically builds either an upgrade or downgrade pipeline
depending on the input parameters, fetches the correct boundary bridge for
serialization, and executes the functional pipeline.

The following example converts from 11 to 9:

```ruby
require 'nokogiri'

# Assumes VERSION_REGISTRY, build_upgrade_pipeline, and build_downgrade_pipeline
# are defined and available in scope as established previously.

def migrate_xml(xml_string, from:, to:)
  # 1. Guard Clause: If the versions match, return the input unmodified
  return xml_string if from == to

  # 2. LHS Bookend: Parse input string to Nokogiri Document
  parse_xml = ->(str) { Nokogiri::XML(str) }

  # 3. Dynamic Pipeline Generation & Serialization Bridge Selection
  if from > to
    # Downgrade Path
    in_memory_pipeline = build_downgrade_pipeline(from: from, to: to)
    final_bridge       = VERSION_REGISTRY[to]
    serialize_xml      = ->(doc) { final_bridge.serialize(doc) }
  else
    # Upgrade Path
    in_memory_pipeline = build_upgrade_pipeline(from: from, to: to)
    final_bridge       = VERSION_REGISTRY[to]
    serialize_xml      = ->(doc) { final_bridge.serialize(doc) }
  end

  # 4. Compose the complete pure process end-to-end
  pipeline = parse_xml >> in_memory_pipeline >> serialize_xml

  # 5. Execute the pipeline
  pipeline.call(xml_string)
end

# Downgrading an XML string from v11 to v9
v9_string = migrate_xml(v11_xml_string, from: 11, to: 9)

# Upgrading an XML string from v9 to v12
v12_string = migrate_xml(v9_xml_string, from: 9, to: 12)
```


### Why this is idiomatic

• Self-Documenting: Passing from: 11, to: 9 clearly communicates the intent of
the code compared to zero-based array slicing like [1..2].

• Configurable: If you add a v13_to_12 step in the future, you only update the
registry hash. The pipeline builder logic remains completely untouched.
