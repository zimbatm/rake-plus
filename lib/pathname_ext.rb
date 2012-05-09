require 'pathname'

class Pathname
  alias / +
  def =~(regex); to_s =~ regex end
  def <=>(other); to_s <=> other.to_s end
  def length; to_s.length end
  alias size length
end

def path(*a)
  Pathname.new(File.join(*a))
end
