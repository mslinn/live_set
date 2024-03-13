require_relative 'test_helper'

class LiveSetTest < Minitest::Test
  def test_it_is_a_module
    assert_kind_of Module, LiveSet
  end

  def test_that_it_has_a_version_number
    refute_nil ::LiveSet::VERSION
  end
end
