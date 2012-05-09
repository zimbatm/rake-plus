require 'rake-plus'
require 'rake-plus/rake_ext'

class Recipe < Rake::Task
  include Rake::DSL if defined? Rake::DSL
  BUILD_SYSTEM  = `uname -sm`.strip.gsub(' ', '-').downcase

  @@defaults = {}

  class << self
    def var(name, &default)
      if block_given?
        @@defaults[name.to_s] = default

        class_eval <<-CODE
        def #{name}(val=nil)
          if !val.nil?
            @#{name} = val
          elsif @#{name}.nil?
            @#{name} = instance_eval(&@@defaults["#{name}"])
          end
          @#{name}
        end
        CODE
      else
        class_eval <<-CODE
        def #{name}(val=nil)
          @#{name} = val unless val.nil?
          @#{name}
        end
        CODE
      end
      self
    end
  end

  # Variables for the DSL
  def url_or_git
    @url || @git || @svn
  end

  var :unpack_dir do
    url_or_git.basename.sub('.tar.gz','').sub('.tar.bz2','')
  end
  var :build_dir do
    # : causes trouble in PATH
    sub = name.split(':')
    sub[0] = sub[0] + '-' + BUILD_SYSTEM
    RakePlus.build_dir / sub.join('/')
  end
  var :src_dir do
    build_dir / 'src'
  end
  var :dep_dir do
    build_dir / 'dep'
  end
  var :prefix do
    build_dir / 'install'
  end
  def bdeps(val=nil)
    unless val.nil?
      val = [val] unless val.kind_of? Array
      @bdeps = val.map{|x| x.kind_of?(Recipe) ? x : recipe(x)}
    end
    @bdeps || []
  end
  var :static_install
  def install(&block)
    @install ||= block
    @install ||= proc do
      mkdir_p(prefix)
      sh "./configure --prefix=#{prefix}#{static_install ? " --enable-static --disable-shared" : ''}"
      sh "make"
      sh "make install"
    end
    @install
  end
  def url(val=nil)
    unless val.nil?
      @url = remote_package(val)
    end
    @url
  end
  def git(val=nil)
    unless val.nil?
      @git = git_dep(val)
    end
    @git
  end
  
  def svn(val=nil)
    unless val.nil?
      @svn = svn_dep(val)
    end
    @svn
  end
  
  def patches
    @patches ||= []
  end
  def patch(val)
    patches.push(val)
  end

  def install_to(dir)
    sh "cp -r #{prefix}/* #{dir}"
  end

  def needed?
    file_missing?(build_dir / "install.done") || out_of_date?(timestamp)
  end

  def timestamp
    if File.exist?(build_dir / "install.done")
      File.mtime(build_dir / "install.done")
    else
      Rake::EARLY
    end
  end

  def opts_to_string(opts)
    ary = []
    opts.each_pair do |k,v|
      ary << "--#{k}=#{v}"
    end
    ary.join(' ')
  end

  def flags_to_features(*flags)
    flags.flatten.map do |x|
      case x
      when /^\+/
        x.gsub(/^\+/,'--enable-')
      when /^-/
        x.gsub(/^-/,'--disable-')
      when /^\/\//, /^\s*$/
        nil
      else
        raise ArgumentError, "unknown flag: #{x}"
      end
    end.compact.join(' ')
  end

  def define(&block)
    raise "Already defined" if @defined
    instance_eval(&block)
    raise "Missing @url or @git" unless url_or_git

    directory build_dir
    directory src_dir

    patches.each{|p| file(p) }


    file(build_dir / "src.done" => [url_or_git, build_dir, src_dir] + patches) do |t|
      sh "rm -rf #{src_dir}/*"
      url_or_git.unpack_to src_dir

      # Apply patches
      Dir.chdir(src_dir / unpack_dir) do
        patches.each do |p|
          sh "patch -b -f -N -p0 < #{RakePlus.top / p}"
        end
      end

      touch t.name
    end

    self.class.define_task(self.name.sub(/.*:/,'') => bdeps + [build_dir / "src.done"] + Dir[src_dir/'**/*'] )

    @defined = true
    self
  end

  def execute(args=nil)
    raise "Not defined" unless @defined

    # Make build-dependencies available
    if bdeps.any?
      rm_rf dep_dir
      mkdir_p dep_dir
      bdeps.each{|dep| recipe(dep).install_to(dep_dir) }
    end

    with_env(
      :LDFLAGS => "-L#{dep_dir}/lib",
      :CFLAGS  => "-I#{dep_dir}/include",
      :PKG_CONFIG_PATH => "#{dep_dir}/lib/pkgconfig",
      :PATH    => "#{dep_dir}/bin:#{ENV['PATH']}"
    ) do
      Dir.chdir(src_dir / unpack_dir, &install)
    end

    # remove unused stuff
    rm_rf prefix / "man"
    rm_rf prefix / "share" / "man"
    sh "find #{prefix} -type d -empty -delete"

    # done
    touch build_dir / "install.done"
    super
  end

protected

  def with_env(new_env={}, &block)
    bak = new_env.keys.inject({}) do |h,k|
      h[k.to_s] = ENV[k.to_s]
      h
    end
    new_env.each{|k,v| ENV[k.to_s] = v.to_s }
    yield
  ensure
    bak.each{|k,v| ENV[k] = v }
  end

end

def recipe(*args, &block)
  Recipe.define_task(*args, &block)
end
