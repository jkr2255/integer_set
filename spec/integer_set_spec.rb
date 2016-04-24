require 'spec_helper'

describe IntegerSet do
  it 'has a version number' do
    expect(IntegerSet::VERSION).not_to be nil
  end

  describe '.[]' do
    it 'creates IntegerSet' do
      expect(IntegerSet[0, 6, 100]).to eq(IntegerSet.new << 0 << 6 << 100)
    end

    it 'raises ArgumentError with out of range value' do
      expect { IntegerSet['aaa'] }.to raise_error(ArgumentError)
      expect { IntegerSet[-1] }.to raise_error(ArgumentError)
      expect { IntegerSet[3.0] }.to raise_error(ArgumentError)
      expect { IntegerSet[2**10_000] }.to raise_error(ArgumentError)
    end
  end

  describe '#new' do
    it 'accepts enumerable object' do
      expect(IntegerSet.new([0, 6, 10_000])).to eq(IntegerSet[0, 6, 10_000])
      expect(IntegerSet.new(1..4)).to eq(IntegerSet[1, 2, 3, 4])
    end

    it 'accepts block' do
      expect(IntegerSet.new([5]) { |i| i * 2 }).to eq(IntegerSet[10])
    end

    it 'raises ArgumentError with out of range value' do
      expect { IntegerSet.new([8, -1]) }.to raise_error(ArgumentError)
    end
  end

  describe '#size, #length' do
    it 'returns the count of set entries' do
      %i|size length|.each do |sym|
        expect(IntegerSet[800].public_send(sym)).to eq(1)
        expect(IntegerSet.new(1..10_000).public_send(sym)).to eq(10_000)
        expect(IntegerSet.new.public_send(sym)).to eq(0)
      end
    end
  end

  describe '#empty?' do
    it 'returns true with empty set' do
      expect(IntegerSet.new.empty?).to be true
    end

    it 'returns false with non-empty set' do
      expect(IntegerSet[0].empty?).to be false
    end
  end

  describe '#clear' do
    it 'returns self' do
      s = IntegerSet[1, 5]
      expect(s.clear).to be_equal(s)
    end

    it 'clears items' do
      s = IntegerSet[1, 5]
      expect(s.clear.size).to be 0
    end
  end

  describe '#replace' do
    it 'returns self' do
      s = IntegerSet[1, 8]
      t = IntegerSet[3, 6]
      expect(s.replace(t)).to be_equal(s)
    end

    it 'works with another IntegerSet' do
      s = IntegerSet[1, 8]
      t = IntegerSet[3, 6]
      s.replace(t)
      expect(s).to eq(t)
    end

    it 'works with another Set' do
      s = IntegerSet[1, 8]
      t = Set[3, 6]
      s.replace(t)
      expect(s).to eq(IntegerSet[3, 6])
    end

    it 'works with another Enumerable' do
      s = IntegerSet[1, 8]
      t = 3..6
      s.replace(t)
      expect(s).to eq(IntegerSet[3, 4, 5, 6])
    end

    it 'raises error with Enumerable containing out-of-range values' do
      s = IntegerSet[1, 8]
    end
  end

end
