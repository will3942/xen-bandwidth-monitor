require 'bundler/setup'
Bundler.require(:default)
require './db'

def ask_question(q)
  print q + " "
  input = STDIN.gets.chomp
  if input == 'y' or input == 'yes' or input == 'YES' or input == 'Yes' or input == 'Y'
    return true
  else
    return false
  end
end

def get_input(str)
  print str + ": "
  input = STDIN.gets.chomp
  unless input == "" or input == " "
    return input
  else
    return false
  end
end

hostname = get_input("Enter the hostname of the VM you would like to monitor")
abort("Please enter a hostname") unless hostname

limit = get_input("Enter the limit in GB (gigabytes) for data transferred (integer taken)")
abort("Please enter a limit") unless limit

exist = VirtualMachine.where(hostname: hostname).first

unless exist.nil?
  exist.bandwidth_limit_gigabytes = limit
  if exist.save
    puts "VM limit updated"
  else
    puts "Failed"
    p exist.errors.full_messages
  end
else
  vm = VirtualMachine.new(hostname: hostname, bandwidth_limit_gigabytes: limit)
  if vm.save
    puts "VM added"
  else
    puts "Failed"
    p vm.errors.full_messages
  end
end
