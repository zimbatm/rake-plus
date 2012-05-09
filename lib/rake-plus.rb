require 'rake-plus/trace'
require 'rake-plus/path'

module RakePlus
  @top = path(Dir.pwd)
  @cache_dir = @top / '.cache'
  @build_dir = @top / 'build'
  @template_dir = @top / 'tpl'

  class << self
    attr_reader :top
    attr_accessor :cache_dir
    attr_accessor :build_dir
    attr_accessor :template_dir
  end
end
