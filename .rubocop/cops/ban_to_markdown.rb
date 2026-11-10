module RuboCop
  module Cop
    module Custom
      # Disallows generating markdown within models.
      #
      # A model holds the facts of a set, and a serializer writes them. A model that writes
      # markdown itself has the markup of the report in two places, and the two drift apart.
      class BanToMarkdown < Base
        MSG = 'Defining `to_markdown` is not allowed in models.'.freeze
        MARKUP_MSG = 'Models may not use `LiveMarkup`: the markdown is written by the serializers.'.freeze

        # Matches method definitions: def to_markdown(...)
        def_node_matcher :to_markdown_method?, <<~PATTERN
          (def :to_markdown ...)
        PATTERN

        # Matches a reference to the markup module: LiveMarkup.something
        def_node_matcher :markup_reference?, <<~PATTERN
          (const nil? :LiveMarkup)
        PATTERN

        def on_def(node)
          return unless to_markdown_method?(node)

          add_offense(node, message: MSG)
        end
        alias on_defs on_def

        def on_const(node)
          return unless markup_reference?(node)

          add_offense(node, message: MARKUP_MSG)
        end
      end
    end
  end
end
