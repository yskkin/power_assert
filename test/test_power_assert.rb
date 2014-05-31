require 'test/unit'
require 'power_assert'
require 'ripper'
require 'set'

class TestPowerAssert < Test::Unit::TestCase
  EXTRACT_METHODS_TEST = [
    [[[:method, "c", 4], [:method, "b", 2], [:method, "d", 8], [:method, "a", 0]],
      'a(b(c), d))'],

    [[[:method, "a", 0], [:method, "b", 2], [:method, "d", 6], [:method, "c", 4]],
      'a.b.c(d)'],

    [[[:method, "b", 2], [:method, "a", 0], [:method, "c", 5], [:method, "e", 9], [:method, "d", 7]],
      'a(b).c.d(e)'],

    [[[:method, "b", 4], [:method, "a", 2], [:method, "c", 7], [:method, "e", 13], [:method, "g", 11], [:method, "d", 9], [:method, "f", 0]],
      'f(a(b).c.d(g(e)))'],

    [[[:method, "c", 5], [:method, "e", 11], [:method, "a", 0]],
      'a(b: c, d: e)'],

    [[[:method, "b", 2], [:method, "c", 7], [:method, "d", 10], [:method, "e", 15], [:method, "a", 0]],
      'a(b => c, d => e)'],

    [[[:method, "b", 4], [:method, "d", 10]],
      '{a: b, c: d}'],

    [[[:method, "a", 1], [:method, "b", 6], [:method, "c", 9], [:method, "d", 14]],
      '{a => b, c => d}'],

    [[[:method, "a", 2], [:method, "b", 5], [:method, "c", 10], [:method, "d", 13]],
      '[[a, b], [c, d]]'],

    [[[:method, "a", 0], [:method, "b", 2], [:method, "c", 5]],
      'a b, c { d }'],

    [[[:method, "a", 20]],
      'assertion_message { a }'],

    [[[:method, "a", 0]],
      'a { b }'],

    [[[:method, "c", 4], [:method, "B", 2], [:method, "d", 8], [:method, "A", 0]],
      'A(B(c), d)'],

    [[[:method, "c", 6], [:method, "f", 17], [:method, "h", 25], [:method, "a", 0]],
      'a(b = c, (d, e = f), G = h)'],

    [[[:method, "b", 2], [:method, "c", 6], [:method, "d", 9], [:method, "e", 12], [:method, "g", 18], [:method, "i", 24], [:method, "j", 29], [:method, "a", 0]],
      'a(b, *c, d, e, f: g, h: i, **j)'],

    [[[:method, "a", 0], [:method, "==", nil], [:method, "b", 5], [:method, "+", nil], [:method, "c", 9]],
      'a == b + c'],

    [[[:ref, "var", 0], [:ref, "var", 8], [:method, "var", 4]],
      'var.var(var)'],

    [[[:ref, "B", 2], [:ref, "@c", 5], [:ref, "@@d", 9], [:ref, "$e", 14], [:method, "f", 18], [:method, "self", 20], [:ref, "self", 26], [:method, "a", 0]],
      'a(B, @c, @@d, $e, f.self, self)']
  ]

  EXTRACT_METHODS_TEST.each_with_index do |(expect, source), idx|
    define_method("test_extract_methods_#{idx}") do
      pa = PowerAssert.const_get(:Context).new(-> { var = nil; -> {} }.(), nil)
      assert_equal expect, pa.send(:extract_idents, Ripper.sexp(source), :assertion_message).map(&:to_a), source
    end
  end

  def assertion_message(&blk)
    ::PowerAssert.start(blk, assertion_method: __method__) do |pa|
      pa.yield
      pa.message_proc.()
    end
  end

  def test_assertion_message
    a = 0
    @b = 1
    @@c = 2
    $d = 3
    assert_equal <<END.chomp, assertion_message {
      String(a) + String(@b) + String(@@c) + String($d)
      |      |  | |      |   | |      |    | |      |
      |      |  | |      |   | |      |    | |      3
      |      |  | |      |   | |      |    | "3"
      |      |  | |      |   | |      |    "0123"
      |      |  | |      |   | |      2
      |      |  | |      |   | "2"
      |      |  | |      |   "012"
      |      |  | |      1
      |      |  | "1"
      |      |  "01"
      |      0
      "0"
END
      String(a) + String(@b) + String(@@c) + String($d)
    }
    assert_equal <<END.chomp, assertion_message {
      "0".class == "3".to_i.times.map {|i| i + 1 }.class
          |     |      |    |     |                |
          |     |      |    |     |                Array
          |     |      |    |     [1, 2, 3]
          |     |      |    #<Enumerator: 3:times>
          |     |      3
          |     false
          String
END
      "0".class == "3".to_i.times.map {|i| i + 1 }.class
    }
    assert_equal '', assertion_message {
      false
    }
    assert_equal <<END.chomp,
    assertion_message { "0".class }
                            |
                            String
END
    assertion_message { "0".class }
    assert_equal <<END.chomp, assertion_message {
      Set.new == Set.new([0])
      |   |   |  |   |
      |   |   |  |   #<Set: {0}>
      |   |   |  Set
      |   |   false
      |   #<Set: {}>
      Set
END
      Set.new == Set.new([0])
    }
  end
end
