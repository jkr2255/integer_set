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
      [:size, :length].each do |sym|
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
      expect { s.replace(-1..7) }.to raise_error(RangeError)
      expect { s.replace([9, 'a']) }.to raise_error(ArgumentError)
    end
  end

  describe '#to_a' do
    it 'returns empty Array with empty IntegerSet' do
      expect(IntegerSet.new.to_a).to eq([])
    end

    it 'returns members as Array' do
      expect(IntegerSet.from_range(1..100).to_a.sort).to eq([*1..100])
    end
  end

  describe '#to_set' do
    it 'returns self if no argument was given' do
      s = IntegerSet[1, 9]
      expect(s.to_set).to be_equal(s)
    end

    it 'returns new Set if Set was given' do
      s = IntegerSet[1, 9]
      expect(s.to_set(Set)).to eq(Set[1, 9])
    end
  end

  describe '#flatten' do
    it 'returns duplicated self' do
      s = IntegerSet[1, 9].freeze
      t = s.flatten
      expect(t).to eq(s)
      expect(t).not_to equal(s)
    end
  end

  describe '#flatten!' do
    it 'returns nil' do
      s = IntegerSet[1, 9]
      expect(s.flatten!).to be nil
    end
  end

  describe '#include?, #member?' do
    it 'returns true if value is in the set' do
      s = IntegerSet[1, 3]
      expect(s.include?(1)).to be true
      expect(s.member?(1)).to be true
    end

    it 'returns false if value is not in the set (regardless value is in the range)' do
      s = IntegerSet[1, 3]
      expect(s.include?(5)).to be false
      expect(s.include?('foo')).to be false
      expect(s.member?(5)).to be false
      expect(s.member?('foo')).to be false
    end
  end

  describe '#superset?, #>=' do
    it 'returns true with proper superset' do
      s = IntegerSet[1, 2, 3, 4]
      t = IntegerSet[1, 2, 3]
      u = Set[2, 3, 4]
      expect(s.superset?(t)).to be true
      expect(s).to be >= t
      expect(s.superset?(u)).to be true
      expect(s).to be >= u
    end

    it 'returns true with the same set' do
      s = IntegerSet[1, 2, 3, 4]
      t = Set[1, 2, 3, 4]
      expect(s.superset?(s)).to be true
      expect(s).to be >= s
      expect(s.superset?(t)).to be true
      expect(s).to be >= t
    end

    it 'returns false with not superset' do
      s = IntegerSet[1, 2, 3, 4]
      t = IntegerSet[1, 3, 5]
      u = Set[1, 3, 5]
      expect(s.superset?(t)).to be false
      expect(s).not_to be >= t
      expect(s.superset?(u)).to be false
      expect(s).not_to be >= u
    end

    it 'raises ArgumentError with other than Set' do
      s = IntegerSet[1, 2, 3, 4]
      expect { s.superset?([1, 2]) }.to raise_error(ArgumentError)
      expect { s.superset?(3) }.to raise_error(ArgumentError)
      expect { s >= [1, 2] }.to raise_error(ArgumentError)
      expect { s >= 3 }.to raise_error(ArgumentError)
    end
  end

  describe '#proper_superset?, #>' do
    it 'returns true with proper superset' do
      s = IntegerSet[1, 2, 3, 4]
      t = IntegerSet[1, 2, 3]
      u = Set[2, 3, 4]
      expect(s.proper_superset?(t)).to be true
      expect(s).to be > t
      expect(s.proper_superset?(u)).to be true
      expect(s).to be > u
    end

    it 'returns false with the same set' do
      s = IntegerSet[1, 2, 3, 4]
      t = Set[1, 2, 3, 4]
      expect(s.proper_superset?(s)).to be false
      expect(s).not_to be > s
      expect(s.proper_superset?(t)).to be false
      expect(s).not_to be > t
    end

    it 'returns false with not superset' do
      s = IntegerSet[1, 2, 3, 4]
      t = IntegerSet[1, 3, 5]
      u = Set[1, 3, 5]
      expect(s.proper_superset?(t)).to be false
      expect(s).not_to be > t
      expect(s.proper_superset?(u)).to be false
      expect(s).not_to be > u
    end

    it 'raises ArgumentError with other than Set' do
      s = IntegerSet[1, 2, 3, 4]
      expect { s.proper_superset?([1, 2]) }.to raise_error(ArgumentError)
      expect { s.proper_superset?(3) }.to raise_error(ArgumentError)
      expect { s > [1, 2] }.to raise_error(ArgumentError)
      expect { s > 3 }.to raise_error(ArgumentError)
    end
  end

  describe '#subset?, #<=' do
    it 'returns true with proper subset' do
      s = IntegerSet[1, 2, 3]
      t = IntegerSet[1, 2, 3, 4]
      u = Set[1, 2, 3, 4]
      expect(s.subset?(t)).to be true
      expect(s).to be <= t
      expect(s.subset?(u)).to be true
      expect(s).to be <= u
    end

    it 'returns true with the same set' do
      s = IntegerSet[1, 2, 3, 4]
      t = Set[1, 2, 3, 4]
      expect(s.subset?(s)).to be true
      expect(s).to be <= s
      expect(s.subset?(t)).to be true
      expect(s).to be <= t
    end

    it 'returns false with not subset' do
      s = IntegerSet[1, 2, 3, 4]
      t = IntegerSet[1, 3, 5]
      u = Set[1, 3, 5]
      expect(s.subset?(t)).to be false
      expect(s).not_to be <= t
      expect(s.subset?(u)).to be false
      expect(s).not_to be <= u
    end

    it 'raises ArgumentError with other than Set' do
      s = IntegerSet[1, 2, 3, 4]
      expect { s.subset?([1, 2]) }.to raise_error(ArgumentError)
      expect { s.subset?(3) }.to raise_error(ArgumentError)
      expect { s <= [1, 2] }.to raise_error(ArgumentError)
      expect { s <= 3 }.to raise_error(ArgumentError)
    end
  end

  describe '#proper_subset?, #<' do
    it 'returns true with proper subset' do
      s = IntegerSet[1, 2, 3]
      t = IntegerSet[1, 2, 3, 4]
      u = Set[1, 2, 3, 4]
      expect(s.proper_subset?(t)).to be true
      expect(s).to be < t
      expect(s.proper_subset?(u)).to be true
      expect(s).to be < u
    end

    it 'returns false with the same set' do
      s = IntegerSet[1, 2, 3, 4]
      t = Set[1, 2, 3, 4]
      expect(s.proper_subset?(s)).to be false
      expect(s).not_to be < s
      expect(s.proper_subset?(t)).to be false
      expect(s).not_to be < t
    end

    it 'returns false with not subset' do
      s = IntegerSet[1, 2, 3, 4]
      t = IntegerSet[1, 3, 5]
      u = Set[1, 3, 5]
      expect(s.proper_subset?(t)).to be false
      expect(s).not_to be < t
      expect(s.proper_subset?(u)).to be false
      expect(s).not_to be < u
    end

    it 'raises ArgumentError with other than Set' do
      s = IntegerSet[1, 2, 3, 4]
      expect { s.proper_subset?([1, 2]) }.to raise_error(ArgumentError)
      expect { s.proper_subset?(3) }.to raise_error(ArgumentError)
      expect { s < [1, 2] }.to raise_error(ArgumentError)
      expect { s < 3 }.to raise_error(ArgumentError)
    end
  end

  describe '#intersect?' do
    it 'returns true if one item is shared' do
      s = IntegerSet[1, 2, 3]
      t = IntegerSet[3, 4, 5]
      u = Set[2, 6, 10]
      expect(s).to be_intersect(t)
      expect(s).to be_intersect(u)
    end

    it 'returns false if no item is shared' do
      s = IntegerSet[1, 2, 3]
      t = IntegerSet[4, 5, 6]
      u = Set[7, 8, 9]
      expect(s).not_to be_intersect(t)
      expect(s).not_to be_intersect(u)
    end

    it 'raises ArgumentError if other than Set is specified' do
      s = IntegerSet[1, 2, 3]
      expect { s.intersect?([1, 2]) }.to raise_error(ArgumentError)
      expect { s.intersect?(3) }.to raise_error(ArgumentError)
    end
  end

  describe '#disjoint?' do
    it 'returns false if one item is shared' do
      s = IntegerSet[1, 2, 3]
      t = IntegerSet[3, 4, 5]
      u = Set[2, 6, 10]
      expect(s).not_to be_disjoint(t)
      expect(s).not_to be_disjoint(u)
    end

    it 'returns true if no item is shared' do
      s = IntegerSet[1, 2, 3]
      t = IntegerSet[4, 5, 6]
      u = Set[7, 8, 9]
      expect(s).to be_disjoint(t)
      expect(s).to be_disjoint(u)
    end

    it 'raises ArgumentError if other than Set is specified' do
      s = IntegerSet[1, 2, 3]
      expect { s.disjoint?([1, 2]) }.to raise_error(ArgumentError)
      expect { s.disjoint?(3) }.to raise_error(ArgumentError)
    end
  end

  describe '#each' do
    it 'returns Enumerator if block is not given' do
      s = IntegerSet[1, 2, 3]
      expect(s.each).to be_a(Enumerator)
    end

    it 'yields with each value' do
      expect { |b| IntegerSet.new.each(&b) }.not_to yield_control
      expect { |b| IntegerSet.from_range(1..100).each(&b) }.to yield_control.exactly(100).times
    end
  end

  describe '#add, #<<' do
    it 'modifies self' do
      s = IntegerSet[1, 2, 3]
      t = s.dup
      s.add(8)
      expect(s).not_to eq(t)
    end
  end

end
