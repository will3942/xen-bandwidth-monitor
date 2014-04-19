require 'bundler/setup'
Bundler.require(:default)
require './db'
require 'open3'

# xentop command output
xentop = `xentop -fbi1`.split("\n")
header = xentop[0].split(" ") # xentop header to get indexes (handles updates)
@xentop = xentop[1..-1] # xentop without header

# Indexes
@hnindex = header.index("NAME") # Hostname
@txindex = header.index("NETTX(k)") # Network transmitted kilobytes
@rxindex = header.index("NETRX(k)") # Network received kilobytes

# Methods
def find_vm(hostname)
  @xentop.each_with_index do |line, index|
    el = line.split(" ")
    hostname.gsub!(" ", "")
    xh = el[@hnindex].gsub(" ", "")
    if xh == hostname
      return index
    end
  end
  return false
end

def vm(hostname)
  stdout, stderr, exit_status = Open3.capture3("xm", "list", hostname)
  if stderr.empty?
    unless stdout.nil?
      output = stdout.split("\n").map{|x| x.split(" ")}
      unless output[1].nil? or output[1].empty?
        vm = output[1]
        i = indexOf("Name", output[0])
        hostname = vm[i]
        ip_addresses = Array.new
        if File.exist?("/etc/xen/#{hostname}.cfg")
          cfg = IO.read("/etc/xen/#{hostname}.cfg")
          vifs = cfg.scan(/vif\s*=\s*\[(.*)\]/)
          vifs.each do |vif|
            vif.each do |viff|
              ips = viff.scan(/ip\s*=\s*([0-9]{0,3}.[0-9]{0,3}.[0-9]{0,3}.[0-9]{0,3})\s*,/)
              ips.map{|ip| ip_addresses.push(ip[0])}
            end
          end
        end
        ip_addresses.uniq!
        ip_addresses.reject! { |c| c.empty? }
        return {:hostname => hostname, :ips => ip_addresses}
      else
        raise "VM does not exist"
      end
    else
      raise "Unknown error getting VMs"
    end
  else
    raise "Unknown error getting VMs"
  end
end

def indexOf(needle, haystack)
  hash = Hash[haystack.map.with_index.to_a]
  hash[needle]
end

# Get bandwidth for each VM
vms = VirtualMachine.all
vms.each do |vm|
  limit = vm.bandwidth_limit_gigabytes
  last = vm.bandwidth_measurements.where("timestamp.month" => Time.now.month, "timestamp.year" => Time.now.year).last
     
  vmindex = find_vm(vm.hostname)
  current_usage = ((@xentop[vmindex].split(" ")[@txindex].to_i + @xentop[vmindex].split(" ")[@rxindex].to_i) / 1024 / 1024).ceil.round(0).to_i

  if last.nil?
    measurement = vm.bandwidth_measurements.new(cumulative_gigabytes: 0, current_gigabytes: current_usage, timestamp: Time.now)
    unless measurement.save
      File.open('/var/log/bandwidth-monitor.log', 'a') { |f| f.write("#{Time.new.strftime("%H:%M:%S (%m-%d-%Y)").to_s} - #{vm.hostname} failed to save measurement.\n") }
    end
  else
    if last.current_gigabytes > current_usage
      current_cumulative = last.cumulative_gigabytes.to_i + current_usage
    else
      current_cumulative = (current_usage - last.current_gigabytes.to_i) + last.cumulative_gigabytes.to_i
    end
    measurement = vm.bandwidth_measurements.new(cumulative_gigabytes: current_cumulative, current_gigabytes: current_usage, timestamp: Time.now)
    unless measurement.save
      File.open('/var/log/bandwidth-monitor.log', 'a') { |f| f.write("#{Time.new.strftime("%H:%M:%S (%m-%d-%Y)").to_s} - #{vm.hostname} failed to save measurement.\n") }
    end
  end

  if measurement.cumulative_gigabytes >= limit
    xvm = vm(vm.hostname)
    xvm[:ips].each do |ip|
      output = `/sbin/iptables -C INPUT -s #{ip}/32 -j REJECT --reject-with icmp-port-unreachable 2>&1`
      if output.include?("No chain/target/match")
        null = `nullroute-ip #{ip}`
        Pony.mail(
          :to => 'will@will3942.com',
          :via => :smtp,
          :via_options => {
            :address              => 'smtp.gmail.com',
            :port                 => '587',
            :enable_starttls_auto => true,
            :user_name            => ENV['bwmon_gmail_user'],
            :password             => ENV['bwmon_gmail_password'],
            :authentication       => :login,
            :domain               => "nl.definedcode.com"
          },
          :subject => "Defined Code Hosting Nullrouting",
          :body => "#{vm.hostname} (#{ip}) has been nullrouted due to its traffic limit being reached"
        )
      end
    end             
  else
    xvm = vm(vm.hostname)
    xvm[:ips].each do |ip|
      output = `/sbin/iptables -C INPUT -s #{ip}/32 -j REJECT --reject-with icmp-port-unreachable 2>&1`
      unless output.include?("No chain/target/match")
        route = `route-ip #{ip}`
      end
    end
  end
end
