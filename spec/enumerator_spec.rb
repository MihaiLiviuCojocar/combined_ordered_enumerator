require 'enumerator'

describe Enumerator do
  context 'ascending' do
    it 'knows when it is' do
      enumerator = (1..5).to_enum
      expect(enumerator).to be_ascending
    end

    it 'knows when it is not' do
      enumerator = 10.downto(1)
      expect(enumerator).not_to be_ascending
    end

    it 'does not raise an error' do
      enumerator = [].to_enum
      expect{ enumerator.ascending? }.not_to raise_error
    end
  end
end