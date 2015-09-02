class Enumerator
  def ascending?
    self.next < self.next rescue StopIteration
  end
end
