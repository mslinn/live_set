# Architectural Guide: Composing Bidirectional XSLT Transformations in Ruby

The terms used here are defined in [glossary.md](glossary.md).

Function composition in Ruby allows you to link a sequence of isolated, pure
transformations into a seamless pipeline. This guide covers how to build a
production-ready, bidirectional XML migration engine using Ruby’s native
functional operators and Nokogiri.

1. Core Principles of Pure Function Composition

    A function is pure if it has no side effects and always returns the same
    output given the same input. Ruby 2.6+ supports native functional
    composition on `Proc` and `Method` objects using forward (`>>`) and backward (`<<`)
    pipeline operators. [1]

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
    `Method` objects using `#method` and composed: [1]

    ```ruby
    module MathOperations
      def self.double(x) = x * 2
      def self.increment(x) = x + 1
    end

    double_then_increment = MathOperations.method(:double) >> MathOperations.method(:increment)
    double_then_increment.call(4) # => 9
    ```

2. Defining a Single Source of Truth: The Target End-State

    When managing schema versions (e.g., Ableton Live Sets (ALS files) v8
    through v12), a robust design would use a unified Version-Keyed Registry
    where the key represents the desired end state (the version we are moving
    TO). [1]

    ALS conversions are handled by XSLT transformations, which are inherently
    bidirectional.

    Because ALS version conversions are therefore also bidirectional, each key
    points to a specialized translation bridge object that handles the logic
    required to enter that version from its neighboring version. [1]

    ```ruby
    # Single Source of Truth
    # The key reflects the target destination version.
    VERSION_REGISTRY = {
      8  => nil,              # Base version (nothing transforms up TO v8)
      9  => xslt_v8_to_9,     # Moves up TO v9 forward, or down TO v8 via inverse
      10 => xslt_v9_to_10,    # Moves up TO v10 forward, or down TO v9 via inverse
      11 => xslt_v10_to_11,   # Moves up TO v11 forward, or down TO v10 via inverse
      12 => xslt_v11_to_12    # Moves up TO v12 forward, or down TO v11 via inverse
    }.freeze
    ```

    **Conceptual Visual Model**

    ```plain
    [v8] <=== key 9 (xslt_v8_to_9) ===> [v9] <=== key 10 (xslt_v9_to_10) ===> [v10] <=== key 11 (xslt_v10_to_11) ===> [v11] <=== key 12 (xslt_v11_to_12) ===> [v12]

    UPWARD PATH (from: 8, to: 12)    => Target versions: [9, 10, 11, 12]  => Operation: .forward
    DOWNWARD PATH (from: 12, to: 8)  => Target versions: [11, 10, 9, 8]  => Operation: .inverse (Executed 11 -> 10 -> 9 -> 8)
    ```

3. Dynamically Slicing the Pipeline Intervals

    By leveraging the target end-state registry layout, you can write semantic
    builders that filter keys dynamically and compose them using
    `Enumerable#reduce` (`:>>`). [1]

    ```ruby
    # Extract and chain upgrade transformations
    def build_upgrade_pipeline(from:, to:)
      # For from: 8, to: 12 -> Selects target destinations 9, 10, 11, 12
      bridges = VERSION_REGISTRY.select do |target_version, transformation|
        target_version > from && target_version <= to && transformation
      end.values

      steps = bridges.map(&:forward)
      steps.reduce(:>>) # Links: v8_to_9, v9_to_10 >> v10_to_11 >> v11_to_12
    end

    # Extract and chain downgrade transformations
    def build_downgrade_pipeline(from:, to:)
      # For from: 12, to: 8 -> Selects target destinations 11, 10, 9, 8
      # (Bridges stored at keys 12, 11, 10, 9 are required to accomplish this path)
      bridges = VERSION_REGISTRY.select do |target_version, transformation|
        target_version > to && target_version <= from && transformation
      end.values

      # Convert bridges to inverses, then reverse the sequence to run highest version first
      steps = bridges.map(&:inverse).reverse
      steps.reduce(:>>) # Links: v12_to_11 >> v11_to_10 >> v10_to_9 >> v9_to_8
    end
    ```

