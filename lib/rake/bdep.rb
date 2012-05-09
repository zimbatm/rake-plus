require 'rake/sudo'

module Rake
  # TODO: abstract dependencies from the package system
  class BuildDependency < Rake::Task
    include Rake::DSL if defined? Rake::DSL

    def needed?
      return if ON_OSX
      # dpkg-query also returns old packages, so '^ii ' guarantees only installed
      sh("dpkg-query -l \"#{basename}\" | grep -e '^ii ' > /dev/null 2>&1") do |ok, res|
        return :package_missing unless ok
      end
      return
    end

    def timestamp
      Rake::EARLY
    end

    def execute(args=nil)
      sudo "apt-get install -qy \"#{basename}\""
      super
    end

    def basename
      name.sub(':bdep:','')
    end

    class << self
      # Apply the scope to the task name according to the rules for this kind
      # of task.  File based tasks ignore the scope when creating the name.
      def scope_name(scope, task_name)
        ":bdep:#{task_name}"
      end
    end
  end
end

def bdep(args, &block)
  t = Rake::BuildDependency.define_task(args, &block)
  Rake::Task["bdeps"].prerequisites.push(t.name).uniq!
  t
end

desc "Installs all bdeps"
task "bdeps"
