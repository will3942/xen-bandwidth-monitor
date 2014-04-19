require 'bundler/setup'
Bundler.require(:default)
require './db'

vms = VirtualMachine.all
vms.each do |vm|
  puts "#{vm.hostname}:"
  vm = vm.bandwidth_measurements.last
  puts "	Cumulative: #{vm.cumulative_gigabytes}"
  puts "	Current: #{vm.current_gigabytes}"
end