4. The Functional XSLT Engine Lifecycle

    XSLT engines behave differently than traditional Ruby DOM-mutation scripts.
    When executing an XSLT transformation via Nokogiri, the input document is
    never mutated in-place; instead, the engine generates an entirely new
    `Nokogiri::XML::Document` instance. [1]

    Additionally, string serialization must be managed using the stylesheet's
    own rules (such as matching your `<xsl:output>` settings) rather than a
    generic `.to_xml` call. [1]

    **Designing the Bidirectional XSLT Wrapper**

    Each bridge class wraps the respective compiled forward and inverse
    stylesheets into standard functional callables: [1]

    ```ruby
    class BidirectionalXslt
      # A stylesheet is not directional. It matches the input document and emits
      # something else, so one stylesheet can carry both directions of a version
      # version_diff: a rename matches either spelling and emits
      # the other. The direction is a property of the document, not of the
      # stylesheet, and the stylesheet can read it from <Ableton MinorVersion>.
      #
      # The up direction (older version to newer) is lossless: it preserves
      # everything the live set contains and changes only how it is expressed.
      # The down direction is lossy: constructs the older version cannot
      # represent are dropped and cannot be recovered. The down direction is
      # therefore not a functional inverse of the up direction, and down-then-up
      # does not return the original document.
      #
      # Transformations that cannot be expressed symmetrically -- deleting an element only
      # the newer version has, adding one the older version lacks -- must be
      # conditioned on the version read from the input document.
      def initialize(up_path, down_path)
        @up_tx   = Nokogiri::XSLT(File.read(up_path))   # a transform, compiled from a stylesheet
        @down_tx = Nokogiri::XSLT(File.read(down_path)) # a transform, compiled from a stylesheet
      end

      # Applies the transform to an XML document, and returns a transformed live set
      def forward
        ->(doc) { @up_tx.transform(doc) }
      end

      # Applies the transform to an XML document, and returns a transformed live set.
      #
      # The name says inverse, but the down direction is not an inverse. It
      # loses what the older version cannot represent.
      def inverse
        ->(doc) { @down_tx.transform(doc) }
      end

      # Output rendering following the stylesheet's own rules
      def serialize(doc, direction:)
        tx = direction == :up ? @up_tx : @down_tx
        tx.serialize(doc)
      end
    end
    ```

    **The Orchestration Method**

    The orchestrator establishes input and output boundaries ("bookends"). The
    raw XML string is parsed at entry, passed through the in-memory AST
    pipeline, and serialized at exit. [1]

    ```ruby
    # Converts an XML document from one Live version to another.
    #
    # The upgrade must reproduce Live's own conversion. Opening an older set in
    # a newer Live and saving it produces a specific document; the upgrade has
    # to produce that same document, including the elements Live adds and the
    # default values it gives them. Without that, an upgraded old set differs
    # structurally from the same set saved natively in the new version, and
    # every comparison reports differences that belong to the transform rather
    # than to the live sets.
    def migrate_xml(xml_string, from:, to:)
      return xml_string if from == to # Identity guard clause

      parse_xml = ->(str) { Nokogiri::XML(str) }

      if from > to
        direction = :down
        in_memory_pipeline = build_downgrade_pipeline(from: from, to: to)

        # Select the bridge that handled the final step down (to + 1)
        # For to: 8, this safely grabs key 9 (xslt_v8_to_9) to use its serialization format
        final_bridge = VERSION_REGISTRY[to + 1]
      else
        direction = :up
        in_memory_pipeline = build_upgrade_pipeline(from: from, to: to)
        final_bridge = VERSION_REGISTRY[to]
      end

      # Each step is written in the format of the version it lands in, so the
      # writer is chosen by the target version, not by the direction.
      serialize_xml = ->(final_doc) { final_bridge.serialize(final_doc, direction: direction) }

      # Compose and execute the complete pipeline
      full_process = parse_xml >> in_memory_pipeline >> serialize_xml
      full_process.call(xml_string)
    end
    ```

