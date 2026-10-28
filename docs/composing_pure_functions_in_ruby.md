# Composing Pure Functions in Ruby

Function composition in Ruby can be achieved using the native `>>` (pipeline) and
`<<` (compose) operators on `Proc` and `Method` objects, introduced in Ruby 2.6. [1]
(https://www.ghostcassette.com/function-composition-in-ruby/) Pure functions in
Ruby are blocks of code that have no observable side effects and always produce
the same output for a given input. [1]
(https://engineering.gusto.com/embracing-functional-programming-in-ruby-4386129cc7e4)


## Methods for Composing Pure Functions

1. Native Proc Composition (`>>` and `<<`)

    You can define pure functions using lambdas or procs, and chain them directly
    using forward (`>>`) or backward (`<<`) composition. [1]
    (https://ruby-doc.org/learn/ruby-functional-programming/), [2]
    (https://www.ghostcassette.com/function-composition-in-ruby/)

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
    them into Method objects using #method and compose them the exact same way. [1]
    (https://www.ghostcassette.com/function-composition-in-ruby/)

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
    that acts like a single pure function from the outside. [1]
    (https://www.tomdalling.com/blog/pure-function-as-an-object-PFAAO-pattern/),
    [2]
    (https://engineering.gusto.com/embracing-functional-programming-in-ruby-4386129cc7e4)

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
(https://patshaughnessy.net/2014/4/8/using-a-ruby-class-to-write-functional-code),
[2]
(https://engineering.gusto.com/embracing-functional-programming-in-ruby-4386129cc7e4)


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

To compose specific intervals (or slices) from an ordered set of functions in Ruby, the most idiomatic approach is combining array slicing with Enumerable#reduce using the forward composition operator (>>).
Here are the various ways to achieve this, from direct slicing to building a dynamic pipeline helper.

### Setup

Assuming your pure functions are defined as lambdas or procs inside an ordered array:
ruby
v8_to_9   = ->(x) { "v9(#{x})" }
v9_to_10  = ->(x) { "v10(#{x})" }
v10_to_11 = ->(x) { "v11(#{x})" }
v11_to_12 = ->(x) { "v12(#{x})" }


### The ordered set

```ruby
pipeline_steps = [v8_to_9, v9_to_10, v10_to_11, v11_to_12]
```


1. The Idiomatic Way: Array Slicing + reduce(`:>>`)

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


1. The Semantic Way: A Dedicated Pipeline Wrapper

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

1. The Explicit Manual Way

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

Here are the correct ways to slice and apply your functions in reverse order:

1. The Idiomatic Way: Slice and #reverse

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

1. The Right-to-Left Way: Slice and `#reduce` (`:<<`)

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

### Comparison of the two approaches

| Approach                     | Sliced Array Order | Composition Operator | Execution Order                               |
| ---------------------------- | ------------------ | -------------------- | --------------------------------------------- |
| `[0..2].reverse.reduce(:>>)` | `[v10, v9, v8]`    | Forward (`>>`)       | `v10 \(\rightarrow \) v9 \(\rightarrow \) v8` |
| `[0..2].reduce(:<<)`         | `[v8, v9, v10]`    | Backward (`<<`)      | `v10 \(\rightarrow \) v9 \(\rightarrow \) v8` |


## Downgrading Data Structures

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

1. Dual-Direction Version Registry Pattern

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

1. Schema Validation as a Safety Valve

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

1. Composing the "In-Memory" Pipeline with String Bookends

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

# The overall chain 'full_process' behaves as a pure function
# Given the same XML string input, it always returns the same XML string output
# with zero side-effects leaking to the rest of the application
```

Since each transformation function is invoked at most once during program
execution, you can safely leverage isolated mutation to achieve maximum
performance.

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

  steps = DOWNGRADE_REGISTRY.select { |version,_| version <= from && version > to }.values

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
