require 'uri'

module Rake
  class GitDependency < Rake::Task
    include Rake::DSL if defined? Rake::DSL
    attr_accessor :branch, :commit_id

    def branch(val = nil)
      @branch = val if val
      @branch
    end

    def commit_id(val = nil)
      @commit_id = val if val
      @commit_id
    end

    def commit_or_branch
      @commit_id || @branch
    end

    def needed?
      return :checkout_missing unless File.directory?(local_path)
      # check if that revision exists
      if commit_or_branch
        Dir.chdir(local_path) do
          sh("git log #{commit_or_branch} -- >/dev/null 2>&1") do |ok, res|
            return "commit_missing: #{commit_or_branch}" unless ok
          end
        end
      end
      return
    end

    def timestamp
      if File.exist?(local_path / 'HEAD')
        File.mtime(local_path / 'HEAD')
      else
        Rake::EARLY
      end
    end

    def local_path
      CACHE_DIR / "git" / basename
    end

    def basename
      base = File.basename(name)
      unless File.extname(base) == ".git"
        base + ".git"
      else
        base
      end
    end

    def execute(args=nil)
      if File.directory?(local_path)
        Dir.chdir(local_path) do
          sh "git remote update"
        end
      else
        FileUtils.mkdir_p File.dirname(local_path)
        sh "git clone --mirror #{name} #{local_path}"
      end
      super
    end

    # Utility
    def clone_to(dir, branch=nil)
      sh "git clone #{local_path} #{dir}"
      if commit_or_branch
        Dir.chdir(dir) do
          sh "git checkout #{commit_or_branch}"
        end
      end
    end

    # Like .tar archives, creates a folder beneath it
    def unpack_to(dir)
      clone_to(File.join(dir, basename))
    end

    class << self
      # Git based tasks ignore the scope when creating the name.
      def scope_name(scope, task_name); task_name end
    end
  end
end

# Usage: git("git@github.com:zimbatm/direnv.git")
#


def git(*args, &block)
  Rake::GitDependency.define_task(*args, &block)
end
alias git_dep git
