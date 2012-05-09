require 'uri'

module Rake
  class SvnDependency < Rake::Task
    include Rake::DSL if defined? Rake::DSL

    def branch(val = nil)
      @branch = val if val
      @branch || "trunk"
    end

    def needed?
      return :checkout_missing unless File.directory?(local_path)
    end

    def timestamp
      if File.exist?(local_path / 'svn')
        File.mtime(local_path / 'svn')
      else
        Rake::EARLY
      end
    end
    
    def local_path
      CACHE_DIR / "svn" / basename
    end

    def basename
      base = File.basename(name)
    end

    def execute(args=nil)
      if File.directory?(local_path)
        Dir.chdir(local_path) do
          sh "svn update"
        end
      else
        FileUtils.mkdir_p File.dirname(local_path)
        sh "svn checkout #{name}/#{branch} #{local_path}"
      end
      super
    end

    # Like .tar archives, creates a folder beneath it
    def unpack_to(dir)
      sh "cp -R #{local_path} #{dir}"
    end

    class << self
      # Git based tasks ignore the scope when creating the name.
      def scope_name(scope, task_name); task_name end
    end
  end
end

# Usage: git("git@github.com:zimbatm/direnv.git")
#


def svn(*args, &block)
  Rake::SvnDependency.define_task(*args, &block)
end
alias svn_dep svn
