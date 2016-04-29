require 'spec_helper'

describe IntegerSet do
  it 'has a version number' do
    expect(IntegerSet::VERSION).not_to be nil
  end

  describe '.[]' do
    it 'creates IntegerSet' do
      expect(IntegerSet[0, 6, 100]).to eq(IntegerSet.new << 0 << 6 << 100)
    end

    it 'raises IntegerSet::DomainError with out of range value' do
      expect { IntegerSet['aaa'] }.to raise_error(IntegerSet::DomainError)
      expect { IntegerSet[-1] }.to raise_error(IntegerSet::DomainError)
      expect { IntegerSet[3.0] }.to raise_error(IntegerSet::DomainError)
      expect { IntegerSet[2**10_000] }.to raise_error(IntegerSet::DomainError)
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

    it 'raises IntegerSet::DomainError with out of range value' do
      expect { IntegerSet.new([8, -1]) }.to raise_error(IntegerSet::DomainError)
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
      expect { s.replace(-1..7) }.to raise_error(IntegerSet::DomainError)
      expect { s.replace([9, 'a']) }.to raise_error(IntegerSet::DomainError)
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
      s = IntegerSet[1, 9].freeze
      expect(s.to_set).to be_equal(s)
    end

    it 'returns new Set if Set was given' do
      s = IntegerSet[1, 9].freeze
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
      s = IntegerSet[1, 3].freeze
      expect(s.include?(1)).to be true
      expect(s.member?(1)).to be true
    end

    it 'returns false if value is not in the set (regardless value is in the range)' do
      s = IntegerSet[1, 3].freeze
      expect(s.include?(5)).to be false
      expect(s.include?('foo')).to be false
      expect(s.member?(5)).to be false
      expect(s.member?('foo')).to be false
    end
  end

  describe '#superset?, #>=' do
    it 'returns true with proper superset' do
      s = IntegerSet[1, 2, 3, 4].freeze
      t = IntegerSet[1, 2, 3].freeze
      u = Set[2, 3, 4].freeze
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
      s = IntegerSet[1, 2, 3, 4].freeze
      t = IntegerSet[1, 3, 5].freeze
      u = Set[1, 3, 5].freeze
      expect(s.superset?(t)).to be false
      expect(s).not_to be >= t
      expect(s.superset?(u)).to be false
      expect(s).not_to be >= u
    end

    it 'raises ArgumentError with other than Set' do
      s = IntegerSet[1, 2, 3, 4].freeze
      expect { s.superset?([1, 2]) }.to raise_error(ArgumentError)
      expect { s.superset?(3) }.to raise_error(ArgumentError)
      expect { s >= [1, 2] }.to raise_error(ArgumentError)
      expect { s >= 3 }.to raise_error(ArgumentError)
    end
  end

  describe '#proper_superset?, #>' do
    it 'returns true with proper superset' do
      s = IntegerSet[1, 2, 3, 4].freeze
      t = IntegerSet[1, 2, 3].freeze
      u = Set[2, 3, 4].freeze
      expect(s.proper_superset?(t)).to be true
      expect(s).to be > t
      expect(s.proper_superset?(u)).to be true
      expect(s).to be > u
    end

    it 'returns false with the same set' do
      s = IntegerSet[1, 2, 3, 4].freeze
      t = Set[1, 2, 3, 4].freeze
      expect(s.proper_superset?(s)).to be false
      expect(s).not_to be > s
      expect(s.proper_superset?(t)).to be false
      expect(s).not_to be > t
    end

    it 'returns false with not superset' do
      s = IntegerSet[1, 2, 3, 4].freeze
      t = IntegerSet[1, 3, 5].freeze
      u = Set[1, 3, 5].freeze
      expect(s.proper_superset?(t)).to be false
      expect(s).not_to be > t
      expect(s.proper_superset?(u)).to be false
      expect(s).not_to be > u
    end

    it 'raises ArgumentError with other than Set' do
      s = IntegerSet[1, 2, 3, 4].freeze
      expect { s.proper_superset?([1, 2]) }.to raise_error(ArgumentError)
      expect { s.proper_superset?(3) }.to raise_error(ArgumentError)
      expect { s > [1, 2] }.to raise_error(ArgumentError)
      expect { s > 3 }.to raise_error(ArgumentError)
    end
  end

  describe '#subset?, #<=' do
    it 'returns true with proper subset' do
      s = IntegerSet[1, 2, 3].freeze
      t = IntegerSet[1, 2, 3, 4].freeze
      u = Set[1, 2, 3, 4].freeze
      expect(s.subset?(t)).to be true
      expect(s).to be <= t
      expect(s.subset?(u)).to be true
      expect(s).to be <= u
    end

    it 'returns true with the same set' do
      s = IntegerSet[1, 2, 3, 4].freeze
      t = Set[1, 2, 3, 4].freeze
      expect(s.subset?(s)).to be true
      expect(s).to be <= s
      expect(s.subset?(t)).to be true
      expect(s).to be <= t
    end

    it 'returns false with not subset' do
      s = IntegerSet[1, 2, 3, 4].freeze
      t = IntegerSet[1, 3, 5].freeze
      u = Set[1, 3, 5].freeze
      expect(s.subset?(t)).to be false
      expect(s).not_to be <= t
      expect(s.subset?(u)).to be false
      expect(s).not_to be <= u
    end

    it 'raises ArgumentError with other than Set' do
      s = IntegerSet[1, 2, 3, 4].freeze
      expect { s.subset?([1, 2]) }.to raise_error(ArgumentError)
      expect { s.subset?(3) }.to raise_error(ArgumentError)
      expect { s <= [1, 2] }.to raise_error(ArgumentError)
      expect { s <= 3 }.to raise_error(ArgumentError)
    end
  end

  describe '#proper_subset?, #<' do
    it 'returns true with proper subset' do
      s = IntegerSet[1, 2, 3].freeze
      t = IntegerSet[1, 2, 3, 4].freeze
      u = Set[1, 2, 3, 4].freeze
      expect(s.proper_subset?(t)).to be true
      expect(s).to be < t
      expect(s.proper_subset?(u)).to be true
      expect(s).to be < u
    end

    it 'returns false with the same set' do
      s = IntegerSet[1, 2, 3, 4].freeze
      t = Set[1, 2, 3, 4].freeze
      expect(s.proper_subset?(s)).to be false
      expect(s).not_to be < s
      expect(s.proper_subset?(t)).to be false
      expect(s).not_to be < t
    end

    it 'returns false with not subset' do
      s = IntegerSet[1, 2, 3, 4].freeze
      t = IntegerSet[1, 3, 5].freeze
      u = Set[1, 3, 5].freeze
      expect(s.proper_subset?(t)).to be false
      expect(s).not_to be < t
      expect(s.proper_subset?(u)).to be false
      expect(s).not_to be < u
    end

    it 'raises ArgumentError with other than Set' do
      s = IntegerSet[1, 2, 3, 4].freeze
      expect { s.proper_subset?([1, 2]) }.to raise_error(ArgumentError)
      expect { s.proper_subset?(3) }.to raise_error(ArgumentError)
      expect { s < [1, 2] }.to raise_error(ArgumentError)
      expect { s < 3 }.to raise_error(ArgumentError)
    end
  end

  describe '#intersect?' do
    it 'returns true if one item is shared' do
      s = IntegerSet[1, 2, 3].freeze
      t = IntegerSet[3, 4, 5].freeze
      u = Set[2, 6, 10].freeze
      expect(s).to be_intersect(t)
      expect(s).to be_intersect(u)
    end

    it 'returns false if no item is shared' do
      s = IntegerSet[1, 2, 3].freeze
      t = IntegerSet[4, 5, 6].freeze
      u = Set[7, 8, 9].freeze
      expect(s).not_to be_intersect(t)
      expect(s).not_to be_intersect(u)
    end

    it 'raises ArgumentError if other than Set is specified' do
      s = IntegerSet[1, 2, 3].freeze
      expect { s.intersect?([1, 2]) }.to raise_error(ArgumentError)
      expect { s.intersect?(3) }.to raise_error(ArgumentError)
    end
  end

  describe '#disjoint?' do
    it 'returns false if one item is shared' do
      s = IntegerSet[1, 2, 3].freeze
      t = IntegerSet[3, 4, 5].freeze
      u = Set[2, 6, 10].freeze
      expect(s).not_to be_disjoint(t)
      expect(s).not_to be_disjoint(u)
    end

    it 'returns true if no item is shared' do
      s = IntegerSet[1, 2, 3].freeze
      t = IntegerSet[4, 5, 6].freeze
      u = Set[7, 8, 9].freeze
      expect(s).to be_disjoint(t)
      expect(s).to be_disjoint(u)
    end

    it 'raises ArgumentError if other than Set is specified' do
      s = IntegerSet[1, 2, 3].freeze
      expect { s.disjoint?([1, 2]) }.to raise_error(ArgumentError)
      expect { s.disjoint?(3) }.to raise_error(ArgumentError)
    end
  end

  describe '#each' do
    it 'returns Enumerator if block is not given' do
      s = IntegerSet[1, 2, 3].freeze
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

    it 'raises IntegerSet::DomainError if value is out of range' do
      s = IntegerSet[1, 2, 3]
      expect { s.add(-1) }.to raise_error(IntegerSet::DomainError)
      expect { s << 'a' }.to raise_error(IntegerSet::DomainError)
    end
  end

  describe '#add?' do
    it 'adds item & returns self (with proper & not found value)' do
      s = IntegerSet[1, 2, 3]
      ret = s.add?(4)
      expect(ret).to equal(s)
      expect(s.include?(4)).to be true
    end

    it 'returns nil if already a member' do
      s = IntegerSet[1, 2, 3]
      expect(s.add?(1)).to be nil
    end

    it 'raises IntegerSet::DomainError if value is out of range' do
      s = IntegerSet[1, 2, 3]
      expect { s.add?(-1) }.to raise_error(IntegerSet::DomainError)
      expect { s.add?('a') }.to raise_error(IntegerSet::DomainError)
    end
  end

  describe '#delete' do
    it 'returns modified self' do
      s = IntegerSet[1, 2, 3]
      t = s.dup
      expect(s.delete(2)).to equal(s)
      expect(s).not_to eq(t)
    end

    it 'returns self if delete is not necessary' do
      s = IntegerSet[1, 2, 3]
      t = s.dup
      expect(s.delete(5)).to equal s
      expect(s.delete('a')).to equal s
      expect(s).to be == t
    end
  end

  describe '#delete?' do
    it 'returns modified self if deleted' do
      s = IntegerSet[1, 2, 3]
      t = s.dup
      expect(s.delete?(2)).to equal(s)
      expect(s).not_to eq(t)
    end

    it 'returns nil if delete is not necessary' do
      s = IntegerSet[1, 2, 3]
      t = s.dup
      expect(s.delete?(5)).to be nil
      expect(s.delete?('a')).to be nil
      expect(s).to eq t
    end
  end

  describe '#delete_if' do
    it 'returns Enumerator if block was not given' do
      s = IntegerSet[1, 2, 3]
      expect(s.delete_if).to be_a Enumerator
    end

    it 'returns self if block is given' do
      s = IntegerSet[1, 2, 3]
      expect(s.delete_if {}).to equal s
    end

    it 'removes items if block return true' do
      s = IntegerSet[1, 2, 3]
      expect(s.delete_if { |i| i == 2 }).to eq IntegerSet[1, 3]
    end
  end

  describe '#keep_if' do
    it 'returns Enumerator if block was not given' do
      s = IntegerSet[1, 2, 3]
      expect(s.keep_if).to be_a Enumerator
    end

    it 'returns self if block is given' do
      s = IntegerSet[1, 2, 3]
      expect(s.keep_if {}).to equal s
    end

    it 'removes items if block return false' do
      s = IntegerSet[1, 2, 3]
      expect(s.keep_if { |i| i != 2 }).to eq IntegerSet[1, 3]
    end
  end

  describe '#collect!' do
    it 'returns Enumerator if block was not given' do
      s = IntegerSet[1, 2, 3]
      expect(s.collect!).to be_a Enumerator
    end

    it 'returns self modified by block' do
      s = IntegerSet[1, 2, 3]
      expect(s.collect!(&:next)).to equal s
      expect(s).to eq(IntegerSet[2, 3, 4])
    end

    it 'raises IntegerSet::DomainError if block returns invalid values' do
      s = IntegerSet[1, 2, 3]
      expect { s.collect! { nil } }.to raise_error IntegerSet::DomainError
    end
  end

  describe '#reject!' do
    it 'returns Enumerator if block was not given' do
      s = IntegerSet[1, 2, 3]
      expect(s.reject!).to be_a Enumerator
    end

    it 'removes modified self if deleted' do
      s = IntegerSet[1, 2, 3]
      expect(s.reject! { |i| i == 2 }).to equal s
      expect(s).to eq IntegerSet[1, 3]
    end

    it 'returns nil if no items deleted' do
      s = IntegerSet[1, 2, 3]
      expect(s.reject! { |i| i == 4 }).to be nil
    end
  end

  describe '#select!' do
    it 'returns Enumerator if block was not given' do
      s = IntegerSet[1, 2, 3]
      expect(s.select!).to be_a Enumerator
    end

    it 'removes modified self unless all selected' do
      s = IntegerSet[1, 2, 3]
      expect(s.select! { |i| i != 2 }).to equal s
      expect(s).to eq IntegerSet[1, 3]
    end

    it 'returns nil if all items selected' do
      s = IntegerSet[1, 2, 3]
      expect(s.select! { true }).to be nil
    end
  end

  describe '#merge' do
    it 'works well with other IntegerSet' do
      s = IntegerSet[1, 2, 3]
      t = IntegerSet[3, 5, 7]
      expect(s.merge(t)).to eq(IntegerSet[1, 2, 3, 5, 7])
    end

    it 'works well with other Set (in range)' do
      s = IntegerSet[1, 2, 3]
      t = Set[3, 5, 7]
      expect(s.merge(t)).to eq(IntegerSet[1, 2, 3, 5, 7])
    end

    it 'works well with other suitable Range' do
      s = IntegerSet[3, 5, 7]
      t = 1..3
      expect(s.merge(t)).to eq(IntegerSet[1, 2, 3, 5, 7])
    end

    it 'works well with other suitable Enumerable' do
      s = IntegerSet[3, 5, 7]
      t = [1, 2, 3]
      expect(s.merge(t)).to eq(IntegerSet[1, 2, 3, 5, 7])
    end

    it 'raises IntegerSet::DomainError with out-of-range Set' do
      s = IntegerSet[1, 2, 3]
      t = Set['a', 'b']
      expect { s.merge(t)}.to raise_error IntegerSet::DomainError
    end

    it 'raises IntegerSet::DomainError with out-of-range Range' do
      s = IntegerSet[1, 2, 3]
      t = -1..8
      expect { s.merge(t)}.to raise_error IntegerSet::DomainError
    end

    it 'raises IntegerSet::DomainError with out-of-range Enumerable' do
      s = IntegerSet[1, 2, 3]
      t = ['a', 'b']
      expect { s.merge(t)}.to raise_error IntegerSet::DomainError
    end
  end

  describe '#subtract' do
    it 'returns modified self' do
      s = IntegerSet[1, 2, 3]
      t = IntegerSet[3, 5, 7]
      expect(s.subtract(t)).to equal s
      expect(s).to eq IntegerSet[1, 2]
    end

    it 'works well with partially out-of-range Range' do
      s = IntegerSet[1, 2, 3]
      t = -1..1
      expect(s.subtract(t)).to equal s
      expect(s).to eq IntegerSet[2, 3]
    end

    it 'does nothing with out-of-range Enumerable' do
      s = IntegerSet[1, 2, 3]
      t = ['a', nil]
      expect(s.subtract(t)).to equal s
    end
  end

  describe '#|' do
    it 'works well with other IntegerSet' do
      s = IntegerSet[1, 2, 3].freeze
      t = IntegerSet[3, 5, 7].freeze
      expect(s | t).to eq IntegerSet[1, 2, 3, 5, 7]
    end

    it 'returns IntegerSet if Set content is in range' do
      s = IntegerSet[1, 2, 3].freeze
      t = Set[3, 5, 7].freeze
      ret = s | t
      expect(ret).to be_a(IntegerSet)
      expect(ret).to eq IntegerSet[1, 2, 3, 5, 7]
    end

    it 'returns Set if Set is provided and content is out of range' do
      s = IntegerSet[1, 2, 3].freeze
      t = Set[3, 5, 'hoge'].freeze
      ret = s | t
      expect(ret).to be_a(Set)
      expect(ret).to eq Set[1, 2, 3, 5, 'hoge']
    end

    it 'works well with proper Range' do
      s = IntegerSet[1, 2, 3].freeze
      t = 3..6
      ret = s | t
      expect(ret).to be_a(IntegerSet)
      expect(ret).to eq IntegerSet[1, 2, 3, 4, 5, 6]
    end

    it 'raises IntegerSet::DomainError if out of range Range' do
      s = IntegerSet[1, 2, 3].freeze
      t = -1..10
      expect { s | t }.to raise_error IntegerSet::DomainError
    end

    it 'raises IntegerSet::DomainError if out of range Enumerable' do
      s = IntegerSet[1, 2, 3].freeze
      t = %w|a b c|
      expect { s | t }.to raise_error IntegerSet::DomainError
    end
  end

  describe '#-' do
    it 'works well with other IntegerSet' do
      s = IntegerSet[1, 2, 3].freeze
      t = IntegerSet[3, 5, 7].freeze
      expect(s - t).to eq IntegerSet[1, 2]
    end

    it 'works well with other Set' do
      s = IntegerSet[1, 2, 3].freeze
      t = Set[3, 5, 7, 'foo'].freeze
      ret = s - t
      expect(ret).to be_a(IntegerSet)
      expect(ret).to eq IntegerSet[1, 2]
    end

    it 'works well with proper Range' do
      s = IntegerSet[1, 2, 3].freeze
      t = 3..6
      ret = s - t
      expect(ret).to be_a(IntegerSet)
      expect(ret).to eq IntegerSet[1, 2]
    end

    it 'works well with partially out of Range' do
      s = IntegerSet[1, 2, 3].freeze
      t = -1..1
      expect(s - t).to eq IntegerSet[2, 3]
    end

    it 'does nothing with out-of-range Enumerable' do
      s = IntegerSet[1, 2, 3].freeze
      t = %w|a b c|
      expect(s - t).to eq s
    end
  end

end
