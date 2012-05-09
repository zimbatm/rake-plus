def sudo(*command)
  raise ArgumentError, "command missing" if command.empty?
  if command.length == 1
    sh "sudo #{command.first}"
  else
    sh "sudo", *command
  end
end
