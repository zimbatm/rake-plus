require 'time'

def gitver(branch_or_file=nil)
  ret = `git log -n 1 --oneline #{branch_or_file}`
  raise ArgumentError, "could not find #{branch_or_file}" if $?.exitstatus > 0
  raise "parse error" unless (ret =~ /^([^\s]+)/)
  commit_id = $1
  commit_num = `git log --oneline #{branch_or_file} | wc -l`.chomp.to_i
  "#{commit_num}-#{commit_id}"
end
