class CombinedOrderedEnumerator < Enumerator
  class UnorderedEnumerator < RuntimeError
    attr_reader :enumerator

    def initialize(enumerator)
      @enumerator = enumerator
    end
  end

  def initialize(*args)
    super() do |yielder|
      unless args.empty?
        initial_value = enumerator_with_smallest_next_value(args).first

        loop do
          enum = enumerator_with_smallest_next_value(args)
          value_to_be_yielded = enum.next
          raise UnorderedEnumerator.new(enum) if descending_values?(initial_value, value_to_be_yielded)
          yielder.yield(value_to_be_yielded)
          initial_value = value_to_be_yielded
        end
      end
    end
  end

  private

  def enumerator_with_smallest_next_value(enums)
    enums.reduce { |memo, enum| memo < enum ? memo : enum }
  end

  def descending_values?(first_value, second_value)
    first_value > second_value
  end
end

class Enumerator
  include Comparable

  def <=>(another)
    return  1 if self.last_iteration?
    return -1 if another.last_iteration?
    self.peek <=> another.peek
  end

  def last_iteration?
    begin
      return false if peek
    rescue StopIteration
      return true
    end
  end
end


# ================================================
# TESTS
# ================================================


if $0 == __FILE__
  require 'minitest/autorun'
  require 'minitest/pride'

  class EnumeratorTest < MiniTest::Unit::TestCase
    def test_comparing_an_empty_array_and_a_finite_enumerator
      enumerator_one = [].to_enum
      enumerator_two = [1,2].to_enum
      assert_equal false, enumerator_one < enumerator_two
    end

    def test_comparing_a_finite_enumerator_and_an_empty_array
      enumerator_one = [1,2].to_enum
      enumerator_two = [].to_enum
      assert_equal true, enumerator_one < enumerator_two
    end

    def test_comparing_two_finite_enumerators
      enumerator_one = [1,2].to_enum
      enumerator_two = [2,3].to_enum
      assert_equal true, enumerator_one < enumerator_two
    end

    def test_comparing_two_finite_enumerators_reversed
      enumerator_one = [2,3].to_enum
      enumerator_two = [1,2].to_enum
      assert_equal false, enumerator_one < enumerator_two
    end

    def test_knows_if_there_is_no_next_iteration
      enumerator = [].to_enum
      assert_equal true, enumerator.last_iteration?
    end

    def test_knows_if_there_is_a_next_iteration
      enumerator = [1].to_enum
      assert_equal false, enumerator.last_iteration?
    end

    def test_knows_if_the_end_of_the_iteration_has_been_reached
      enumerator = [1].to_enum
      enumerator.next
      assert_equal true, enumerator.last_iteration?
    end
  end


  class CombinedOrderedEnumeratorTest < MiniTest::Unit::TestCase
    def test_enumerating_nothing
      enumerator = CombinedOrderedEnumerator.new()
      assert_equal [], enumerator.take(10)
    end

    def test_enumerating_with_a_single_enumerator
      enumerator = CombinedOrderedEnumerator.new((1..5).to_enum)
      assert_equal [1, 2, 3, 4, 5], enumerator.take(10)
    end

    def test_enumerating_with_two_empty_arrays
      enumerator = CombinedOrderedEnumerator.new([].to_enum, [].to_enum)
      assert_equal [], enumerator.take(20)
    end

    def test_enumerating_with_one_empty_array_and_finite_sequence
      enumerator = CombinedOrderedEnumerator.new([].to_enum, (1..10).to_enum)
      assert_equal [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], enumerator.take(20)
    end

    def test_enumerating_with_one_empty_array_and_finite_sequence_with_switched_args
      enumerator = CombinedOrderedEnumerator.new((1..10).to_enum, [].to_enum)
      assert_equal [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], enumerator.take(20)
    end

    def test_enumerating_an_infinite_sequence_and_finite_one
      enumerator = CombinedOrderedEnumerator.new(fibonacci, (1..10).to_enum)
      assert_equal [0, 1, 1, 1, 2, 2, 3, 3, 4, 5, 5, 6, 7, 8, 8, 9, 10, 13, 21, 34], enumerator.take(20)
    end

    def test_enumerating_two_infinite_sequences
      enumerator = CombinedOrderedEnumerator.new(fibonacci, sum_of_natural_numbers)
      assert_equal [0, 1, 1, 1, 2, 3, 3, 5, 6, 8, 10, 13, 15, 21, 21, 28, 34, 36, 45, 55], enumerator.take(20)
    end

    def test_enumerating_three_finite_sequences
      enumerator = CombinedOrderedEnumerator.new((1..5).to_enum, (1..3).to_enum, (4..10).to_enum)
      assert_equal [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 7, 8, 9, 10], enumerator.take(20)
    end

    def test_enumerating_three_infinite_sequences
      enumerator = CombinedOrderedEnumerator.new(fibonacci, fibonacci, fibonacci)
      assert_equal [0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2], enumerator.take(12)
    end

    def test_raises_unordered_enumerator_exception_if_enumerator_isnt_in_ascending_order
      enumerator = CombinedOrderedEnumerator.new(10.downto(1))

      assert_raises(CombinedOrderedEnumerator::UnorderedEnumerator) do
        enumerator.take(20)
      end
    end

    def test_raises_unordered_enumerator_exception_if_enumerator_isnt_in_ascending_order
      enumerator = CombinedOrderedEnumerator.new([1,3,2].to_enum)

      assert_raises(CombinedOrderedEnumerator::UnorderedEnumerator) do
        enumerator.take(20)
      end
    end

    def test_raising_unordered_enumerator_should_reference_enumerator
      decending_enumerator = 10.downto(1)
      enumerator = CombinedOrderedEnumerator.new(decending_enumerator)

      begin
        enumerator.take(2)
        assert false
      rescue CombinedOrderedEnumerator::UnorderedEnumerator => exception
        assert_equal decending_enumerator, exception.enumerator
      end
    end

    private

    class FibonacciEnumerator < Enumerator
      def initialize
        super() do |yielder|
          a, b = 0, 1

          loop do
            yielder.yield a
            a, b = b, (a + b)
          end
        end
      end
    end

    def fibonacci
      FibonacciEnumerator.new
    end

    class SumOfNaturalNumbersEnumerator < Enumerator
      def initialize
        super() do |yielder|
          n = 1

          loop do
            yielder.yield (n * (n + 1)) / 2
            n += 1
          end
        end
      end
    end

    def sum_of_natural_numbers
      SumOfNaturalNumbersEnumerator.new
    end
  end
end
