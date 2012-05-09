require 'pathname'

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
