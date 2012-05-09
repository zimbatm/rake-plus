require 'pathname'

# Patching Pathame to return self.class.new objects instead of Pathname.new
class Pathname
  def +(other)
    other = self.class.new(other) unless other.kind_of?(Pathname)
    self.class.new(plus(@path, other.to_s))
  end

  def join(*args)
    args.unshift self
    result = args.pop
    result = self.class.new(result) unless result.kind_of?(Pathname)
    return result if result.absolute?
    args.reverse_each {|arg|
      arg = self.class.new(arg) unless arg.kind_of?(Pathname)
      result = arg + result
      return result if result.absolute?
    }
    result
  end

  def relative_path_from(base_directory)
    dest_directory = self.cleanpath.to_s
    base_directory = base_directory.cleanpath.to_s
    dest_prefix = dest_directory
    dest_names = []
    while r = chop_basename(dest_prefix)
      dest_prefix, basename = r
      dest_names.unshift basename if basename != '.'
    end
    base_prefix = base_directory
    base_names = []
    while r = chop_basename(base_prefix)
      base_prefix, basename = r
      base_names.unshift basename if basename != '.'
    end
    unless SAME_PATHS[dest_prefix, base_prefix]
      raise ArgumentError, "different prefix: #{dest_prefix.inspect} and #{base_directory.inspect}"
    end
    while !dest_names.empty? &&
          !base_names.empty? &&
          SAME_PATHS[dest_names.first, base_names.first]
      dest_names.shift
      base_names.shift
    end
    if base_names.include? '..'
      raise ArgumentError, "base_directory has ..: #{base_directory.inspect}"
    end
    base_names.fill('..')
    relpath_names = base_names + dest_names
    if relpath_names.empty?
      self.class.new('.')
    else
      self.class.new(File.join(*relpath_names))
    end
  end
end

# Like a Pathname but behaves more like a string
class Path < Pathname
  alias / +
  def =~(regex); to_s =~ regex end
  def <=>(other); to_s <=> other.to_s end
  def length; to_s.length end
  alias size length

  def method_missing(m, *a, &b)
    s = to_s
    if s.respond_to? m
      s.send(m, *a, &b)
    else
      super
    end
  end

  def respond_to?(m)
    super || to_s.respond_to?(m)
  end

  alias expand expand_path

  def self.[](*args)
    new File.join(*args.map(&:to_s))
  end
end

def path(*args)
  Path[ *args ]
end
