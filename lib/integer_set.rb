# Based on set.rb bundled with Ruby.
#
# set.rb license:
#++
# Copyright (c) 2002-2013 Akinori MUSHA <knu@iDaemons.org>
#
# Documentation by Akinori MUSHA and Gavin Sinclair.
#
# All rights reserved.  You can redistribute and/or modify it under the same
# terms as Ruby.
#
# for integer_set.rb:
# Copyright (c) 2016 Jkr2255.


require "integer_set/version"
require 'bit_counter'
require 'set'

if defined?(JRUBY_VERSION)
  # Calling Java is faster than pure Ruby (backports)
  require 'integer_set/jruby_bit_length'
else
  require 'backports/2.1.0/fixnum/bit_length'
  require 'backports/2.1.0/bignum/bit_length'
end

#
# Fast set consisting only of integers.
# Interface is like Ruby-bundled set.
#
class IntegerSet
  include Enumerable

  # Creates a new set containing the given objects.
  def self.[](*ary)
    new(ary)
  end

  # Creates a new set containing the elements of the given enumerable
  # object.
  #
  # If a block is given, the elements of enum are preprocessed by the
  # given block.
  def initialize(enum = nil, &block) # :yields: o
    @val = 0

    enum.nil? and return

    if block
      do_with_enum(enum) { |o| add(block[o]) }
    else
      merge(enum)
    end
  end

  def do_with_enum(enum, &block) # :nodoc:
    if enum.respond_to?(:each_entry)
      enum.each_entry(&block)
    elsif enum.respond_to?(:each)
      enum.each(&block)
    else
      raise ArgumentError, "value must be enumerable"
    end
  end
  private :do_with_enum

  # Copying IntegerSet is merely copying of integer,
  # so no special treatment is necessary

  # Returns the number of elements.
  def size
    BitCounter.count(@val)
  end
  alias length size

  # Returns true if the set contains no elements.
  def empty?
    @val == 0
  end

  # Removes all elements and returns self.
  def clear
    @val = 0
    self
  end

  # Replaces the contents of the set with the contents of the given
  # enumerable object and returns self.
  def replace(enum)
    if enum.instance_of?(self.class)
      @val = enum.instance_variable_get(:@val)
    else
      clear
      merge(enum)
    end

    self
  end

  # Converts the set to an array.  The order of elements is uncertain.
  def to_a
    unchecked = @val
    shift = 0
    arr = []
    while unchecked > 0
      bit = unchecked & -unchecked
      pos = bit.bit_length - 1
      arr << (pos + shift)
      unchecked >>= (pos + 1)
      shift += pos + 1
    end
    arr
  end

  # Returns self if no arguments are given.  Otherwise, converts the
  # set to another with klass.new(self, *args, &block).
  #
  # In subclasses, returns klass.new(self, *args, &block) unless
  # overridden.
  def to_set(klass = IntegerSet, *args, &block)
    return self if instance_of?(IntegerSet) && klass == IntegerSet && block.nil? && args.empty?
    klass.new(self, *args, &block)
  end

  # Returns a new set that is a copy of the set.
  # IntegerSet contains no set, so simply return dup.
  def flatten
    dup
  end

  # Always returns nil, for no IntegerSet contains another Set.
  def flatten!
    nil
  end

  # Returns true if the set contains the given object.
  def include?(o)
    return false unless valid_member?(o)
    @val[o] != 0
  end
  alias member? include?

  # Returns true if the set is a superset of the given set.
  def superset?(set)
    return (~@val & set.to_i) == 0 if set.is_a?(IntegerSet)
    set.is_a?(Set) or raise ArgumentError, "value must be a set"
    return false if size < set.size
    set.all? { |o| include?(o) }
  end
  alias >= superset?

  # Returns true if the set is a proper superset of the given set.
  def proper_superset?(set)
    return self != set && superset?(set) if set.is_a?(IntegerSet)
    set.is_a?(Set) or raise ArgumentError, "value must be a set"
    return false if size <= set.size
    set.all? { |o| include?(o) }
  end
  alias > proper_superset?

  # Returns true if the set is a subset of the given set.
  def subset?(set)
    return (@val & ~set.to_i) == 0 if set.is_a?(IntegerSet)
    set.is_a?(Set) or raise ArgumentError, "value must be a set"
    return false if set.size < size
    all? { |o| set.include?(o) }
  end
  alias <= subset?

  # Returns true if the set is a proper subset of the given set.
  def proper_subset?(set)
    return self != set && subset?(set) if set.is_a?(IntegerSet)
    set.is_a?(Set) or raise ArgumentError, "value must be a set"
    return false if set.size <= size
    all? { |o| set.include?(o) }
  end
  alias < proper_subset?

  # Returns true if the set and the given set have at least one
  # element in common.
  def intersect?(set)
    return (@val & set.to_i) > 0 if set.is_a?(IntegerSet)
    set.is_a?(Set) or raise ArgumentError, "value must be a set"
    if size < set.size
      any? { |o| set.include?(o) }
    else
      set.any? { |o| include?(o) }
    end
  end

  # Returns true if the set and the given set have no element in
  # common.  This method is the opposite of +intersect?+.
  def disjoint?(set)
    !intersect?(set)
  end

  # Calls the given block once for each element in the set, passing
  # the element as parameter.  Returns an enumerator if no block is
  # given.
  def each(&block)
    block or return enum_for(__method__)
    to_a.each(&block)
    self
  end

  # Adds the given object to the set and returns self.  Use +merge+ to
  # add many elements at once.
  def add(o)
    validate_member!(o)
    @val |= 1 << o
    self
  end
  alias << add

  # Adds the given object to the set and returns self.  If the
  # object is already in the set, returns nil.
  def add?(o)
    if include?(o)
      nil
    else
      add(o)
    end
  end

  # Deletes the given object from the set and returns self.  Use +subtract+ to
  # delete many items at once.
  def delete(o)
    @val &= ~(1 << o) if valid_member?(o)
    self
  end

  # Deletes the given object from the set and returns self.  If the
  # object is not in the set, returns nil.
  def delete?(o)
    if include?(o)
      delete(o)
    else
      nil
    end
  end

  # Deletes every element of the set for which block evaluates to
  # true, and returns self.
  def delete_if
    block_given? or return enum_for(__method__)
    select { |o| yield o }.each { |o| delete(o) }
    self
  end

  # Deletes every element of the set for which block evaluates to
  # false, and returns self.
  def keep_if
    block_given? or return enum_for(__method__)
    reject { |o| yield o }.each { |o| delete(o) }
    self
  end

  # Replaces the elements with ones returned by collect().
  def collect!
    block_given? or return enum_for(__method__)
    set = self.class.new
    each { |o| set << yield(o) }
    replace(set)
  end
  alias map! collect!

  # Equivalent to Set#delete_if, but returns nil if no changes were
  # made.
  def reject!(&block)
    block or return enum_for(__method__)
    n = size
    delete_if(&block)
    size == n ? nil : self
  end

  # Equivalent to Set#keep_if, but returns nil if no changes were
  # made.
  def select!(&block)
    block or return enum_for(__method__)
    n = size
    keep_if(&block)
    size == n ? nil : self
  end

  # Merges the elements of the given enumerable object to the set and
  # returns self.
  def merge(enum)
    enum = IntegerSet.from_range(enum) if enum.is_a?(Range)
    if enum.instance_of?(IntegerSet)
      @val |= enum.to_i
    else
      do_with_enum(enum) { |o| add(o) }
    end

    self
  end

  # Deletes every element that appears in the given enumerable object
  # and returns self.
  def subtract(enum)
    if enum.instance_of?(IntegerSet)
      @val &= ~enum.to_i
    else
      do_with_enum(enum) { |o| delete(o) }
    end

    self
  end

  # Returns a new set built by merging the set and the elements of the
  # given enumerable object.
  def |(enum)
    if enum.is_a?(Set)
      enum = try_integer_set(enum)
      return enum.dup.merge(self) unless enum.is_a?(IntegerSet)
    end
    dup.merge(enum)
  end
  alias + |             ##
  alias union |         ##

  # Returns a new set built by duplicating the set, removing every
  # element that appears in the given enumerable object.
  def -(enum)
    dup.subtract(enum)
  end
  alias difference -    ##

  # Returns a new set containing elements common to the set and the
  # given enumerable object.
  def &(enum)
    if enum.instance_of?(IntegerSet)
      n = self.class.from_i(@val & enum.to_i)
    else
      n = self.class.new
      do_with_enum(enum) { |o| n.add(o) if include?(o) }
    end
    n
  end
  alias intersection &  ##

  # Returns a new set containing elements exclusive between the set
  # and the given enumerable object.  (set ^ enum) is equivalent to
  # ((set | enum) - (set & enum)).
  def ^(enum)
    if enum.is_a?(Set)
      enum = try_integer_set(enum)
      return enum.is_a?(IntegerSet) ? self.class.from_i(@val ^ enum.to_i) : enum ^ self
    end
    n = IntegerSet.new(enum)
    each { |o| if n.include?(o) then n.delete(o) else n.add(o) end }
    n
  end

  # Returns true if two sets are equal.  The equality of each couple
  # of elements is defined according to Object#eql?.
  def ==(other)
    if other.instance_of?(self.class)
      @val == other.to_i
    elsif other.is_a?(Set) && size == other.size
      other.all? { |o| include?(o) }
    else
      false
    end
  end

  def hash      # :nodoc:
    @val.hash
  end

  def eql?(o)   # :nodoc:
    o.instance_of?(self.class) && @val.eql?(o.to_i)
  end

  # Classifies the set by the return value of the given block and
  # returns a hash of {value => set of elements} pairs.  The block is
  # called once for each element of the set, passing the element as
  # parameter.
  #
  # e.g.:
  #
  #   require 'set'
  #   files = Set.new(Dir.glob("*.rb"))
  #   hash = files.classify { |f| File.mtime(f).year }
  #   p hash    # => {2000=>#<Set: {"a.rb", "b.rb"}>,
  #             #     2001=>#<Set: {"c.rb", "d.rb", "e.rb"}>,
  #             #     2002=>#<Set: {"f.rb"}>}
  def classify # :yields: o
    block_given? or return enum_for(__method__)

    h = {}

    each { |i|
      x = yield(i)
      (h[x] ||= self.class.new).add(i)
    }

    h
  end

  # Divides the set into a set of subsets according to the commonality
  # defined by the given block.
  #
  # If the arity of the block is 2, elements o1 and o2 are in common
  # if block.call(o1, o2) is true.  Otherwise, elements o1 and o2 are
  # in common if block.call(o1) == block.call(o2).
  #
  # e.g.:
  #
  #   require 'set'
  #   numbers = Set[1, 3, 4, 6, 9, 10, 11]
  #   set = numbers.divide { |i,j| (i - j).abs == 1 }
  #   p set     # => #<Set: {#<Set: {1}>,
  #             #            #<Set: {11, 9, 10}>,
  #             #            #<Set: {3, 4}>,
  #             #            #<Set: {6}>}>
  def divide(&func)
    func or return enum_for(__method__)

    if func.arity == 2
      require 'tsort'

      class << dig = {}         # :nodoc:
        include TSort

        alias tsort_each_node each_key
        def tsort_each_child(node, &block)
          fetch(node).each(&block)
        end
      end

      each { |u|
        dig[u] = a = []
        each{ |v| func.call(u, v) and a << v }
      }

      set = Set.new()
      dig.each_strongly_connected_component { |css|
        set.add(self.class.new(css))
      }
      set
    else
      Set.new(classify(&func).values)
    end
  end


  # Returns a string containing a human-readable representation of the
  # set. ("#<IntegerSet: {element1, element2, ...}>")
  def inspect
    sprintf('#<%s: {%s}>', self.class, to_a.inspect[1..-2])
  end

  def pretty_print(pp)  # :nodoc:
    pp.text sprintf('#<%s: {', self.class.name)
    pp.nest(1) {
      pp.seplist(self) { |o|
        pp.pp o
      }
    }
    pp.text "}>"
  end

  ##### original in IntegerSet

  # error class for out of IntegerSet's range
  class DomainError < RangeError; end

  def valid_member?(val)
    return false unless val.is_a?(Integer)
    val >= 0 && val <= self.class.maximum
  end

  private :valid_member?

  def validate_member!(val)
    raise DomainError, 'Out of range for IntegerSet' unless valid_member?(val)
  end

  private :validate_member!

  # Returns internal representation of set.
  # x is included iff (1 << x) & to_i != 0.
  def to_i
    @val
  end

  # Create IntegerSet from integer.
  def self.from_i(val)
    raise TypeError, 'IntegerSet.from_i with invalid type' unless val.is_a?(Integer)
    raise ArgumentError, 'IntegerSet cannot be created from negative integer' if val < 0
    s = new
    s.instance_variable_set(:@val, val)
    s
  end

  # Create IntegerSet From Range
  def self.from_range(range)
    error = DomainError.new 'Unsuitable Range for IntegerSet#from_range'
    first = range.first
    last = range.last
    # empty Range
    return new if (first > last) || (range.exclude_end? && first == last)
    raise error unless first.is_a?(Integer) && last.is_a?(Integer)
    last -= 1 if range.exclude_end?
    raise error if first < 0
    from_i((1 << (last + 1)) - (1 << first))
  end

  # pretending to be a Set
  def is_a?(klass)
    return true if klass == Set
    super
  end

  alias kind_of? is_a?

  def try_integer_set(set) #:nodoc:
    return set if set.is_a?(IntegerSet)
    raise TypeError unless set.is_a?(Set)
    return set unless set.all? { |val| valid_member?(val) }
    self.class.new set
  end

  private :try_integer_set

  # class instance variable
  @maximum = 1_048_576

  class << self
    attr_reader :maximum

    def maximum=(num)
      raise ArgumentError if num <= 0
      @maximum = num
    end
  end

end
