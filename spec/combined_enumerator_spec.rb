require 'combined_enumerator'

describe CombinedOrderedEnumerator do
  it 'enumerating nothing' do
    enumerator = CombinedOrderedEnumerator.new
    expect(enumerator.take(20)).to eq []
  end

  it 'enumerating with a single enumerator' do
    enumerator = CombinedOrderedEnumerator.new((1..5).to_enum)
    expect(enumerator.take(10)).to eq [1, 2, 3, 4, 5]
  end

  it 'enumerating with two empty arrays' do
    enumerator = CombinedOrderedEnumerator.new([].to_enum, [].to_enum)
    expect(enumerator.take(20)).to eq []
  end

  it 'enumerating with one empty array and one finite sequence' do
    enumerator = CombinedOrderedEnumerator.new([].to_enum, (1..10).to_enum)
    expect(enumerator.take(20)).to eq [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  end

  it 'enumerating with one empty array and one finite sequence with switched args' do
    enumerator = CombinedOrderedEnumerator.new((1..10).to_enum, [].to_enum)
    expect(enumerator.take(20)).to eq [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  end

  it 'enumerating an infinite sequence and a finite one' do
    enumerator = CombinedOrderedEnumerator.new(fibonacci, (1..10).to_enum)
    expect(enumerator.take(20)).to eq [0, 1, 1, 1, 2, 2, 3, 3, 4, 5, 5, 6, 7, 8, 8, 9, 10, 13, 21, 34]
  end

  it 'enumerating two infinite sequences' do
    enumerator = CombinedOrderedEnumerator.new(fibonacci, sum_of_natural_numbers)
    expect(enumerator.take(20)).to eq [0, 1, 1, 1, 2, 3, 3, 5, 6, 8, 10, 13, 15, 21, 21, 28, 34, 36, 45, 55]
  end

  it 'enumerating three finite sequences' do
    enumerator = CombinedOrderedEnumerator.new((1..5).to_enum, (1..3).to_enum, (4..10).to_enum)
    expect(enumerator.take(20)).to eq [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 7, 8, 9, 10]
  end

  it 'enumerating three infinite sequences' do
    enumerator = CombinedOrderedEnumerator.new(fibonacci, fibonacci, fibonacci)
    expect(enumerator.take(12)).to eq [0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2]
  end

  it "raises UnorderedEnumeratorException if enumerator isn't in ascending order" do
    enumerator = CombinedOrderedEnumerator.new(10.downto(1))
    expect{ enumerator.take(20) }.to raise_error CombinedOrderedEnumerator::UnorderedEnumerator
  end

  it 'raising UnorderedEnumeratorException should reference enumerator' do
    descending_enumerator = 10.downto(1)
    enumerator = CombinedOrderedEnumerator.new(descending_enumerator)
    begin
      enumerator.take(2)
    rescue CombinedOrderedEnumerator::UnorderedEnumerator => exception
      expect(exception.enumerator).to eq descending_enumerator
    end
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
