# Architectural Guide: Composing Bidirectional Transformations in Ruby

The terms used here are defined in [glossary.md](glossary.md).

Function composition in Ruby allows you to link a sequence of isolated, pure
transformations into a seamless pipeline. This guide covers how a
production-ready, bidirectional XML migration engine is built from Ruby's native
function operators and Nokogiri.

## 1. Core Principles of Pure Function Composition

A function is pure if it has no side effects and always returns the same
output given the same input. Ruby 2.6+ supports native functional composition on
`Proc` and `Method` objects using forward (`>>`) and backward (`<<`) pipeline
operators.

```ruby
# Define pure lambdas
add_three  = ->(x) { x + 3 }
square     = ->(x) { x * x }
to_string  = ->(x) { "Result: #{x}" }

# Forward composition (Left-to-Right sequence)
pipeline = add_three >> square >> to_string
pipeline.call(5) # => "Result: 64"

# Backward composition (Right-to-Left sequence)
compose = to_string << square << add_three
compose.call(5) # => "Result: 64"
```

If transformations are organized as class methods, they can be unbound into
`Method` objects using `#method` and composed:

```ruby
module MathOperations
  def self.double(x) = x * 2
  def self.increment(x) = x + 1
end

double_then_increment = MathOperations.method(:double) >> MathOperations.method(:increment)
double_then_increment.call(4) # => 9
```

A conversion in this program is a pure function in this sense. It takes a
document and returns a document, the result depends only on the document, and
nothing outside it is touched.

## 2. Defining a Single Source of Truth: The Target End-State

When managing schema versions (e.g., Ableton Live Sets (ALS files) v8
through v12), a robust design uses a unified version-keyed registry where the
key represents the version being moved *to*.

ALS conversions are bidirectional, so each key points to a bridge: the part of
the program that converts a set between that version and the one before it.
The bridge holds what the two versions do differently, and it handles moving
both ways.

```ruby
# The bridge for each version of Live, keyed by the version the bridge leads to.
BRIDGES = {
  9  => Live8And9,     # Moves up TO v9 forward, or down TO v8 via inverse
  10 => Live9And10,    # Moves up TO v10 forward, or down TO v9 via inverse
  11 => Live10And11,   # Moves up TO v11 forward, or down TO v10 via inverse
  12 => Live11And12    # Moves up TO v12 forward, or down TO v11 via inverse
}.freeze
```

**Conceptual Visual Model**

```plain
[v8] <=== key 9 (Live8And9) ===> [v9] <=== key 10 (Live9And10) ===> [v10] <=== key 11 (Live10And11) ===> [v11] <=== key 12 (Live11And12) ===> [v12]

UPWARD PATH (from: 8, to: 12)    => Bridges: [9, 10, 11, 12]
DOWNWARD PATH (from: 12, to: 8)  => Bridges: [12, 11, 10, 9]
```

A bridge is not told which way to convert. It reads the version out of the
document it is handed and converts it to the other of the two versions it
knows, so the same bridge carries both directions, and the direction is a
property of the document rather than of the bridge.

Only Live 11 and Live 12 have a bridge today, so only the 11↔12 version_diff
is in scope, and its bridge is the class `Live11And12`. The bridges of the
other version_diffs do not exist yet.

`lib/live_set/tx/live_versions.rb` is to hold the registry, and each entry of
it is to be a function of a document — it takes a document and returns a
document — so that the bridges of two versions can be composed with `>>`. The
class of the bridge is behind the function; the function is what the registry
holds.

## 3. Dynamically Slicing the Pipeline Intervals

Because the registry is keyed by the version a bridge leads to, the bridges
between two versions are the keys between them, and a conversion from one
version to another is the composition of those bridges.

```ruby
# The bridges between two versions, in the order they are applied.
#
# For from: 8, to: 12 -> the bridges keyed 9, 10, 11 and 12
# For from: 12, to: 8 -> the bridges keyed 12, 11, 10 and 9
def bridges_between(from:, to:)
  keys = to > from ? (from + 1..to).to_a : (to + 1..from).to_a.reverse
  keys.map { |version| BRIDGES.fetch(version) }
end

# The composition of them.
bridges_between(from: 8, to: 12).reduce(:>>)
```

Each entry of the registry is a function of a document, so the bridges
compose. Each bridge in the composition reads the version of the document it
is given and moves it one version, so the direction of the whole conversion is
decided by the document and not by the caller. The direction is not a
parameter of any of them.

