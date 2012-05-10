module Rake
  class RemotePackage < Rake::Task
    include Rake::DSL if defined? Rake::DSL

    # Example: https://github.com/vivienschilis/segmenter/zipball/v0.0.1
    GITHUB_MATCH = %r[^https?://github\.com/([^/]+)/([^/]+)/(zip|tar)ball/(.*)]
    SF_MATCH = %r[^https?://sourceforge.net/.*/([^/]+)/download$]

    def needed?
      :package_missing unless File.exist?(local_path)
    end

    def local_path
      RakePlus.cache_dir / "pkg" / basename
    end

    def basename
      if name =~ GITHUB_MATCH
        "#{$1}-#{$2}-#{$4}#{$3 == "zip" ? ".zip" : ".tar.gz"}"
      elsif name =~ SF_MATCH
        $1
      else
        File.basename(name.sub(/\?.*/,''))
      end
    end

    def execute(args=nil)
      if needed?
        FileUtils.mkdir_p File.dirname(local_path)
        sh "curl -L -o \"#{local_path}.tmp\" \"#{name}\""
        mv "#{local_path}.tmp", local_path
      end
      super
    end

    # Utility
    def unpack_to(dir)
      abs_local_path = local_path.expand
      Dir.chdir(dir) do
        case abs_local_path
        when /\.tar\.gz$/, /\.tgz$/
          sh "tar xzvf \"#{abs_local_path}\""
        when /\.tar\.bz2$/
          sh "tar xjvf \"#{abs_local_path}\""
        when /\.tar$/
          sh "tar xvf \"#{abs_local_path}\""
        else
          raise "Unsupported file extensions of #{abs_local_path}"
        end
      end
    end

    # Time stamp for file task.
    def timestamp
      if File.exist?(local_path)
        File.mtime(local_path)
      else
        Rake::EARLY
      end
    end

    class << self
      # Apply the scope to the task name according to the rules for this kind
      # of task.  File based tasks ignore the scope when creating the name.
      def scope_name(scope, task_name)
        task_name
      end
    end
  end
end

def remote_package(*args, &block)
  t = Rake::RemotePackage.define_task(*args, &block)
  Rake::Task["remote_packages"].prerequisites.push(t.name).uniq!
  t
end

desc "Downloads all remote packages"
task :remote_packages