5. Comparing Two Live Sets

    Two sets cannot be compared directly, because the same set is written
    differently in each Live version. Both are brought to a common version
    first, and the comparison is made there.

    ```ruby
    # Compares two live sets for equality.
    #
    # Both documents are upgraded, never downgraded. A downgrade drops the
    # constructs the older version cannot represent, so two sets that differ
    # only in those constructs would compare equal.
    #
    # The upgrade is lossless, so the base version does not decide what the
    # comparison can see. It is chosen for where the upgrade is most faithful
    # to Live's own.
    #
    # Bytes play no part in the comparison. The gzip header, the mtime and the
    # writer's formatting all lie outside the equality relation.
    #
    # Revision and SchemaChangeCount describe the file rather than the live
    # set: Live rewrites them every time it saves a set, so two files holding
    # the same set do not agree on them. They are excluded from the comparison.
    # What else to exclude is not settled yet.
    def equal?(left, right, base_version:)
      left_doc = upgrade_to(left, base_version)
      right_doc = upgrade_to(right, base_version)

      # Nokogiri's == is not structural equality, so the trees are compared as
      # XML canonicalized per XML C14N.
      canonicalize(left_doc) == canonicalize(right_doc)
    end

    # XML canonicalization (C14N) of a document, for comparison.
    #
    # Whitespace-only text nodes are removed first, because Live indents its
    # XML and the indentation is not part of the set. Canonicalization then
    # normalizes attribute order and quoting.
    def canonicalize(doc)
      doc.xpath('//text()').each { |node| node.remove if node.content.strip.empty? }
      doc.canonicalize
    end
    ```

6. Optimization Refinement: Memory-Safe DOM Processing

    While XSLT steps naturally produce fresh immutable document instances, there
    are cases where you may choose to inject standard Ruby/Nokogiri
    DOM-manipulation steps directly into your functional pipeline (e.g.,
    filtering out large attributes or rewriting nodes before compilation). [1]

    Passing strings between Ruby steps causes parsing bloat. Conversely, using
    deep copying (`.dup`) inside every function avoids structural mutability
    side effects but hits CPU performance when processing massive XML
    structures. [1]

    **Optimization: The Single-Pass Mutation Proxy**

    Because the pipeline executes sequentially and each step runs once, you can
    enforce an Isolated Mutation contract. To guarantee functional isolation
    safely without manual .dup calls, wrap the initial document in a proxy
    container that monitors and enforces a mutate-at-most-once state constraint.
    [1]

    ```ruby
    class MutationSafeDocument
      attr_reader :document

      def initialize(nokogiri_doc, mutated = false)
        @document = nokogiri_doc
        @mutated  = mutated
      end

      def mutated?
        @mutated
      end

      # Clones the expensive underlying C-node tree exactly once when first written to.
      # Subsequent steps receive an O(1) pass-through of the already isolated workspace.
      def ensure_mutable!
        if mutated?
          self
        else
          MutationSafeDocument.new(@document.dup, true)
        end
      end
    end
    ```

    **Implementing DOM Manipulation Steps with the Proxy**

    Your non-XSLT preprocessing steps handle this wrapper, protecting the pipeline's overall purity without redundant object allocation overhead: [1]

    ```ruby
    v11_to_10_dom_preprocessing = ->(proxy) {
      writable_proxy = proxy.ensure_mutable!
      doc = writable_proxy.document

      # Perform isolated modifications directly on the AST
      if legacy_node = doc.at_css('user_id')
        legacy_node.name = 'uid'
      end

      writable_proxy # Pass the safe proxy to the next pipeline block
    }
    ```

    This single-pass proxy technique balances design parameters, offering
    flat-scale memory allocations, safety from external mutation leaks, and
    lightweight unit testing capabilities. [1]