## 4. The Lifecycle of a Conversion

A conversion is made of three classes and one document.

`LiveSetConverter` reads a set and writes the converted set next to it. It
does nothing else: it hands the parsed document to `LiveSetTransformer`, and
writes what comes back.

`LiveSetTransformer` finds the bridge for the version the document carries,
and applies it.

The bridge itself is a class that inherits the machinery from
`LiveVersionConverter` and holds the differences between its two versions.
`Live11And12` is the bridge between Live 11 and Live 12.

```ruby
class LiveSetTransformer
  # The bridges, each of which converts between two versions of the format.
  BRIDGES = [Live11And12].freeze

  # The bridge that converts a document.
  def self.bridge_for(document)
    version = version_of(document)
    bridge = BRIDGES.find { |candidate| candidate.versions.include?(version) }
    raise ArgumentError, "no bridge converts a set of version #{version.inspect}" if bridge.nil?

    bridge
  end

  def transform
    self.class.bridge_for(@document).new(@document).convert
  end
end
```

The bridge reads the version of the document it is handed, and works out which
way the set has to go: up to the newer version, or down to the older one. A
document whose version the bridge does not know is an error.

The base class holds the machinery, and applies it in this order:

1. the version strings of the version the set is going to;
2. the removal of the elements and attributes the older version does not have;
3. the rename of the elements the two versions spell differently;
4. the emptying of the elements the older version keeps empty;
5. the default attributes the older version always writes;
6. the attributes the newer version writes;
7. the special transformations;
8. the elements the newer version adds;
9. the order the version writes the children of an element in.

The lists of names that the first six and the last three steps work from are
constants of the subclass, and the machinery reads them through
`self.class::`, so a subclass supplies them by defining its own. The seventh
step is the subclass's own: fifteen hand-written methods for the differences a
list of names cannot express — a value the two versions write differently, an
element one version wraps and the other keeps bare, an element that has to
move to another parent.

A list of names does not say which way the conversion is going. A rename
matches either spelling and emits the other, so the same list serves both
directions. A list that applies in one direction only holds an entry for each
direction, and the bridge takes the one that applies.

A transformation is not directional. It matches the document it is given and
emits something else, so one set of transformations carries both directions of
a version_diff, and the direction is a property of the document. One bridge
stands between two versions, and it handles moving both ways.

The up direction (older version to newer) is lossless: it preserves everything
the live set contains and changes only how it is expressed. The down
direction is lossy: constructs the older version cannot represent are dropped
and cannot be recovered. The down direction is therefore not a functional
inverse of the up direction, and down-then-up does not return the original
document.

## 5. Comparing Two Live Sets

Two sets cannot be compared directly, because the same set is written
differently in each Live version. Both are brought to a common version first,
and the comparison is made there.

The comparison is made by `lib/live_set/xml_diff.rb`, which walks two
documents in parallel: the children of two elements are matched by their
names, the children with the same name are compared with each other in the
order they come, and the children that one of the elements has and the other
does not are reported as differences. `exe/xml_diff` is the tool that runs it,
and it prints the differences it finds.

Bytes play no part in the comparison. The gzip header, the mtime and the
writer's formatting all lie outside the equality relation.

Revision and SchemaChangeCount describe the file rather than the live set:
Live rewrites them every time it saves a set, so two files holding the same
set do not agree on them. A converted set is given a fixed Revision instead,
so that it can be recognized as the result of a conversion rather than a set
saved by Live. What else to exclude is not settled yet.

The up direction has a reference to be compared against: a Live 11 set is
opened in Live 12 and saved, and the file Live wrote is the ground truth the
conversion is measured against. `spec/live_set/tx/live_up_comparison_spec.rb`
is that comparison, and it names the differences that a conversion cannot
reproduce — the ones that come from the state of the machine Live ran on, and
from the state of the session view.

## 6. The Conversion Edits the Document It Is Given

An XSLT engine builds a new document for every step it takes, so the memory
of a conversion is the sum of its steps. The conversion in this program is
Ruby, and it does not work that way: the bridge is handed a document and
edits it in place, and returns the same document. There is no copy, and no
proxy to guard against one, because the document is the caller's and the
caller knows it is being converted.

The consequence to remember is that the document the caller passed in *is* the
converted set once the conversion is done. A spec that converts a set and then
compares it with something else compares the document it started with:

```ruby
document = AlsFile.read(live11_path)
described_class.new(document).convert
document # the converted set
```
