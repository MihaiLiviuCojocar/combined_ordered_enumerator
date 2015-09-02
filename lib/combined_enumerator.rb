class CombinedOrderedEnumerator < Enumerator
  class UnorderedEnumerator < RuntimeError
    attr_reader :enumerator

    def initialize( enum )
      @enumerator = enum
    end
  end

  def initialize(*args)
    @enums = args
  end

  def take(number)
    @enums.map do |enum|
      raise CombinedOrderedEnumerator::UnorderedEnumerator.new(enum) unless enum.ascending?
      enum.take(number)
    end.flatten.sort[0...number]
  end
end
