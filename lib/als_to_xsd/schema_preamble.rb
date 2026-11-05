# The comment that heads the generated schema.
#
# It explains what the schema was inferred from, and what the schema cannot say about the format.
SCHEMA_PREAMBLE = <<~PREAMBLE.freeze
  <!--
    This schema was generated from Ableton Live set files. It describes the elements those
    files contained, the attributes they carry, and the bounds on how often they may appear.
    It is an inference from a sample of the format, not a specification of it.

    maxOccurs is "unbounded" wherever a child element was seen to repeat, because a sample
    cannot reveal the real maximum.

    The children of an element are declared in the order they were first seen, inside an
    xs:sequence. Live does not always write siblings in groups: a MIDI track can come
    between two audio tracks, and a device parameter can come between two parameters of
    another type. No sequence can describe that, so where the sample showed a child element
    coming back after a different child element had already appeared, the children are
    declared in an xs:choice instead, and are accepted in any order.
  -->
PREAMBLE
