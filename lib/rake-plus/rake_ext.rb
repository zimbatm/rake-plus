module Rake
  class Task
    # Are there any prerequisites with a later time than the given time stamp?
    def out_of_date?(stamp)
      @prerequisites.any? { |n| application[n, @scope].timestamp > stamp}
    end

    def file_missing?(path)
      File.exist?(path) ? nil : :file_missing
    end
  end
end
